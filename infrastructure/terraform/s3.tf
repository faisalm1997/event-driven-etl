# S3 bucket for source JSON + versioning + encryption + public ACL 
# S3 bucket for curated Parquet 
# S3 event Notification to trigger lambda 
# Specify outputs in a different file


resource "aws_s3_bucket" "source_bucket" {
  bucket = "event-driven-etl-json-source-bucket"

  tags = {
    Name = 
  }
}