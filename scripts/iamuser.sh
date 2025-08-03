#!/bin/bash

# Create IAM user for Terraform with S3 access and AWS Control Tower permissions

# Set default values
DEFAULT_USERNAME="terraform-admin"

echo "=== Terraform IAM User Setup ==="
echo "This script will create an IAM user with Administrator permissions for:"
echo "  - Complete AWS access (AdministratorAccess)"
echo "  - AWS Organizations (for company creation)"
echo "  - AWS Control Tower (for Landing Zone deployment)"
echo "  - All other AWS services"
echo ""
echo "⚠️  WARNING: This user will have near-root privileges!"
echo ""

# Prompt for username
read -p "Enter IAM username (default: $DEFAULT_USERNAME): " USERNAME
USERNAME=${USERNAME:-$DEFAULT_USERNAME}

# Validate username
if [[ -z "$USERNAME" ]]; then
    echo "Error: Username cannot be empty"
    exit 1
fi

# Basic username validation
if [[ ! "$USERNAME" =~ ^[a-zA-Z0-9+=,.@_-]+$ ]] || [[ ${#USERNAME} -gt 64 ]]; then
    echo "Error: Invalid username format"
    echo "Username must:"
    echo "  - Be up to 64 characters long"
    echo "  - Contain only alphanumeric characters and +=,.@_- symbols"
    exit 1
fi

echo ""
echo "Creating IAM user with the following configuration:"
echo "  Username: $USERNAME"
echo "  Permissions: AdministratorAccess (near-root privileges)"
echo "  Tags: adminIAM=true"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Step 1/4: Creating IAM user..."
# 1. Create IAM user with tags
if ! aws iam create-user \
    --user-name "$USERNAME" \
    --tags Key=adminIAM,Value=true Key=Purpose,Value=TerraformAdmin Key=CreatedBy,Value=Script; then
    echo "Error: Failed to create user. User may already exist or you may lack permissions."
    echo "Checking if user already exists..."
    if aws iam get-user --user-name "$USERNAME" >/dev/null 2>&1; then
        echo "User '$USERNAME' already exists. Adding tags and continuing..."
        aws iam tag-user \
            --user-name "$USERNAME" \
            --tags Key=adminIAM,Value=true Key=Purpose,Value=TerraformAdmin Key=CreatedBy,Value=Script
    else
        exit 1
    fi
fi

echo "Step 2/4: Attaching AWS managed policies..."
# 2. Attach AdministratorAccess policy (near-root privileges)
echo "Attaching AdministratorAccess policy..."
if ! aws iam attach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"; then
    echo "Error: Failed to attach AdministratorAccess policy"
    exit 1
fi

echo "Step 3/4: Adding billing management access..."
# 3. Add billing access for budget and cost management  
echo "Attaching Billing policy..."
if ! aws iam attach-user-policy \
    --user-name "$USERNAME" \
    --policy-arn "arn:aws:iam::aws:policy/job-function/Billing"; then
    echo "Warning: Failed to attach Billing policy (user still has admin access)"
fi

echo "Step 4/4: Creating access keys (inactive by default for security)..."
# 4. Create access keys and immediately deactivate for security
echo "Creating access keys..."
if ! ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name "$USERNAME"); then
    echo "Error: Failed to create access keys"
    exit 1
fi

# Extract keys from JSON output
ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | grep -o '"AccessKeyId": "[^"]*"' | cut -d'"' -f4)
SECRET_ACCESS_KEY=$(echo "$ACCESS_KEY_OUTPUT" | grep -o '"SecretAccessKey": "[^"]*"' | cut -d'"' -f4)

# Validate that keys were extracted successfully
if [[ -z "$ACCESS_KEY_ID" ]] || [[ -z "$SECRET_ACCESS_KEY" ]]; then
    echo "Error: Failed to extract access keys from AWS response"
    exit 1
fi

# Immediately deactivate the access key for security
echo "Deactivating access keys for security (use activation script when needed)..."
aws iam update-access-key \
    --user-name "$USERNAME" \
    --access-key-id "$ACCESS_KEY_ID" \
    --status Inactive

echo ""
echo "✅ SUCCESS: IAM user '$USERNAME' created with Administrator permissions"
echo ""
echo "🔐 Access Keys (SAVE THESE SECURELY!):"
echo "────────────────────────────────────────────────────────────────"
echo "AWS_ACCESS_KEY_ID:     $ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $SECRET_ACCESS_KEY"
echo "Status:                INACTIVE (use activation script to enable)"
echo "────────────────────────────────────────────────────────────────"
echo ""
echo "⚠️  SECURITY WARNING:"
echo "   - Keys are INACTIVE by default for security"
echo "   - Use activation/deactivation scripts to control access"
echo "   - Save these credentials securely (password manager, encrypted file)"
echo "   - These keys will NOT be shown again"
echo "   - Do not commit these to source control"
echo ""
echo "📋 Attached Policies:"
echo "   - AdministratorAccess (near-root privileges)"
echo "   - Billing (budget and cost management)"
echo ""
echo "🏷️  User Tags:"
echo "   - adminIAM: true"
echo "   - Purpose: TerraformAdmin"
echo "   - CreatedBy: Script"
echo ""
echo "🚀 User Capabilities (when ACTIVE):"
echo "   ✅ Complete access to ALL AWS services (AdministratorAccess)"
echo "   ✅ Create/manage AWS Organizations and accounts"
echo "   ✅ Deploy/manage AWS Control Tower Landing Zones"
echo "   ✅ Create IAM users/roles for CI/CD with limited permissions"
echo "   ✅ Manage budgets, billing alerts, and cost controls"
echo "   ✅ Full infrastructure deployment and management"
echo ""
echo "🔄 Next Steps:"
echo "   1. Save the credentials securely"
echo "   2. Use activation script when you need to perform admin tasks"
echo "   3. Always deactivate after completing admin work"
echo ""
echo "📝 To manage this user:"
echo "   # Activate keys:"
echo "   aws iam update-access-key --user-name \"$USERNAME\" --access-key-id \"$ACCESS_KEY_ID\" --status Active"
echo ""
echo "   # Deactivate keys:"
echo "   aws iam update-access-key --user-name \"$USERNAME\" --access-key-id \"$ACCESS_KEY_ID\" --status Inactive"
echo ""
echo "   # Check key status:"
echo "   aws iam list-access-keys --user-name \"$USERNAME\""
echo ""
echo "🗑️  To delete this user completely:"
echo "aws iam detach-user-policy --user-name \"$USERNAME\" --policy-arn \"arn:aws:iam::aws:policy/AdministratorAccess\""
echo "aws iam detach-user-policy --user-name \"$USERNAME\" --policy-arn \"arn:aws:iam::aws:policy/job-function/Billing\""
echo "aws iam delete-access-key --user-name \"$USERNAME\" --access-key-id \"$ACCESS_KEY_ID\""
echo "aws iam delete-user --user-name \"$USERNAME\""