data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ec2_kms" {
  description             = "KMS key for EC2 EBS encryption"
  enable_key_rotation     = var.enable_key_rotation
  rotation_period_in_days = var.rotation_period_in_days
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
      },
      {
        "Sid" : "Allow service-linked role use of the customer managed key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:CreateGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : true
          }
        }
      }
    ]
  })

  tags = {
    Name = "EC2 KMS Key"
  }
}

resource "aws_kms_key" "rds_kms_key" {
  description             = "My RDS KMS key"
  enable_key_rotation     = var.enable_key_rotation
  rotation_period_in_days = var.rotation_period_in_days

  tags = {
    Name = "RDS KMS Key"
  }
}

resource "aws_kms_key" "s3_kms" {
  description             = "KMS key for S3 Bucket encryption"
  enable_key_rotation     = var.enable_key_rotation
  rotation_period_in_days = var.rotation_period_in_days
  tags = {
    Name = "S3 KMS Key"
  }
}

resource "aws_kms_key" "secrets_manager_key" {
  description             = "KMS key for encrypting Secrets Manager secrets"
  enable_key_rotation     = var.enable_key_rotation
  rotation_period_in_days = var.rotation_period_in_days
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "Allow Secrets Manager to use the key",
        Effect    = "Allow",
        Principal = { Service = "secretsmanager.amazonaws.com" },
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
  tags = {
    Name = "Secrets Manager KMS Key"
  }
}

resource "random_password" "db_password" {
  length  = var.password_length
  special = var.password_special
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "rdb-password-4"
  kms_key_id              = aws_kms_key.secrets_manager_key.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

resource "aws_iam_role_policy" "secrets_access_policy" {
  name = "secrets-access-policy"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Effect   = "Allow",
        Action   = "kms:Decrypt",
        Resource = aws_kms_key.secrets_manager_key.arn
      }
    ]
  })
}