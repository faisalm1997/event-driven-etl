include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../terraform"
}

# Get AWS account ID dynamically
locals {
  account_id = run_cmd("--terragrunt-quiet", "aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text")
  
  # Get root locals
  root = read_terragrunt_config(find_in_parent_folders())
}

# Input variables for dev environment
inputs = {
  # AWS Configuration
  aws_region   = "us-east-1"
  environment  = "dev"
  project_name = "event-driven-etl"

  # S3 Configuration (unique bucket names with account ID)
  source_bucket_name  = "ede-dev-source-${local.account_id}"
  curated_bucket_name = "ede-dev-curated-${local.account_id}"
  s3_filter_prefix    = "incoming/"

    # Lambda Validator Configuration
  lambda_function_name = "ede-dev-validator"
  lambda_handler       = "lambda_handler.handler"
  lambda_runtime       = "python3.12"
  lambda_package_path  = "${get_repo_root()}/src/lambda/build/validator.zip"
  lambda_timeout       = 120
  lambda_memory_size   = 1024
  log_level            = "INFO"

  # Lambda Quality Checker Configuration
  enable_quality_checks       = true
  lambda_quality_package_path = "${get_repo_root()}/src/lambda/build/quality.zip"

  # Alerts
  alert_email = "faisalmomoniat@googlemail.com"

  # Glue/Athena Configuration
  enable_glue_athena         = true
  glue_database_name         = "ede_dev"
  glue_table_name            = "validated_events"
  athena_results_bucket_name = "" 
  athena_workgroup_name      = "ede-dev"

  # Tags
  common_tags = merge(
    local.root.locals.common_tags,
    {
      deployed_by = "terragrunt"
    }
  )
}