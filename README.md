# event-driven-etl

Event-driven ETL pipeline for ingesting, validating, and processing JSON data streams using S3, Lambda, Glue, and Athena.

## Architecture

JSON files → S3 (source) → Lambda (validate) → S3 (curated) → Athena (query)

## Features

- **Event-driven ingestion**: S3 events trigger Lambda processing
- **Schema validation**: JSON schema validation with error handling
- **Data partitioning**: Automatic partitioning by date for query optimization
- **Data quality checks**: Automated quality validation on curated data
- **Dead letter queue**: Failed validations routed to SQS for investigation
- **Monitoring**: CloudWatch alarms for errors, duration, and DLQ depth
- **SQL queries**: Athena interface for ad-hoc analytics
- **Infrastructure as Code**: Terraform + Terragrunt for reproducible deployments

## Repo Structure

```
event-driven-etl/
├── infrastructure/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.tf
│   │   ├── s3.tf
│   │   ├── iam.tf
│   │   ├── lambda.tf
│   │   ├── lambda_quality.tf
│   │   ├── sqs.tf
│   │   ├── glue.tf
│   │   ├── athena.tf
│   │   └── cloudwatch.tf
│   └── terragrunt/
│       ├── terragrunt.hcl
│       └── dev/
│           └── terragrunt.hcl
├── src/
│   └── lambda/
│       ├── lambda_handler.py
│       ├── quality_checker.py
│       └── build/
│           ├── validator.zip
│           └── quality.zip
├── scripts/
│   ├── package_lambda.sh
│   └── load_test_data.sh
├── docs/
│   ├── architecture.md
│   ├── sample_queries.sql
│   └── runbook.md
├── tests/
│   └── test_validation.py
├── .gitignore
└── README.md
```

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.5.0
- Terragrunt >= 0.50.0
- Python 3.12
- Bash shell (macOS/Linux)

```bash
# Verify installations
aws --version
terraform --version
terragrunt --version
python3 --version
```

## Deployment

### 1. Configure AWS Credentials

```bash
# Use AWS profile (recommended)
export AWS_PROFILE=your-profile-name

# Or configure interactively
aws configure

# Verify credentials
aws sts get-caller-identity
```

### 2. Package Lambda Functions

```bash
# Make script executable
chmod +x scripts/package_lambda.sh

# Package Lambda
./scripts/package_lambda.sh

# Verify ZIP created
ls -lh src/lambda/build/validator.zip
```

### 3. Deploy Infrastructure

```bash
# Navigate to dev environment
cd infrastructure/terragrunt/dev

# Initialise Terraform
terragrunt init

# Preview changes
terragrunt plan

# Deploy
terragrunt apply

# View outputs
terragrunt output
```

### 4. Test the Pipeline

```bash
# Return to project root
cd ../../..

# Make test script executable
chmod +x scripts/load_test_data.sh

# Upload test data
./scripts/load_test_data.sh
```

### 5. Verify Lambda Procwssing

```bash
# View Lambda logs (real-time)
aws logs tail /aws/lambda/ede-dev-validator --follow

# Check curated bucket
CURATED_BUCKET=$(cd infrastructure/terragrunt/dev && terragrunt output -raw curated_bucket_name)
aws s3 ls "s3://$CURATED_BUCKET/validated/" --recursive

# Download validated file
aws s3 cp "s3://$CURATED_BUCKET/validated/year=2025/month=01/day=27/events_001.json" - | jq .
```

### 6. Query with Athena (Optional)

```bash
# Run sample query
aws athena start-query-execution \
  --query-string "SELECT * FROM ede_dev.validated_events LIMIT 10" \
  --work-group ede-dev

# Daily aggregates
aws athena start-query-execution \
  --query-string "
    SELECT 
      year, month, day,
      COUNT(*) as event_count,
      AVG(value) as avg_value
    FROM ede_dev.validated_events
    WHERE year = 2025
    GROUP BY year, month, day
  " \
  --work-group ede-dev
```

## Testing

### Upload Custom Test Data

```bash
SOURCE_BUCKET=$(cd infrastructure/terragrunt/dev && terragrunt output -raw source_bucket_name)

# Create test file
cat > test-event.json <<EOF
{
  "id": 1,
  "ts": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "value": 42.5
}
EOF

# Upload to S3
aws s3 cp test-event.json "s3://$SOURCE_BUCKET/incoming/test-event.json"
```

### Test Validation Errors

```bash
# Upload invalid data
cat > invalid.json <<EOF
{"id": "not-a-number", "ts": "invalid", "value": "bad"}
EOF

aws s3 cp invalid.json "s3://$SOURCE_BUCKET/incoming/invalid.json"

# Check Lambda error logs
aws logs tail /aws/lambda/ede-dev-validator --since 2m --filter-pattern "ERROR"
```

### Load Testing

```bash
# Upload 100 test files
for i in {1..100}; do
  cat <<EOF | aws s3 cp - "s3://$SOURCE_BUCKET/incoming/load_test_$i.json"
[{"id": $i, "ts": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")", "value": $(( RANDOM % 100 ))}]
EOF
done

# Monitor processing
aws logs tail /aws/lambda/ede-dev-validator --follow
```

## Monitoring

### CloudWatch Metrics

```bash
# Lambda invocations (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=ede-dev-validator \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum

# Lambda errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=ede-dev-validator \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

### Check Alarms

```bash
# List active alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix ede-dev \
  --state-value ALARM
```

## Troubleshooting

### Lambda Not Triggering

```bash
# Check S3 event notification
SOURCE_BUCKET=$(cd infrastructure/terragrunt/dev && terragrunt output -raw source_bucket_name)
aws s3api get-bucket-notification-configuration --bucket $SOURCE_BUCKET

# Verify Lambda permission
aws lambda get-policy --function-name ede-dev-validator
```

### View Failed Messages

```bash
# Check dead letter queue
aws sqs receive-message \
  --queue-url "https://sqs.us-east-1.amazonaws.com/$(aws sts get-caller-identity --query Account --output text)/event-driven-etl-dev-dlq" \
  --max-number-of-messages 10
```

### Athena Query Issues

```bash
# Check Glue table schema
aws glue get-table \
  --database-name ede_dev \
  --name validated_events

# View query execution details
aws athena get-query-execution --query-execution-id <QUERY_ID>
```

## Cleanup

```bash
# Navigate to Terragrunt dev
cd infrastructure/terragrunt/dev

# Empty S3 buckets (required before deletion)
SOURCE_BUCKET=$(terragrunt output -raw source_bucket_name)
CURATED_BUCKET=$(terragrunt output -raw curated_bucket_name)

aws s3 rm "s3://$SOURCE_BUCKET" --recursive
aws s3 rm "s3://$CURATED_BUCKET" --recursive

# Destroy all resources
terragrunt destroy
```

## Quick Reference

```bash
# Deploy
cd infrastructure/terragrunt/dev && terragrunt apply

# Upload test data
./scripts/load_test_data.sh

# View logs
aws logs tail /aws/lambda/ede-dev-validator --follow

# Query data
aws athena start-query-execution \
  --query-string "SELECT COUNT(*) FROM ede_dev.validated_events" \
  --work-group ede-dev

# Cleanup
cd infrastructure/terragrunt/dev && terragrunt destroy
```

## Configuration

Edit `infrastructure/terragrunt/dev/terragrunt.hcl` to customise:

- AWS region
- Bucket names
- Lambda memory/timeout
- Enable/disable Glue/Athena
- Alert email for SNS notifications
- Environment specific tags