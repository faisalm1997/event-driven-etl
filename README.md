# event-driven-etl

Purpose: Event-driven ETL pipeline for ingesting and processing real-time data streams using Kinesis, Lambda, and Glue.

## Repo Structure

```sh
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
