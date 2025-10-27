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

