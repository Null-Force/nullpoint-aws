# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# nullpoint-aws

> **The foundation layer of nullforce-kickstart-aws** - Terraform-based AWS infrastructure foundation with bootstrap scripts for initial setup.

## Current Status

**⚠️ DEVELOPMENT IN PROGRESS**: This repository currently contains a basic Terraform setup with a test S3 bucket implementation. The full AWS Control Tower Landing Zone infrastructure is planned but not yet implemented.

## Essential Development Commands

### Terraform Workflow
```bash
# Basic Terraform commands (requires backend configuration first)
terraform init
terraform validate 
terraform fmt -recursive
terraform plan
terraform apply
terraform output
terraform destroy

# Backend initialization (after running bootstrap scripts)
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=eu-central-1"
```

### Bootstrap Scripts (First-Time Setup)
```bash
# 1. Create admin IAM user with Administrator access
./scripts/create-admin-iam-user.sh

# 2. Create S3 backend for Terraform state storage
./scripts/create-terraform-backend.sh

# 3. Manage admin user access (activate/deactivate keys)
./scripts/manage-admin-iam-access.sh
```

### Local CI/CD Testing
```bash
# Test GitHub Actions pipeline locally with act
act -j terraform \
  --env AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)" \
  --env AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key)" \
  --env AWS_DEFAULT_REGION="$(aws configure get region || echo eu-central-1)" \
  --env TERRAFORM_STATE_BUCKET="your-terraform-state-bucket"
```

### Configuration Management
```bash
# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars to set AWS region (default: eu-central-1)
```

## Architecture Overview

### Current Implementation
The repository currently implements a minimal Terraform setup for testing AWS connectivity:

- **Test S3 Bucket**: Simple bucket with random suffix in `main.tf:3-8`
- **S3 Backend**: Configured but requires manual initialization via bootstrap scripts
- **AWS Provider**: Standard configuration with default tagging in `providers.tf:7-16`
- **Version Constraints**: Terraform >= 1.6.0, AWS provider ~> 6.0 in `versions.tf`

### Bootstrap Architecture
The repository solves the "chicken and egg" problem of Terraform state storage through three critical scripts:

1. **IAM User Creation** (`scripts/create-admin-iam-user.sh`):
   - Creates IAM user with AdministratorAccess policy
   - Generates access keys (inactive by default for security)
   - Includes billing access for cost management

2. **S3 Backend Creation** (`scripts/create-terraform-backend.sh`):
   - Creates S3 bucket with versioning, encryption, and lifecycle policies
   - Configures IAM-only access (blocks root account)
   - Sets up proper bucket policy and logging

3. **Access Management** (`scripts/manage-admin-iam-access.sh`):
   - Activates/deactivates admin user access keys
   - Lists admin users with status
   - Security-focused activation workflow

### File Structure
```
├── main.tf              # Test S3 bucket resource
├── variables.tf         # Input variables (aws_region)
├── outputs.tf           # Output values (currently empty)
├── providers.tf         # AWS provider with S3 backend config
├── versions.tf          # Version constraints
├── locals.tf            # Local values (currently empty)
├── data.tf              # Data sources (currently empty)
├── scripts/             # Bootstrap automation scripts
│   ├── create-admin-iam-user.sh
│   ├── create-terraform-backend.sh
│   └── manage-admin-iam-access.sh
├── environments/        # Environment-specific configs (empty)
└── modules/             # Reusable modules (empty)
```

## Key Configuration Details

### Backend Configuration
The S3 backend is configured in `providers.tf:3-5` but requires initialization:
```hcl
terraform {
  backend "s3" {}
}
```

### AWS Provider Setup
Provider includes automatic resource tagging in `providers.tf:10-16`:
- Project: "nullforce-kickstart-aws"
- Component: "nullpoint-aws"  
- ManagedBy: "Terraform"

### CI/CD Pipeline
GitHub Actions workflow (`.github/workflows/terraform.yml`) provides:
- AWS CLI and Terraform installation
- Credential validation with `aws sts get-caller-identity`
- Compatible with local testing via `act`

## Development Workflow

### Initial Setup Sequence
1. **Bootstrap Phase**: Run scripts in order to create IAM user and S3 backend
2. **Configuration**: Copy `terraform.tfvars.example` to `terraform.tfvars`
3. **Backend Init**: Initialize Terraform with backend configuration
4. **Development**: Standard Terraform workflow (plan, apply, etc.)

### Security Best Practices
- Admin IAM user keys are **inactive by default**
- Use activation script only when needed, deactivate immediately after
- S3 backend bucket blocks public access and root account access
- All resources include comprehensive tagging for governance

### Prerequisites
- AWS CLI installed and configured
- Terraform >= 1.6.0 installed
- 3 unique email addresses for future Control Tower accounts
- AdministratorAccess permissions on AWS account

## Integration Notes

### MCP Server Compatibility
This repository is optimized for use with Claude Code's AWS-Terraform MCP server. Key integration points:

- **Bootstrap Scripts**: Solve initial setup challenges before Terraform can manage state
- **Backend Configuration**: S3 backend setup aligns with MCP server expectations
- **Tagging Strategy**: Consistent resource tagging supports infrastructure governance

### Future Ecosystem Integration
Part of the nullforce-kickstart-aws ecosystem:
- 🏗️ **nullpoint-aws** (this repo) - Landing Zone foundation
- 🔄 **hubpoint-aws** - Shared services and connectivity  
- ⚡ **workpoint-aws** - Application workload templates