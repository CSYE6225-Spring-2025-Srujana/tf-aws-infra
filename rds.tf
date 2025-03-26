variable "rds_db_password" {
  description = "Password for RDS database"
  type        = string
  sensitive   = true
}

resource "random_uuid" "bucket_name" {}

resource "aws_s3_bucket" "webapp_bucket" {
  bucket        = random_uuid.bucket_name.result
  force_destroy = true

  tags = {
    Name = "${var.vpc_name}-webapp-bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_enc" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
  bucket = aws_s3_bucket.webapp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.vpc_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name = "${var.vpc_name}-ec2-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:CreateBucket",
        "s3:PutBucketTagging",
        "s3:PutEncryptionConfiguration",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "rds:CreateDBSubnetGroup",
        "rds:CreateDBParameterGroup"
      ],
      Resource = [
        "arn:aws:s3:::${aws_s3_bucket.webapp_bucket.id}",
        "arn:aws:s3:::${aws_s3_bucket.webapp_bucket.id}/*"
      ]
    },
    {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:DescribeParameters"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
      }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.vpc_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

#rds
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.vpc_name}-rds-subnet-group"
  subnet_ids = aws_subnet.subnets_private[*].id

  tags = {
    Name = "${var.vpc_name}-rds-subnet-group"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.vpc_name}-db-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # Only from app SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-db-sg"
  }
}

resource "aws_db_parameter_group" "rds_param_group" {
  name   = "${var.vpc_name}-param-group"
  family = "mysql8.0" # Adjust to mysql5.7 or mariadb10.5 if needed

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  tags = {
    Name = "${var.vpc_name}-param-group"
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier             = "csye6225"
  engine                 = "mysql"
  engine_version         = "8.0" # Adjust as needed
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "csye6225"
  username               = "csye6225"
  password               = var.rds_db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  parameter_group_name   = aws_db_parameter_group.rds_param_group.name

  tags = {
    Name = "${var.vpc_name}-db"
  }
}
