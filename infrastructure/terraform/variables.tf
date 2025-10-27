variable "environment" {
  type        = string
  description = "current environment for deployment"
}

variable "aws_region" {
  type        = string
  description = "current aws region for deployment"
}

variable "project_name" {
  type        = string
  description = "name of the project"
}

variable "source_bucket_name" {
  type        = string
  description = "Source JSON S3 bucket name"
}

variable "curated_bucket_name" {
  type        = string
  description = "Curated Parquet S3 bucket name"
}

variable "s3_filter_prefix" {
  type        = string
  description = "S3 prefix filter for triggering Lambda"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}
}

variable "application_name" {
  type        = string
  description = "Name of the application"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}