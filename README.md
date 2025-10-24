# event-driven-etl

## Repo Structure

```sh
event-driven-etl/
├── infrastructure/
│   ├── terraform/
│   │   ├── modules/
│   │   │   ├── kinesis/
│   │   │   ├── lambda/
│   │   │   ├── s3/
│   │   │   ├── glue/
│   │   │   └── redshift/
│   │   └── envs/
│   └── terragrunt/
│       ├── dev/
│       └── prod/
├── src/
│   ├── producer/
│   │   └── event_producer.py
│   ├── consumers/
│   │   └── lambda_handler.py
│   └── glue_jobs/
│       └── streaming_transform.py
├── config/
│   └── stream_config.yaml
├── scripts/
│   ├── deploy_lambda.sh
│   └── test_producer.sh
├── tests/
│   ├── test_lambda_handler.py
│   └── test_glue_transform.py
├── ci-cd/
│   ├── github-actions.yaml
│   └── codebuild-buildspec.yml
├── docs/
│   ├── architecture.png
│   └── runbook.md
└── README.md
```
