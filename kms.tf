resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90  

  
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.instance_role.name}"
          ]
        }
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow attachment of persistent resources"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.instance_role.name}"
          ]
        }
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })
}

# Add an alias for easier management
resource "aws_kms_alias" "ec2_key_alias" {
  name          = "alias/ec2-encryption-key"
  target_key_id = aws_kms_key.ec2_key.key_id
}

# Ensure you have this data source to get the current account ID
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS"
  enable_key_rotation     = true
  rotation_period_in_days = 90  

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 Instance Role Access"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.instance_role.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3"
  enable_key_rotation     = true
  rotation_period_in_days = 90  


   policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Use of the Key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_kms_key" "secrets_manager_key" {
  description             = "KMS key for Secrets Manager"
  enable_key_rotation     = true
  rotation_period_in_days = 90  

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}



# resource "aws_ebs_volume" "example" {
#   availability_zone = "us-west-2a"
#   size              = 10
#   encrypted         = true
#   kms_key_id        = aws_kms_key.ec2_key.arn
# }



# resource "aws_s3_bucket" "example" {
#   bucket = "example-bucket"

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         kms_master_key_id = aws_kms_key.s3_key.arn
#         sse_algorithm     = "aws:kms"
#       }
#     }
#   }
# }


resource "random_password" "db_password" {
  length  = 16
  special = true
override_special = "!#$%^&*-_"
  upper    = true
  lower    = true
  number   = true
}

# Create a custom KMS key for Secrets Manager


# Secrets Manager Secret
resource "aws_secretsmanager_secret" "db_password" {
  name       = "db_password19"
  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "csye6225"
    password = random_password.db_password.result
  })
    depends_on = [aws_kms_key.secrets_manager_key]
}

# Secrets Manager Secret Version


resource "aws_iam_policy" "secrets_manager_access" {
  name        = "secrets-manager-access"
  description = "Allow EC2 to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue",
                     "secretsmanager:DescribeSecret"]
        Effect   = "Allow"
        Resource = "${aws_secretsmanager_secret.db_password.arn}"
   
      }
    ]
  })
}



# resource "aws_iam_instance_profile" "instance_profile" {
#   name = "instance-profile-kms"
#   role = aws_iam_role.ec2_role.name  # Attach IAM role to the instance profile
# }

# Attach the Secrets Manager access policy to the IAM role via the instance profile
resource "aws_iam_role_policy_attachment" "attach_secrets_manager_access" {
  role       = aws_iam_role.instance_role.name  # Reference the role attached to the instance profile
  policy_arn = aws_iam_policy.secrets_manager_access.arn        # ARN of the policy created above
}



resource "aws_iam_policy" "kms_policy" {
  name        = "kms-policy"
  description = "Policy for accessing KMS key"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
         
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = [
          aws_kms_key.secrets_manager_key.arn,
          aws_kms_key.ec2_key.arn,
          aws_kms_key.rds_key.arn,
          aws_kms_key.s3_key.arn
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_kms_policy" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.kms_policy.arn
}

resource "aws_secretsmanager_secret" "mailgun_api_key" {
  name       = "mailgun-api-key2"
  kms_key_id = aws_kms_key.secrets_manager_key.arn
}

resource "aws_secretsmanager_secret_version" "mailgun_api_key_version" {
  secret_id     = aws_secretsmanager_secret.mailgun_api_key.id
  secret_string = jsonencode({
    MAILGUN_API_KEY = "ed3026cd34ad11e2eeda7f1564b45db5-6df690bb-d08bd58a"
  })
}
