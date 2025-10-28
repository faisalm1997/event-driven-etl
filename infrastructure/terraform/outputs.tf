# S3 outputs 

output "source_bucket_name" {
  value       = aws_s3_bucket.source_bucket.bucket
  description = "Source S3 bucket name"
}

output "source_bucket_arn" {
  value       = aws_s3_bucket.source_bucket.arn
  description = "Source S3 bucket ARN"
}

output "curated_bucket_name" {
  value       = aws_s3_bucket.curated_bucket.bucket
  description = "Curated S3 bucket name"
}

output "curated_bucket_arn" {
  value       = aws_s3_bucket.curated_bucket.arn
  description = "Curated S3 bucket ARN"
}

output "lambda_role_arn" {
  value       = aws_iam_role.lambda_execution.arn
  description = "Lambda execution role ARN"
}

output "lambda_role_name" {
  value       = aws_iam_role.lambda_execution.name
  description = "Lambda execution role name"
}

output "lambda_function_arn" {
  value = aws_lambda_function.validator.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.validator.function_name
}

output "lambda_log_group_name" {
  value = aws_cloudwatch_log_group.lambda_cloudwatch_log_group.name
}

output "athena_workgroup_name" {
  value       = aws_athena_workgroup.ede-athena-workgroup[0].name
  description = "Athena workgroup name"
}

output "athena_results_bucket_name" {
  value       = aws_s3_bucket.athena_results_bucket[0].bucket
  description = "Athena results S3 bucket name"
}

output "athena_results_location" {
  value       = "s3://${aws_s3_bucket.athena_results_bucket[0].bucket}/output/"
  description = "Athena results S3 location"
}

output "glue_database_name" {
  value = aws_glue_catalog_database.validated_events_db[0].name
}

output "glue_table_name" {
  value = aws_glue_catalog_table.validated_events_table[0].name
}