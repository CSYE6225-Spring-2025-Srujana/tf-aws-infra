variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "total_public_subnets" {
  description = "Total number of public subnets to create"
  type        = number
  default     = 3
}

variable "total_private_subnets" {
  description = "Total number of private subnets to create"
  type        = number
  default     = 3
}

variable "subnet_size" {
  description = "Subnet size for CIDR calculations"
  type        = number
  default     = 4
}

variable "aws_profile" {
  description = "AWS CLI Profile to use"
  type        = string
}

# variable "ami_name_prefix" {
#   description = "Prefix for the AMI built using Packer"
#   type        = string
# }

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "app_port" {
  description = "Port on which the application runs"
  type        = number
}

variable "domain_name" {
  description = "Name of the VPC"
  type        = string
}
