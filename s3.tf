# resource "random_id" "bucket_id" {
#   byte_length = 4
# }


# resource "aws_s3_bucket_acl" "private_bucket_acl" {
#   bucket = "akash-bucket-${formatdate("YYYYMMDD", timestamp())}-${random_id.bucket_id.hex}"
#   acl    = "private"

# }

# # Generate a random ID for the bucket name
# resource "random_id" "bucket_id" {
#   byte_length = 4
# }

# # Create the S3 Bucket with a unique name
# resource "aws_s3_bucket" "private_bucket" {
#   bucket = "akash-bucket-${formatdate("YYYYMMDD", timestamp())}-${random_id.bucket_id.hex}"
# }

# # Set the ACL for the S3 Bucket, depending on the bucket's existence
# resource "aws_s3_bucket_acl" "private_bucket_acl" {
#   bucket = aws_s3_bucket.private_bucket.id
#   acl    = "private"

#   depends_on = [aws_s3_bucket.private_bucket]  # Ensure the bucket is created first
# }

# Generate a random ID for the bucket name
resource "random_id" "bucket_id" {
  byte_length = 4
}

# Create the S3 Bucket with a unique name
resource "aws_s3_bucket" "private_bucket" {
  bucket = "akash-bucket-${formatdate("YYYYMMDD", timestamp())}-${random_id.bucket_id.hex}"

  acl = "private"


  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}



# If you need to set a bucket policy, you can do it like this
resource "aws_s3_bucket_policy" "private_bucket_policy" {
  bucket = aws_s3_bucket.private_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.private_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:sourceArn" = aws_s3_bucket.private_bucket.arn
          }
        }
      }
    ]
  })
}



resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    id     = "transition_rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}






resource "aws_iam_policy" "cloudwatch_s3_policy" {
  name        = "CloudWatchS3AccessPolicy"
  description = "IAM policy for CloudWatch and S3 access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}/*"
      }
    ]
  })
}




resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.cloudwatch_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_extra_policy" {
  role       = aws_iam_role.instance_role.name # The name of your existing IAM role
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_route53_record" "csye6225_dns_record" {
  zone_id = var.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.csye6225_alb.dns_name
    zone_id                = aws_lb.csye6225_alb.zone_id
    evaluate_target_health = true
  }
}



resource "aws_iam_role" "instance_role" {
  name               = "InstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  role = aws_iam_role.instance_role.name
}


data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_route53_zone" "dev_zone" {
  name = "${var.subdomain}.${var.domain_name}"
}


