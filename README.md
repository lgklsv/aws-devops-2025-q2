# AWS Infrastructure with Terraform

This project sets up AWS infrastructure using Terraform, including an S3 bucket for Terraform state management and GitHub Actions OIDC provider integration.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or later)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with necessary permissions

## Project Structure

```
.
├── main.tf           # Main Terraform configuration
├── backend.tf        # S3 backend configuration
├── variables.tf      # Input variables
├── oidc_provider.tf  # GitHub Actions OIDC provider configuration
└── README.md         # This file
```

## Backend Configuration

The project uses an S3 backend for storing Terraform state. The backend configuration is split into two parts:

1. `backend.tf` - Contains the basic backend configuration
2. `dev-backend-config.tfvars` - Contains environment-specific backend settings

This separation allows you to:

- Keep sensitive backend configuration out of version control
- Use different backend configurations for different environments
- Override backend settings during initialization

Example `dev-backend-config.tfvars`:

```hcl
bucket       = "my-terraform-state-bucket"
key          = "dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

## Components

### S3 Bucket for Terraform State

- Creates an S3 bucket for storing Terraform state
- Enables versioning for state file history
- Prevents accidental deletion of the bucket

### GitHub Actions OIDC Provider

- Sets up an OpenID Connect provider for GitHub Actions
- Enables secure authentication between GitHub Actions and AWS
- Outputs the OIDC provider ARN for use in other configurations

## Usage

1. Create a `dev-backend-config.tfvars` file with your backend configuration:

```hcl
bucket       = "your-terraform-state-bucket"
key          = "dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

2. Initialize Terraform with the backend configuration:

```bash
terraform init -backend-config="dev-backend-config.tfvars"
```

3. Create a `terraform.tfvars` file with your configuration:

```hcl
project_name    = "my-project"
aws_region      = "us-east-1"
s3_bucket_name  = "my-terraform-state-bucket"
environment     = "dev"  # Can be "dev", "staging", or "prod"
```

4. Review the planned changes:

```bash
terraform plan
```

5. Apply the configuration:

```bash
terraform apply
```

## Security

- The S3 bucket has versioning enabled for state file history
- The bucket has `prevent_destroy` lifecycle rule to prevent accidental deletion
- GitHub Actions OIDC provider enables secure authentication without storing AWS credentials
- Backend configuration is separated from the main configuration for better security
