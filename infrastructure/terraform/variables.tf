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