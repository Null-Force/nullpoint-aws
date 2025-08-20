# AWS SSO (Identity Center) Permission Sets for Billing Access

# Get SSO instance
data "aws_ssoadmin_instances" "current" {}

# Billing Administrators Permission Set
resource "aws_ssoadmin_permission_set" "billing_administrators" {
  name             = "AWSBillingAdministrators"
  description      = "Full billing administration access - can manage costs, budgets, and billing settings"
  instance_arn     = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  session_duration = "PT8H"

  tags = {
    Purpose = "Billing Administration"
    Access  = "Infrastructure Read + Billing Full"
  }
}

# Billing Readers Permission Set
resource "aws_ssoadmin_permission_set" "billing_readers" {
  name             = "AWSBillingReaders"
  description      = "Read-only billing access - can view costs and usage reports"
  instance_arn     = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  session_duration = "PT4H"

  tags = {
    Purpose = "Billing Monitoring"
    Access  = "Billing Read Only"
  }
}

# Permission Set Inline Policy for Billing Administrators
resource "aws_ssoadmin_permission_set_inline_policy" "billing_administrators" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.billing_administrators.arn
  
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.ct_billing_admin.arn
      }
    ]
  })
}

# Permission Set Inline Policy for Billing Readers
resource "aws_ssoadmin_permission_set_inline_policy" "billing_readers" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.billing_readers.arn
  
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.ct_billing_reader.arn
      }
    ]
  })
}

# Create Identity Center Groups
resource "aws_identitystore_group" "billing_administrators" {
  display_name      = "BillingAdministrators"
  description       = "Group for billing administrators - full billing access"
  identity_store_id = tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0]
}

resource "aws_identitystore_group" "billing_readers" {
  display_name      = "BillingReaders"  
  description       = "Group for billing readers - read-only billing access"
  identity_store_id = tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0]
}

# Account Assignment - Billing Administrators to Management Account
resource "aws_ssoadmin_account_assignment" "billing_administrators_management" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.billing_administrators.arn

  principal_id   = aws_identitystore_group.billing_administrators.group_id
  principal_type = "GROUP"

  target_id   = data.aws_caller_identity.current.account_id
  target_type = "AWS_ACCOUNT"
}

# Account Assignment - Billing Readers to Management Account  
resource "aws_ssoadmin_account_assignment" "billing_readers_management" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.billing_readers.arn

  principal_id   = aws_identitystore_group.billing_readers.group_id
  principal_type = "GROUP"

  target_id   = data.aws_caller_identity.current.account_id
  target_type = "AWS_ACCOUNT"
}