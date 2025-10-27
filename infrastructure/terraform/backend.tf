terraform {
  backend "s3" {
    bucket         = "event-driven-etl-tf-state-bucket"
    key            = "./.terraform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}