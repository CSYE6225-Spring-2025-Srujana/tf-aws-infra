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
  - A Load Balancer
  - An Auto scaling group
  - DNS Management
  - ACM (Amazon Certificate Manager)

- This Terraform setup allows creating multiple VPCs with their own subnets, gateways, and routing tables without hardcoded values. This is achieved by utilizing variables for customization.
- The following resources are defined in the Terraform configuration:
  - **EC2 Instance**: The EC2 instance will be launched using the specified custom AMI and will be associated with the application security group.
  - **Database Security Group**: Restricts database access; allows only internal traffic.  
  - **RDS Instance**: Sets up a private database with secure credentials.  
  - **EC2 Security Group**: Controls app instance access via SSH and Load Balancer.  
  - **S3 Bucket**: Stores data securely with encryption and lifecycle policies.  
  - **Application Load Balancer**: Distributes app traffic; forwards HTTP to EC2.  
  - **Auto Scaling Group**: Manages EC2 instances based on CPU utilization.  
  - **DNS Configuration**: Routes traffic using Route 53 for domain and subdomains.  
  - **AWS Key Management Service (KMS)**:
    Separate KMS keys for:
    - EC2
    - RDS
    - S3 Buckets
    - Secret Manager (Database Password)
    - KMS key rotation period: 90 days
    - KMS keys are referenced in Terraform configurations.
  - **Secrets Management**:
    - Database Password: Auto-generated using Terraform and stored in AWS Secret Manager with a custom KMS key.
    - Retrieved via user-data script to configure the web application.

  - **SSL Certificates**:
    Development Environment: 
    - Uses AWS Certificate Manager for SSL certificates.
    Demo Environment: 
    - Requires an SSL certificate imported from a third-party vendor (e.g., Namecheap).
    Import command:
    ```
    aws acm import-certificate --certificate file://certificate.pem --private-key file://private-key.pem --certificate-chain file://certificate-chain.pem --region <region>
    ```
    - Load balancer is configured to use the imported SSL certificate.
    - Notes:
      - Only HTTPS traffic is supported for the application.
      - HTTP-to-HTTPS redirection is not required.
      - Traffic between the load balancer and EC2 instance uses plain HTTP.
      - Direct connections to the EC2 instance are blocked.

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
- rds_db_password : Password for the database user
- domain_name : Domain name of aws root account


# Using Multiple Environments
- You can create multiple environments (e.g., dev, demo) by maintaining separate .tfvars files with different variable values (like dev.tfvars and demo.tfvars).

- To apply the configuration for the demo environment:

```
terraform plan -var-file="demo.tfvars"
terraform apply -var-file="demo.tfvars"
```