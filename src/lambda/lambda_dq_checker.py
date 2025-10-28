import json
import logging
import os
import boto3
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

s3_client = boto3.client("s3")
sns_client = boto3.client("sns")

CURATED_BUCKET = os.environ["CURATED_BUCKET"]
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")

def handler(event, context):
    """
    Run quality checks on validated data
    """
    metrics = {
        "total_files": 0,
        "total_records": 0,
        "null_values": 0,
        "out_of_range": 0,
        "duplicates": 0
    }
    
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        
        if not key.startswith("validated/"):
            continue
        
        logger.info(f"Quality check: s3://{bucket}/{key}")
        
        try:
            response = s3_client.get_object(Bucket=bucket, Key=key)
            content = response["Body"].read().decode("utf-8")
            data = json.loads(content)
            
            metrics["total_files"] += 1
            metrics["total_records"] += len(data)
            
            # Check for issues
            seen_ids = set()
            for item in data:
                # Null checks
                if item.get("value") is None:
                    metrics["null_values"] += 1
                
                # Range checks (example: value should be between 0-100)
                if item.get("value", 0) < 0 or item.get("value", 0) > 100:
                    metrics["out_of_range"] += 1
                
                # Duplicate checks
                item_id = item.get("id")
                if item_id in seen_ids:
                    metrics["duplicates"] += 1
                seen_ids.add(item_id)
            
            logger.info(f"Quality metrics: {metrics}")
            
            # Alert if issues found
            if metrics["null_values"] > 0 or metrics["out_of_range"] > 0 or metrics["duplicates"] > 0:
                alert_message = f"""
Data Quality Alert - {datetime.utcnow().isoformat()}

File: {key}
Issues Found:
- Null values: {metrics["null_values"]}
- Out of range: {metrics["out_of_range"]}
- Duplicates: {metrics["duplicates"]}
"""
                logger.warning(alert_message)
                
                if SNS_TOPIC_ARN:
                    sns_client.publish(
                        TopicArn=SNS_TOPIC_ARN,
                        Subject="Data Quality Alert",
                        Message=alert_message
                    )
            
        except Exception as e:
            logger.error(f"Error in quality check for {key}: {e}")
            raise
    
    return {"statusCode": 200, "metrics": metrics}