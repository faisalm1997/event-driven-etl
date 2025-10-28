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
    "classification"  = "JSON"
    "compressionType" = "none"
    "typeOfData"      = "file"
  }

  storage_descriptor {
    location      = "s3://${var.curated_bucket_name}/validated_events/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      name                  = "json_serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
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
  }
}

# Data block for AWS sts caller identity 

data "aws_caller_identity" "current" {}