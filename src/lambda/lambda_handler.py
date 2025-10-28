# src/lambda/lambda_handler.py
import json
import logging
import os
import boto3
from datetime import datetime
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
    Validates JSON files from S3 and writes to partitioned curated bucket
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
            
            # Extract partition from timestamp (assume ISO format in 'ts' field)
            # Use first item's timestamp for partition
            if validated_items:
                ts = datetime.fromisoformat(validated_items[0]["ts"].replace("Z", "+00:00"))
                partition = f"year={ts.year}/month={ts.month:02d}/day={ts.day:02d}"
            else:
                # Fallback to ingestion date
                now = datetime.utcnow()
                partition = f"year={now.year}/month={now.month:02d}/day={now.day:02d}"
            
            # Write to partitioned location
            output_key = f"validated/{partition}/{key.split('/')[-1]}"
            s3_client.put_object(
                Bucket=CURATED_BUCKET,
                Key=output_key,
                Body=json.dumps(validated_items, indent=2),
                ContentType="application/json"
            )
            
            logger.info(f"✅ Wrote {len(validated_items)} items to s3://{CURATED_BUCKET}/{output_key}")
            
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in {key}: {e}")
            raise
        except Exception as e:
            logger.error(f"Error processing {key}: {e}")
            raise
    
    return {"statusCode": 200, "body": "Processing complete"}