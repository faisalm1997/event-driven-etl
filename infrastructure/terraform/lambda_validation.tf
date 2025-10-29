# Lambda function 

resource "aws_lambda_function" "validator" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_execution.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

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
    aws_iam_role_policy_attachment.lambda_s3_access
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