variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "event-driven-etl"
}

# S3 Configuration
variable "source_bucket_name" {
  type        = string
  description = "Source S3 bucket for incoming JSON files"
}

variable "curated_bucket_name" {
  type        = string
  description = "Curated S3 bucket for validated data"
}

variable "s3_filter_prefix" {
  type        = string
  description = "S3 event filter prefix"
  default     = "incoming/"
}

# Lambda Configuration
variable "lambda_function_name" {
  type        = string
  description = "Lambda function name"
}

variable "lambda_handler" {
  type        = string
  description = "Lambda handler"
  default     = "lambda_handler.handler"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda runtime version"
  default     = "python3.12"
}

variable "lambda_package_path" {
  type        = string
  description = "Path to Lambda ZIP package"
}

variable "lambda_quality_package_path" {
  type        = string 
  description = "Path to Lambda quality package path"
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds"
  default     = 120
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda memory in MB"
  default     = 1024
}

variable "log_level" {
  type        = string
  description = "Lambda log level"
  default     = "INFO"
}

# Glue/Athena Configuration
variable "enable_glue_athena" {
  type        = bool
  description = "Enable Glue catalog and Athena"
  default     = false
}

variable "glue_database_name" {
  type        = string
  description = "Glue database name"
  default     = "ede_dev"
}

variable "glue_table_name" {
  type        = string
  description = "Glue table name"
  default     = "validated_events"
}

variable "athena_results_bucket_name" {
  type        = string
  description = "Athena query results bucket"
  default     = ""
}

variable "athena_workgroup_name" {
  type        = string
  description = "Athena workgroup name"
  default     = "ede-dev"
}

# Tags
variable "common_tags" {
  type        = map(string)
  description = "Common resource tags"
  default     = {}
}

# Alerting 

variable "alert_email" {
  type        = string
  description = "Email address for SNS alerts"
  default     = ""
}