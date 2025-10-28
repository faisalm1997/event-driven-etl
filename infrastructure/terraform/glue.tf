# Glue catalog database 
resource "aws_glue_catalog_database" "validated_events_db" {
  count       = var.enable_glue_athena ? 1 : 0
  name        = "${var.project_name}_validated_events_db"
  description = "Glue database for ${var.project_name} ${var.environment}"

  catalog_id = data.aws_caller_identity.current.account_id
}

# Glue catalog table for validated events with schema definition
resource "aws_glue_catalog_table" "validated_events_table" {
  count         = var.enable_glue_athena ? 1 : 0
  name          = "${var.project_name}_validated_events_table"
  database_name = aws_glue_catalog_database.validated_events_db[0].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
    "comment"            = "Validated event data from S3 ingestion pipeline"
    "data_owner"         = "data-engineering"
    "data_classification" = "internal"
    "retention_days"     = "90"
    "created_by"         = "terraform"

    "projection.enabled" = "true"
    "projection.year.type" = "integer"
    "projection.year.range" = "2020,2030"
    "projection.month.type" = "integer"
    "projection.month.range" = "1,12"
    "projection.month.digits" = "2"
    "projection.day.type" = "integer"
    "projection.day.range" = "1,31"
    "projection.day.digits" = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.curated.bucket}/validated/year=$${year}/month=$${month}/day=$${day}"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.curated.bucket}/validated/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json-serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "id"
      type = "int"
    }

    columns {
      name = "ts"
      type = "string"
    }

    columns {
      name = "value"
      type = "double"
    }

    columns {
      name = "_ingested_at"
      type = "string"
    }

    columns {
      name = "_source_file"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }

  partition_keys {
    name = "month"
    type = "int"
  }

  partition_keys {
    name = "day"
    type = "int"
  }
}

# Data block for AWS sts caller identity 

data "aws_caller_identity" "current" {}