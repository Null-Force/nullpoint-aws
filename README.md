# nullpoint-aws

> **The foundation layer of nullforce-kickstart-aws** - AWS Control Tower Landing Zone infrastructure with graduated access control and complete automation.

The initial phase of the complex modular deployment involves preparing an AWS account for Control Tower Landing Zone and ongoing deployments.

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

Choose the appropriate command based on what you want to test:

```bash
# Plan - validate and preview changes (safe, no modifications)
act -j terraform-plan \
  --secret-file "../environments/main.secrets" \
  --var-file "../environments/main.variables"

# Apply - actually deploy infrastructure (makes real changes!)
act -j terraform-apply \
  --secret-file "../environments/main.secrets" \
  --var-file "../environments/main.variables"

# Destroy - remove all infrastructure (destructive!)
act -j terraform-destroy \
  --secret-file "../environments/main.secrets" \
  --var-file "../environments/main.variables"
```

**Workflow explanation:**
- **Plan**: Validates configuration and shows what will change (safe)
- **Apply**: Actually creates/modifies AWS resources (use carefully)  
- **Destroy**: Removes all managed infrastructure (destructive)

The same pipeline file works identically in both local testing and GitHub Actions.

## AWS Control Tower Landing Zone

This infrastructure deploys a complete AWS Control Tower Landing Zone using programmatic API deployment with all required IAM roles and graduated access control.

### Architecture Overview

The deployment creates:
- **AWS Organizations** with ALL feature set enabled
- **Audit Account** - Security monitoring and compliance
- **Log Archive Account** - Centralized logging storage
- **Security OU** - Organizational unit for security accounts
- **Sandbox OU** - Organizational unit for experimentation
- **Landing Zone** - Complete Control Tower setup with governance

### IAM Roles and Access Control

The infrastructure creates a comprehensive set of IAM roles for different access levels and responsibilities:

#### Control Tower Service Roles
┌───────────────────────────────────────────────────────┬──────────────────────────────────┬─────────────────────────────────────┐
| Role Name                                             | Purpose                          | Permissions                         |
┌───────────────────────────────────────────────────────┬──────────────────────────────────┬─────────────────────────────────────┐
| `AWSControlTowerAdmin`                                | Primary Control Tower management | Full Control Tower + Billing access |
| `AWSControlTowerCloudTrailRole`                       | CloudTrail logging service       | CloudWatch Logs management          |
| `AWSControlTowerStackSetRole`                         | CloudFormation operations        | Cross-account StackSet management   |
| `AWSControlTowerConfigAggregatorRoleForOrganizations` | Config aggregation               | Organization-wide Config access     |
└───────────────────────────────────────────────────────┴──────────────────────────────────┴─────────────────────────────────────┴

#### Graduated Access Control Roles
| Role Name                      | Infrastructure Access | Billing Access  | Use Case                               |
|--------------------------------|-----------------------|-----------------|----------------------------------------|
| `AWSControlTowerAdmin`         | **Full Access**       | **Full Access** | DevOps team for infrastructure changes |
| `AWSControlTowerBillingAdmin`  | **Read Only**         | **Full Access** | Finance team for cost management       |
| `AWSControlTowerBillingReader` | **None**              | **Read Only**   | Managers for cost monitoring           |

### Access Control Matrix

```
┌─────────────────────────┬─────────────────┬──────────────────┬─────────────────┐
│ Role                    │ Infrastructure  │ Billing          │ Account Creation│
├─────────────────────────┼─────────────────┼──────────────────┼─────────────────┤
│ AWSControlTowerAdmin    │ Full Access     │ Full Access      │ ✅ Yes          │
│ BillingAdmin            │ Read Only       │ Full Access      │ ❌ No           │
│ BillingReader           │ None            │ Read Only        │ ❌ No           │
└─────────────────────────┴─────────────────┴──────────────────┴─────────────────┘
```

### Governance Features

- **🏛️ Organizational Structure**: Automatic Security and Sandbox OU creation
- **📊 Centralized Logging**: 90-day retention for CloudTrail and access logs
- **🔐 Access Management**: IAM Identity Center integration enabled
- **🌍 Multi-Region**: Governed regions support (default: eu-central-1)
- **🔒 Security Controls**: Service Control Policies applied automatically
- **📋 Compliance**: AWS Config organization-wide monitoring

### Deployment Process

1. **Bootstrap**: Run bootstrap scripts to create admin user and S3 backend
2. **Organization Accounts**: Terraform creates audit and log archive accounts
3. **IAM Roles**: All Control Tower service roles created with proper trust policies
4. **Landing Zone**: Automated deployment with custom manifest configuration
5. **Governance**: Service Control Policies and guardrails applied automatically

### Configuration

The Landing Zone configuration includes:
- **Governed Regions**: `eu-central-1` (configurable via variables)
- **Account Structure**: Management, Audit, Log Archive accounts
- **Logging Retention**: 90 days for both access and CloudTrail logs
- **Access Management**: IAM Identity Center enabled for SSO

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

## Required Variables

Before deploying the infrastructure, configure the following variables in your GitHub repository or environment:

### GitHub Repository Variables
Configure these in `Settings > Secrets and variables > Actions > Variables`:

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_REGION` | Primary AWS region for deployment | `eu-central-1` |
| `EMAIL_LOG_ARCHIVE` | Email for Log Archive account creation | `yourorg+log@example.com` |
| `EMAIL_AUDIT` | Email for Audit account creation | `yourorg+audit@example.com` |
| `TERRAFORM_STATE_BUCKET` | S3 bucket for Terraform state | `your-terraform-state-bucket` |
| `BACKEND_REGION` | AWS region for Terraform backend | `eu-central-1` |

### GitHub Repository Secrets
Configure these in `Settings > Secrets and variables > Actions > Secrets`:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for deployment |

### Terraform Variables
When running locally, create `terraform.tfvars`:

```hcl
aws_region        = "eu-central-1"
email_log_archive = "yourorg+log@example.com"
email_audit       = "yourorg+audit@example.com"
```

### Email Requirements

- **Unique emails required**: Each account needs a unique email address
- **Alias support**: You can use `+` aliases (e.g., `yourorg+audit@example.com`)
- **Access**: These emails become the root user for each account
- **3 total emails needed**: management (existing), audit (new), log archive (new)

## Deployment Steps

1. **Bootstrap Environment**:
   ```bash
   ./scripts/create-admin-iam-user.sh
   ./scripts/create-terraform-backend.sh
   ```

2. **Configure Variables**: Set up GitHub repository variables and secrets

3. **Deploy Infrastructure**:
   - Via GitHub Actions: Use workflow dispatch for `terraform-apply`
   - Via Local: `terraform plan && terraform apply`

4. **Verify Deployment**: Check AWS Control Tower console for Landing Zone status

The deployment typically takes 60-90 minutes to complete due to Control Tower Landing Zone setup time.