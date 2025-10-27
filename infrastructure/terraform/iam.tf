# Lambda assume role policy 
# Lambda execution role 
# Attached AWS managed policy for basic lambda execution 
# Custom policy for S3 execution to be able to read from s3 bucket and write to curated bucket
# Lambda s3 policy 
# Lambda S3 access
# Ouputs for lambda role arn + lambda role name

# Lambda AssumeRole Policy 

data "aws_iam_policy" "lambda_assume_role" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda execution role
resource "aws_iam_role" "lambda_execution" {
  name               = "${var.lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  
  tags = merge(var.common_tags, {
    Name = "${var.lambda_function_name}-role"
  })
}

# Attach AWS managed policy for basic Lambda execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for S3 access
data "aws_iam_policy_document" "lambda_s3_access" {
  # Read from source bucket
  statement {
    sid = "ReadSourceBucket"
    
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    
    resources = [
      aws_s3_bucket.source.arn,
      "${aws_s3_bucket.source.arn}/*"
    ]
  }

  # Write to curated bucket
  statement {
    sid = "WriteCuratedBucket"
    
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    
    resources = [
      aws_s3_bucket.curated.arn,
      "${aws_s3_bucket.curated.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${var.lambda_function_name}-s3-policy"
  description = "S3 access policy for Lambda validator function"
  policy      = data.aws_iam_policy_document.lambda_s3_access.json
  
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}