## AWS Networking Infrastructure Setup using Terraform
# Introduction
* This repository (tf-aws-infra) contains Terraform configuration files to create a complete networking setup on AWS. The infrastructure includes:
  - A Virtual Private Cloud (VPC)
  - Public and private subnets across 3 availability zones
  - An Internet Gateway
  - Route tables for public and private subnets
  - An Application Security Group for web applications
  - An EC2 instance using a custom AMI
  - An RDS instance for hosting mysql databases
  - An S3 bucket and database security group

- This Terraform setup allows creating multiple VPCs with their own subnets, gateways, and routing tables without hardcoded values. This is achieved by utilizing variables for customization.

# Prerequisites
Before you begin, ensure that the following are installed and set up on your local machine:

- Terraform (v1.10.5 or later)
- AWS CLI (configured with proper credentials and region)
- AWS account with permissions to create networking resources

# Instructions for Setting Up Infrastructure
- Step 1: Clone the Repository
```
git@github.com:CSYE6225-Spring-2025-Srujana/tf-aws-infra.git
cd tf-aws-infra
```
- Step 2: Initialize Terraform
This command initializes the working directory and downloads the necessary provider plugins.
```
terraform init
``` 
- Step 3: Format the Code
Ensure that all Terraform files are properly formatted 
```
terraform fmt -recursive
```

- Step 4: Validate the Configuration
Run the validation command to ensure the Terraform configuration files are correct:
```
terraform validate
``` 

- Step 5: Create a Plan
Generate an execution plan to preview the actions Terraform will take:
```
terraform plan -var-file="dev.tfvars"
```
The dev.tfvars file contains environment-specific values such as VPC CIDR block, aws_region and more.

- Step 6: Apply the Plan
Run the following command to create the infrastructure on AWS:

```
terraform apply -var-file="dev.tfvars"
```

- Step 7: Destroy the Infrastructure (if needed)
To tear down and remove all resources created by Terraform:

```
terraform destroy -var-file="dev.tfvars"
```

# Variables
- aws_profile: The AWS profile that is configured for an aws user.
- aws_region: AWS region where the infrastructure will be deployed.
- vpc_name: Name of the VPC that is to be created.
- vpc_cidr: CIDR block for the VPC.
- total_public_subnets: Number of public subnets to be created.
- total_private_subnets: Number of private subnets to be created.
- subnet_size: Subnet Size (in subnet mask bits)


# Using Multiple Environments
- You can create multiple environments (e.g., dev, demo) by maintaining separate .tfvars files with different variable values (like dev.tfvars and demo.tfvars).

- To apply the configuration for the demo environment:

```
terraform plan -var-file="demo.tfvars"
terraform apply -var-file="demo.tfvars"
```