# S3 bucket for source JSON + versioning + encryption + public ACL 
# S3 bucket for curated Parquet + versioning + encryption + public ACL 
# S3 event Notification to trigger lambda 
# Specify outputs in a different file

# S3 bucket for incoming JSON files

resource "aws_s3_bucket" "source_bucket" {
  bucket = var.source_bucket_name
  force_destroy = true

  tags = {
    Name = "${var.project_name}-source-json-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "source_bucket_versioning" {
  bucket = aws_s3_bucket.source_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source_bucket_encryption" {
  bucket = aws_s3_bucket.source_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "source_bucket_public_access_block" {
  bucket = aws_s3_bucket.source_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket for curated parquet files

resource "aws_s3_bucket" "curated_bucket" {
  bucket = var.curated_bucket_name
  force_destroy = true

  tags = {
    Name = "${var.project_name}-curated-parquet-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "curated_bucket_versioning" {
  bucket = aws_s3_bucket.curated_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "curated_bucket_encryption" {
  bucket = aws_s3_bucket.curated_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "curated_bucket_public_access_block" {
  bucket = aws_s3_bucket.curated_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 event notification to trigger source > curated lambda

resource "aws_s3_bucket_notification" "source_events" {
  bucket = aws_s3_bucket.source_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.validator.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.s3_filter_prefix
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# S3 notification for quality check lambda 

resource "aws_s3_bucket_notification" "curated_events" {
  bucket = aws_s3_bucket.curated_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.quality_checker.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "validated/"
  }

  depends_on = [aws_lambda_permission.quality_allow_s3]
}