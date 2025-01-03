resource "aws_sns_topic" "email_verification_topic" {
  name = "${var.project_name}-email-verification"
}

output "sns_topic_arn" {
  value = aws_sns_topic.email_verification_topic.arn
}


# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : aws_sns_topic.email_verification_topic.arn
      }
    ]
  })
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


# Lambda Function for Email Verification
resource "aws_lambda_function" "email_verification_lambda" {
  function_name = "${var.project_name}-email-verification"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "serverless/lambda.handler"
  runtime       = "nodejs18.x"

  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)

  environment {
    variables = {
      MAILGUN_API_KEY = aws_secretsmanager_secret.mailgun_api_key.name
      MAILGUN_DOMAIN  = var.mailgun_domain
      SENDER_EMAIL    = var.sender_email
      DB_HOST         = aws_db_instance.db_instance.endpoint
      DB_USER         = var.db_username
      DB_PASSWORD     = var.db_password
      DB_NAME         = var.db_name
    }
  }

  tags = {
    Name = "${var.project_name}-lambda"
  }
}


# SNS Topic Subscription to Lambda
resource "aws_sns_topic_subscription" "lambda_sns_subscription" {
  topic_arn = aws_sns_topic.email_verification_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_verification_lambda.arn
}

# Allow SNS to Invoke Lambda
resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowSNSInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_verification_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.email_verification_topic.arn
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name = "LambdaCloudWatchLogsPolicy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

# IAM Policy for EC2 Role to Allow SNS Publish
resource "aws_iam_policy" "ec2_sns_publish_policy" {
  name = "${var.project_name}-ec2-sns-publish-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : aws_sns_topic.email_verification_topic.arn
      }
    ]
  })
}

# Attach the policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_sns_publish_policy_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.ec2_sns_publish_policy.arn
}
 

#  resource "aws_iam_policy" "lambda_secrets_policy" {
#   name = "LambdaSecretsAccess"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = [
#           "kms:Decrypt"
#         ],
#         Resource = aws_kms_key.secrets_manager_key.arn
#       },
#       {
#         Effect   = "Allow",
#         Action   = [
#           "secretsmanager:GetSecretValue",
#           "secretsmanager:DescribeSecret"
#         ],
#         Resource = aws_secretsmanager_secret.mailgun_api_key.arn
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_lambda_secrets_policy" {
#   role       = aws_iam_role.instance_role.name
#   policy_arn = aws_iam_policy.lambda_secrets_policy.arn
# }


# resource "aws_iam_policy" "lambda_secrets_manager_access" {
#   name        = "LambdaSecretsManagerAccess"
#   description = "Policy to allow Lambda function to access Secrets Manager for email verification"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = "secretsmanager:GetSecretValue"
#         Resource = ["${aws_secretsmanager_secret.mailgun_api_key.arn}",
#           "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:mailgun-api-key3"]
        
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_secrets_manager_policy_attachment" {
#   role       = "network-setup-lambda-execution-role"
#   policy_arn = aws_iam_policy.lambda_secrets_manager_access.arn
# }


# resource "aws_iam_policy" "lambda_kms_access" {
#   name        = "LambdaKMSAccess"
#   description = "Policy to allow Lambda function to use KMS for decryption"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = "kms:Decrypt"
#         Resource = "arn:aws:kms:us-west-2:361769559850:key/mailgun-api-key3-*"  # Replace with your KMS key ARN
#       },
#       {
#         Effect   = "Allow"
#         Action   = "kms:Decrypt"
#         Resource = "arn:aws:kms:us-west-2:361769559850:key/alias/aws/secretsmanager"  # For default KMS key
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_kms_policy_attachment" {
#   role       = "network-setup-lambda-execution-role"
#   policy_arn = aws_iam_policy.lambda_kms_access.arn
# }


# Define the KMS Key
resource "aws_kms_key" "secrets_manager_key1" {
  description         = "KMS key for encrypting secrets in Secrets Manager"
  enable_key_rotation = true
  policy              = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAccountAdmins",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "AllowLambdaRoleAccess",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/network-setup-lambda-execution-role"
        },
        Action    = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ],
        Resource  = "*"
      }
    ]
  })
}


# Define Secrets Manager Secret
resource "aws_secretsmanager_secret" "mailgun_api_key" {
  name       = "mailgun-api-key10"
  kms_key_id = aws_kms_key.secrets_manager_key1.arn
}

# Define the Secret Version
resource "aws_secretsmanager_secret_version" "mailgun_api_key_version" {
  secret_id     = aws_secretsmanager_secret.mailgun_api_key.id
  secret_string = jsonencode({
    MAILGUN_API_KEY = "ed3026cd34ad11e2eeda7f1564b45db5-6df690bb-d08bd58a"
  })
}

# IAM Policy for Lambda to Access Secrets Manager and KMS
resource "aws_iam_policy" "lambda_secrets_manager_kms_access" {
  name        = "LambdaSecretsManagerKMSAccess"
  description = "Policy to allow Lambda function to access Secrets Manager and KMS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = aws_kms_key.secrets_manager_key1.arn
      },
      {
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.mailgun_api_key.arn
      }
    ]
  })
}

# IAM Role for Lambda Execution


# Attach Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_secrets_manager_kms_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_secrets_manager_kms_access.arn
}

# Lambda Function (Example)
