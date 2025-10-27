# S3 bucket for athena query results + S3 bucket versioning + server side encryption + block public acl + lifecycle configuration to clean up old queries

resource "aws_s3_bucket" "athena_results_bucket" {
  bucket = "${var.project_name}-athena-results-${var.environment}"

  tags = {
    Name = "${var.project_name}-athena-results-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "athena_results_bucket" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results_bucket_encryption" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results_bucket_public_access_block" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results_bucket_lifecycle" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  rule {
    id     = "ExpireOldQueryResults"
    status = "Enabled"

    expiration {
      days = 2
    }

    filter {}
  }
}

# Athena workgroup 

resource "aws_athena_workgroup" "ede-athena-workgroup" {
  name = "ede-athena-workgroup-${var.project_name}-${var.environment}"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results_bucket.bucket}/output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
      }
    }
  }
}