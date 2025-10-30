import json
import logging
import os
import boto3
import pyarrow as pa
import pyarrow.parquet as pq
from datetime import datetime
from jsonschema import validate, Draft7Validator, ValidationError
from io import BytesIO

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

s3_client = boto3.client("s3")
CURATED_BUCKET = os.environ["CURATED_BUCKET"]

JSON_SCHEMA = {
    "type": "object",
    "properties": {
        "id": {"type": "integer"},
        "ts": {"type": "string"},
        "value": {"type": "number"}
    },
    "required": ["id", "ts", "value"],
    "additionalProperties": False
}

def handler(event, context):
    """
    Validates JSON files from S3 and writes to partitioned curated bucket as Parquet
    """
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        
        logger.info(f"Processing s3://{bucket}/{key}")
        
        try:
            # Get object from S3
            response = s3_client.get_object(Bucket=bucket, Key=key)
            content = response["Body"].read().decode("utf-8")
            
            # Parse JSON
            data = json.loads(content)
            items = data if isinstance(data, list) else [data]
            
            # Validate and enrich each item
            validated_items = []
            for idx, item in enumerate(items):
                try:
                    validate(instance=item, schema=JSON_SCHEMA, cls=Draft7Validator)
                    
                    # Add metadata
                    item["_ingested_at"] = datetime.utcnow().isoformat()
                    item["_source_file"] = key
                    
                    validated_items.append(item)
                except ValidationError as ve:
                    logger.error(f"Validation failed for item {idx} in {key}: {ve.message}")
                    raise
            
            if not validated_items:
                logger.warning(f"No valid items in {key}")
                return {"statusCode": 200, "body": "No items to process"}
            
            # Extract partition from timestamp
            ts = datetime.fromisoformat(validated_items[0]["ts"].replace("Z", "+00:00"))
            partition = f"year={ts.year}/month={ts.month:02d}/day={ts.day:02d}"
            
            # Convert to Parquet
            table = pa.Table.from_pylist(validated_items)
            parquet_buffer = BytesIO()
            pq.write_table(table, parquet_buffer, compression='snappy')
            
            # Write to partitioned location
            base_filename = key.split('/')[-1].replace('.json', '')
            output_key = f"validated/{partition}/{base_filename}.parquet"
            
            s3_client.put_object(
                Bucket=CURATED_BUCKET,
                Key=output_key,
                Body=parquet_buffer.getvalue(),
                ContentType="application/octet-stream"
            )
            
            logger.info(f"Wrote {len(validated_items)} items to s3://{CURATED_BUCKET}/{output_key}")
            
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in {key}: {e}")
            raise
        except Exception as e:
            logger.error(f"Error processing {key}: {e}")
            raise
    
    return {"statusCode": 200, "body": "Processing complete"}