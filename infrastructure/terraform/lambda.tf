# Cloudwatch log group for lambda 

resource "aws_cloudwatch_log_group" "Lambda_cloudwatch_log_group" {
  name = "Lambda Cloudwatch Log Group"

  tags = {
    Environment = "${var.environment}"
    Application = "${var.application_name}"
  }
}

# Lambda function 

# Package the Lambda function code
data "archive_file" "example" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda/function.zip"
}

# Lambda function
resource "aws_lambda_function" "example" {
  filename         = data.archive_file.example.output_path
  function_name    = "ede-lambda-function"
  role             = aws_iam_role.example.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.example.output_base64sha256

  runtime = "nodejs20.x"

  environment {
    variables = {
      ENVIRONMENT = "${var.environment}"
      LOG_LEVEL   = aws_cloudwatch_log_group.Lambda_cloudwatch_log_group.name
    }
  }

  tags = {
    Environment = "${var.environment}"
    Application = "${var.application_name}"
  }
}

# Lambda permission for s3 Invoke

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "s3.amazonaws.com"
}