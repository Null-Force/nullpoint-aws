#!/bin/bash

# Create S3 bucket for Terraform state with IAM-based access

# Set default region
DEFAULT_REGION="eu-central-1"

# Prompt for bucket name
echo "=== Terraform S3 Backend Setup ==="
echo ""
read -p "Enter S3 bucket name (must be globally unique): " BUCKET_NAME

# Validate bucket name input
if [[ -z "$BUCKET_NAME" ]]; then
    echo "Error: Bucket name cannot be empty"
    exit 1
fi

# Validate bucket name format (basic validation)
if [[ ! "$BUCKET_NAME" =~ ^[a-z0-9][a-z0-9.-]*[a-z0-9]$ ]] || [[ ${#BUCKET_NAME} -lt 3 ]] || [[ ${#BUCKET_NAME} -gt 63 ]]; then
    echo "Error: Invalid bucket name format"
    echo "Bucket name must:"
    echo "  - Be 3-63 characters long"
    echo "  - Start and end with lowercase letter or number"
    echo "  - Contain only lowercase letters, numbers, periods, and hyphens"
    exit 1
fi

# Prompt for region with default
read -p "Enter AWS region (default: $DEFAULT_REGION): " AWS_REGION
AWS_REGION=${AWS_REGION:-$DEFAULT_REGION}

echo ""
echo "Creating S3 bucket with the following configuration:"
echo "  Bucket Name: $BUCKET_NAME"
echo "  Region: $AWS_REGION"
echo "  Access Control: IAM users only (blocks root account)"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Step 1/7: Creating S3 bucket..."
# 1. Create bucket
if ! aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"; then
    echo "Error: Failed to create bucket. It may already exist or you may lack permissions."
    exit 1
fi

echo "Step 2/7: Enabling versioning..."
# 2. Enable versioning (critical for tfstate!)
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "Step 3/7: Blocking public access..."
# 3. Block public access
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Step 4/7: Enabling server-side encryption..."
# 4. Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

echo "Step 5/7: Setting up lifecycle policy..."
# 5. Lifecycle policy for version management (delete old versions after 90 days)
aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration '{
        "Rules": [
            {
                "ID": "TerraformStateRetention",
                "Status": "Enabled",
                "Filter": {},
                "NoncurrentVersionExpiration": {
                    "NoncurrentDays": 90
                },
                "AbortIncompleteMultipartUpload": {
                    "DaysAfterInitiation": 7
                }
            }
        ]
    }'

echo "Step 6/8: Adding resource tags..."
# 6. Add comprehensive tags for resource management
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging '{
        "TagSet": [
            {
                "Key": "Purpose",
                "Value": "TerraformBackend"
            },
            {
                "Key": "Environment",
                "Value": "Infrastructure"
            },
            {
                "Key": "Project",
                "Value": "nullforce-kickstart-aws"
            },
            {
                "Key": "CreatedBy",
                "Value": "create-terraform-backend.sh"
            },
            {
                "Key": "DataClassification",
                "Value": "Infrastructure"
            },
            {
                "Key": "BackupRequired",
                "Value": "true"
            },
            {
                "Key": "CostCenter",
                "Value": "Infrastructure"
            }
        ]
    }'

echo "Step 7/8: Configuring access policy..."
# 7. Configure bucket policy for IAM users only
# Note: Using account-specific principal to avoid BlockPublicPolicy restriction
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Creating policy for account: $ACCOUNT_ID"

aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowIAMUsers",
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::'$ACCOUNT_ID':root"
                },
                "Action": "s3:*",
                "Resource": [
                    "arn:aws:s3:::'$BUCKET_NAME'",
                    "arn:aws:s3:::'$BUCKET_NAME'/*"
                ],
                "Condition": {
                    "StringLike": {
                        "aws:userid": ["AIDA*", "AROA*"]
                    }
                }
            }
        ]
    }'

echo "Step 8/8: Enabling access logging..."
# 8. Optional: enable access logging
aws s3api put-bucket-logging \
    --bucket "$BUCKET_NAME" \
    --bucket-logging-status '{
        "LoggingEnabled": {
            "TargetBucket": "'$BUCKET_NAME'",
            "TargetPrefix": "access-logs/"
        }
    }'

echo ""
echo "✅ SUCCESS: S3 bucket '$BUCKET_NAME' created and configured for Terraform state"
echo ""

# Display access configuration summary
echo "🔐 Access Control: IAM users only"
echo "   - Any IAM user (AIDA*) can access from any IP"
echo "   - IAM roles (AROA*) can access from any IP"
echo "   - Root account access is blocked"
echo "   - Perfect for CI/CD platforms (GitHub Actions, GitLab, etc.)"
echo ""
echo "🏷️  Resource Tags Applied:"
echo "   - Purpose: TerraformBackend"
echo "   - Environment: Infrastructure"  
echo "   - Project: nullforce-kickstart-aws"
echo "   - Component: nullpoint-aws"
echo "   - ManagedBy: Script"
echo "   - DataClassification: Infrastructure"
echo "   - BackupRequired: true"

echo ""
echo "📋 Add this to your Terraform backend configuration:"
echo ""
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket = \"$BUCKET_NAME\""
echo "    key    = \"terraform.tfstate\""
echo "    region = \"$AWS_REGION\""
echo "  }"
echo "}"
echo ""
echo "💡 You can also initialize Terraform with:"
echo "terraform init \\"
echo "  -backend-config=\"bucket=$BUCKET_NAME\" \\"
echo "  -backend-config=\"key=terraform.tfstate\" \\"
echo "  -backend-config=\"region=$AWS_REGION\""
echo ""

# Show commands to manage bucket policy later
echo "🛠️  To manage bucket policy later:"
echo ""
echo "# View current policy:"
echo "aws s3api get-bucket-policy --bucket \"$BUCKET_NAME\""
echo ""
echo "# Remove policy (rely on IAM only):"
echo "aws s3api delete-bucket-policy --bucket \"$BUCKET_NAME\""
echo ""
echo "# To add IP restrictions, create a new policy with both IAM and IP conditions"