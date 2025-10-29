# Lambda Validation error alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.lambda_function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda validation errors exceed threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.validator.function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = var.common_tags
}

# Lambda validation duration alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.lambda_function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 30000  # 30 seconds
  alarm_description   = "Lambda duration is high"

  dimensions = {
    FunctionName = aws_lambda_function.validator.function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = var.common_tags
}

# DLQ depth alarm
resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  alarm_name          = "${var.project_name}-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "DLQ has messages - failures detected"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = var.common_tags
}

# Validation success and failure rate
resource "aws_cloudwatch_log_metric_filter" "validation_success" {
  name           = "ValidationSuccess"
  log_group_name = aws_cloudwatch_log_group.lambda_cloudwatch_log_group.name
  pattern        = "[time, request_id, level=INFO*, msg=\"Successfully validated*\"]"

  metric_transformation {
    name      = "ValidationSuccess"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "validation_failure" {
  name           = "ValidationFailure"
  log_group_name = aws_cloudwatch_log_group.lambda_cloudwatch_log_group.name
  pattern        = "[time, request_id, level=ERROR*, msg=\"Validation failed*\"]"

  metric_transformation {
    name      = "ValidationFailure"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

# Cloudwatch log group for lambda_validation

resource "aws_cloudwatch_log_group" "lambda_cloudwatch_log_group" {
  name = "ede/lambda/${var.lambda_function_name}"

  tags = {
    Environment = "${var.environment}"
    Name        = "${var.lambda_function_name}-logs"
  }
}