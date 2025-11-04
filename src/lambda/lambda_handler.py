import json
import logging
import os
import boto3
import csv
import gzip
from datetime import datetime
from io import StringIO, BytesIO
from jsonschema import validate, Draft7Validator, ValidationError

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
    Validates JSON files from S3 and writes to partitioned curated bucket as CSV.gz
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
            
            # Convert to CSV and compress with gzip
            csv_buffer = StringIO()
            if validated_items:
                fieldnames = list(validated_items[0].keys())
                writer = csv.DictWriter(csv_buffer, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(validated_items)
            
            # Compress CSV
            csv_bytes = csv_buffer.getvalue().encode('utf-8')
            gzip_buffer = BytesIO()
            with gzip.GzipFile(fileobj=gzip_buffer, mode='wb') as gz:
                gz.write(csv_bytes)
            
            # Write to partitioned location
            base_filename = key.split('/')[-1].replace('.json', '')
            output_key = f"validated/{partition}/{base_filename}.csv.gz"
            
            s3_client.put_object(
                Bucket=CURATED_BUCKET,
                Key=output_key,
                Body=gzip_buffer.getvalue(),
                ContentType="application/gzip",
                ContentEncoding="gzip"
            )
            
            original_size = len(csv_bytes)
            compressed_size = len(gzip_buffer.getvalue())
            compression_ratio = (1 - compressed_size/original_size) * 100
            
            logger.info(
                f"✅ Wrote {len(validated_items)} items to s3://{CURATED_BUCKET}/{output_key} "
                f"(compression: {compression_ratio:.1f}%)"
            )
            
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in {key}: {e}")
            raise
        except Exception as e:
            logger.error(f"Error processing {key}: {e}")
            raise
    
    return {"statusCode": 200, "body": "Processing complete"}