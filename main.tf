########################################
###              Locals              ###
########################################
locals {
  lambdas = merge(var.apps, var.microservices)
}

########################################
###              Lambda              ###
########################################
#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "lambda" {
  for_each      = local.lambdas
  function_name = "${var.project}-${each.value.name}-${var.env}"
  role          = aws_iam_role.iam_for_lambda.arn

  runtime = "provided"
  handler = "main"

  filename    = "${path.module}/src/dummy.zip"
  memory_size = 128

  environment {
    variables = {
      DATABASE_NAME = "${var.project}-${var.env}"
    }
  }

  lifecycle {
    # environment variables are managed by the CI/CD
    # filename is only for the dummy.zip to be ignored
    # s3_bucket is managed by the CI/CD
    ignore_changes = [environment, filename, s3_bucket, runtime, handler]
  }

  tags = var.common_tags
}

resource "aws_lambda_event_source_mapping" "invoke" {
  for_each = var.sqs_enabled == true ? local.lambdas : {}

  event_source_arn = "arn:aws:sqs:${var.aws_conf.region}:${var.aws_conf.account_id}:${var.project}-${each.value.name}-${var.env}"
  function_name    = "${var.project}-${each.value.name}-${var.env}"
}

########################################
###               IAM                ###
########################################
resource "aws_iam_role" "iam_for_lambda" {
  name = "lambda-${var.project}-${var.env}${var.suffix}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Allows Lambda to send logs to cloudwatch
resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda.name
}

# Allows Lambda full access to DynamoDB
resource "aws_iam_role_policy_attachment" "AmazonDynamoDBFullAccess" {
  count = var.dynamodb_kms_key_arn != "" ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.iam_for_lambda.name
}

# Allows Lambda read access to S3 buckets
resource "aws_iam_role_policy_attachment" "AmazonS3ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.iam_for_lambda.name
}

# Allows Lambda read access to S3 buckets
resource "aws_iam_role_policy_attachment" "AmazonLambdaInvoke" {
  policy_arn = aws_iam_policy.lambda_invoke.arn
  role       = aws_iam_role.iam_for_lambda.name
}

# Allows Lambda read receive invoke events and access the queue from SQS
resource "aws_iam_role_policy_attachment" "AWSLambdaSQSQueueExecutionRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  role       = aws_iam_role.iam_for_lambda.name
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "lambda_invoke" {
  name        = "lambda-invoke-${var.project}-${var.env}${var.suffix}"
  description = "IAM policy to allow Lambda invoke other Lambdas"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid      = "VisualEditor0",
          Effect   = "Allow",
          Action   = "lambda:InvokeFunction",
          Resource = "*"
        }
      ]
    }
  )

  tags = var.common_tags
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "lambda_kms" {
  count = var.dynamodb_kms_key_arn != "" ? 1 : 0

  name        = "lambda-kms-${var.project}-${var.env}${var.suffix}"
  description = "IAM policy to allow Lambda to Encrypt/Decrypt KMS"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:ReEncrypt*",
            "kms:Get*",
            "kms:List*"
          ],
          Effect   = "Allow",
          Resource = var.dynamodb_kms_key_arn
        }
      ]
    }
  )

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_kms" {
  count = var.dynamodb_kms_key_arn != "" ? 1 : 0

  policy_arn = aws_iam_policy.lambda_kms[0].arn
  role       = aws_iam_role.iam_for_lambda.name
}
