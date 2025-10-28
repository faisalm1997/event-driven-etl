resource "aws_cloudwatch_log_group" "quality_checker_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}-quality"
  retention_in_days = 7
  tags              = var.common_tags
}

resource "aws_lambda_function" "quality_checker" {
  function_name    = "${var.lambda_function_name}-quality"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "quality_checker.handler"
  runtime          = var.lambda_runtime
  filename         = var.lambda_quality_package_path
  source_code_hash = filebase64sha256(var.lambda_quality_package_path)
  timeout          = 120
  memory_size      = 512

  environment {
    variables = {
      CURATED_BUCKET = aws_s3_bucket.curated_bucket.bucket
      LOG_LEVEL      = var.log_level
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.lambda_function_name}-quality"
  })
}

resource "aws_lambda_permission" "quality_allow_s3" {
  statement_id  = "AllowS3InvokeQuality"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.quality_checker.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.curated_bucket.arn
}