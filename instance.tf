data "aws_ami" "webapp_ami" {
  most_recent = true
  owners      = ["self", "794038250804"]
 
  filter {
    name   = "name"
    values = ["webapp-ami-*"]
  }
 
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# data "aws_ssm_parameter" "latest_custom_ami" {
#   name = "/custom-ami/latest"
# }

resource "tls_private_key" "webapp_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "webapp_key" {
  key_name   = "webapp-key"
  public_key = tls_private_key.webapp_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.webapp_key.private_key_pem
  filename = "${path.module}/webapp-key.pem"
}

resource "aws_security_group" "app_sg" {
  name        = "${var.vpc_name}-app-sg"
  description = "Security group for web application EC2 instance"
  vpc_id      = aws_vpc.main.id

  # Allow SSH (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP (Port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS (Port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Application Port (Modify as needed)
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-app-sg"
  }
}

resource "aws_instance" "web_app" {
  ami                         = data.aws_ami.webapp_ami.id
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.subnets_public[*].id, 0) # Launch in first public subnet
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true # Ensure it's accessible via the internet

  key_name = aws_key_pair.webapp_key.key_name

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true # Ensures volumes are deleted when instance is terminated
  }

  tags = {
    Name = "${var.vpc_name}-webapp"
  }
}

