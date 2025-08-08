# nullpoint-aws

The initial phase of the complex modular deployment involves preparing an AWS account for ongoing deployments.

## Local Testing with act

You can test the GitHub Actions pipeline locally using [act](https://github.com/nektos/act) before pushing to GitHub.

### Prerequisites
- [act](https://github.com/nektos/act) installed
- Docker running
- Environment files configured (see setup below)

### Setup Environment Files
```bash
# Copy example files
cp environments.secrets.example ../environments/main.secrets
cp environments.variables.example ../environments/main.variables

# Edit with your actual values
# ../environments/main.secrets - your AWS credentials
# ../environments/main.variables - your configuration
```

### Run Pipeline Locally

```bash
act -j terraform \
  --secret-file "../environments/main.secrets" \
  --var-file "../environments/main.variables"
```

This command:
- Runs the `terraform` job from `.github/workflows/terraform.yml`
- Loads secrets from `../environments/main.secrets` (AWS credentials)
- Loads variables from `../environments/main.variables` (configuration)
- Tests the complete Terraform workflow: init, plan, apply

The same pipeline file works identically in both local testing and GitHub Actions.

## Bootstrap Scripts

Solve the "chicken and egg" problem when starting with Terraform and AWS. These scripts automate manual AWS Console tasks and create the foundation needed for Terraform deployments.

### Quick Start - First Time Setup

```bash
# 1. Create admin IAM user (alternative to root account usage)
./scripts/create-admin-iam-user.sh

# 2. Create S3 backend for Terraform state (solves bootstrap problem)  
./scripts/create-terraform-backend.sh

# 3. Manage admin user access (activate only when needed)
./scripts/manage-admin-iam-access.sh
```

### Available Scripts

| Script | Purpose | Replaces Manual Task |
|--------|---------|---------------------|
| `create-admin-iam-user.sh` | Creates IAM user with AdministratorAccess for Terraform operations | Manual IAM user creation in AWS Console |
| `create-terraform-backend.sh` | Creates secure S3 bucket for Terraform state with proper encryption, versioning, and access controls | Manual S3 bucket setup with complex security configuration |
| `manage-admin-iam-access.sh` | Activate/deactivate admin IAM users for security | Manual access key management in AWS Console |

### Why These Scripts Solve the Bootstrap Problem

**The Problem**: Terraform needs AWS credentials and S3 backend to start, but creating these securely requires either:
- Using root account (security risk)
- Manual AWS Console configuration (time-consuming, error-prone)
- Complex manual IAM/S3 setup (difficult to reproduce)

**The Solution**: These scripts automate the entire bootstrap process:
1. **Secure IAM Setup**: Creates admin user with proper tags and inactive keys by default
2. **Production-Ready S3 Backend**: Configures encryption, versioning, lifecycle, and access policies  
3. **Security Management**: Easy activation/deactivation of admin privileges

### Script Features

#### `create-admin-iam-user.sh`
- ✅ Creates IAM user with AdministratorAccess + Billing permissions
- ✅ **Security-first**: Access keys created but immediately deactivated
- ✅ Proper tagging for audit and management
- ✅ Detailed instructions for key management
- ✅ Complete cleanup commands provided

#### `create-terraform-backend.sh`  
- ✅ Interactive setup with validation
- ✅ **Enterprise security**: Encryption, versioning, public access blocking
- ✅ **IAM-based access control**: Blocks root account, allows only IAM users
- ✅ Lifecycle management (90-day version retention)
- ✅ Access logging for audit compliance
- ✅ Ready-to-use Terraform backend configuration

#### `manage-admin-iam-access.sh`
- ✅ **Auto-discovery**: Finds admin users by tags
- ✅ **Interactive management**: List, activate, deactivate users  
- ✅ **Security validation**: Only works with properly tagged admin users
- ✅ Real-time status display (Active/Inactive)
- ✅ Warning prompts for privilege escalation

### Security Best Practices Implemented

- 🔐 **Principle of Least Activation**: Admin keys inactive by default
- 🏷️ **Audit Trail**: All resources properly tagged
- 🚫 **Root Account Blocking**: S3 policies prevent root access
- 🔄 **Lifecycle Management**: Automatic cleanup of old state versions
- ⚠️ **User Warnings**: Clear security implications at each step