# PyArrow Lambda Layer

resource "aws_lambda_layer_version" "pyarrow_layer" {
  filename            = "${path.root}/../../src/lambda/layers/pyarrow-layer.zip"
  layer_name          = "${var.project_name}-${var.environment}-pyarrow"
  compatible_runtimes = ["python3.12"]
  description         = "PyArrow 14.0.1 for Parquet processing"
  
  source_code_hash = filebase64sha256("${path.root}/../../src/lambda/layers/pyarrow-layer.zip")
}

# Lambda function 
resource "aws_lambda_function" "validator" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_execution.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  # Use custom PyArrow layer
  layers = [aws_lambda_layer_version.pyarrow_layer.arn]

  environment {
    variables = {
      CURATED_BUCKET = aws_s3_bucket.curated_bucket.bucket
      LOG_LEVEL      = var.log_level
      ENVIRONMENT    = var.environment
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  tags = merge(var.common_tags, {
    Name = var.lambda_function_name
  })

  depends_on = [
    aws_cloudwatch_log_group.lambda_cloudwatch_log_group,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_s3_access,
    aws_iam_role_policy_attachment.lambda_sqs_access,
    aws_lambda_layer_version.pyarrow_layer
  ]
}

# Lambda permission for s3 Invoke

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validator.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source_bucket.arn
}