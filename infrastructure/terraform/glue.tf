# Glue catalog database 
resource "aws_glue_catalog_database" "validated_events_db" {
  name = "${var.project_name}_validated_events_db"
}

# Glue catalog table for validated events with schema definition
resource "aws_glue_catalog_table" "validated_events_table" {
  name          = "${var.project_name}_validated_events_table"
  database_name = aws_glue_catalog_database.validated_events_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
    "compressionType" = "none"
    "typeOfData" = "file"
  }

  storage_descriptor {
    location      = "s3://${var.curated_bucket_name}/validated_events/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "event_id"
      type = "string"
    }

    columns {
      name = "event_type"
      type = "string"
    }

    columns {
      name = "event_timestamp"
      type = "timestamp"
    }

    columns {
      name = "event_data"
      type = "string"
    }
  }
}
# Data block for AWS sts caller identity 

data "aws_caller_identity" "current" {}