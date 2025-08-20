# Main Terraform configuration

## Enable an AWS Organization configuration
resource "aws_organizations_organization" "org" {
  feature_set = "ALL"

  aws_service_access_principals = ["cloudtrail.amazonaws.com", "controltower.amazonaws.com", "sso.amazonaws.com", "account.amazonaws.com"]
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]

  # lifecycle {
  #   ignore_changes = [
  #     roots,                         # Ignore changes to roots to prevent drift issues
  #     aws_service_access_principals, # Ignore changes to service access principals to prevent drift issues
  #     enabled_policy_types           # Ignore changes to enabled policy types to prevent drift issues
  #   ]
  # }
}


## Create accounts within the AWS Organization
resource "aws_organizations_account" "log" {
  name              = "LogArchive"
  email             = var.email_log_archive
  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = true

  lifecycle {
    ignore_changes = [
      parent_id # Ignore changes to parent_id to prevent drift issues
    ]
  }
}

resource "aws_organizations_account" "audit" {
  name              = "Audit"
  email             = var.email_audit
  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = true

  lifecycle {
    ignore_changes = [
      parent_id # Ignore changes to parent_id to prevent drift issues
    ]
  }
}


# Input variables for email addresses
variable "email_log_archive" {
  description = "Email address for the Log Archive account"
  type        = string
}

variable "email_audit" {
  description = "Email address for the Audit account"
  type        = string
}

# IAM roles and groups are defined in separate files:
# - iam-ct-admin.tf - AWSControlTowerAdmin role
# - iam-ct-cloudtrail.tf - AWSControlTowerCloudTrailRole role  
# - iam-ct-stackset.tf - AWSControlTowerStackSetRole role
# - iam-ct-config.tf - AWSControlTowerConfigAggregatorRoleForOrganizations role
# - iam-ct-execution.tf - AWSControlTowerExecution role
# - iam-ct-administrator.tf - ControlTowerAdministrator role (human access with MFA)
# - iam-billing-admin.tf - AWSControlTowerBillingAdmin role  
# - iam-billing-reader.tf - AWSControlTowerBillingReader role
# - sso-billing-permission-sets.tf - Identity Center Permission Sets and groups for billing access


# Manifes configurations
locals {
  governed_regions = ["eu-west-1", "eu-central-1", "il-central-1", "eu-west-2"]

  lz_manifest = {
    governedRegions = local.governed_regions
    organizationStructure = {
      security = { name = "Security" }
      sandbox  = { name = "Sandbox" }
    }
    centralizedLogging = {
      accountId = aws_organizations_account.log.id
      configurations = {
        loggingBucket       = { retentionDays = "90" }
        accessLoggingBucket = { retentionDays = "90" }
      }
      enabled = true
    }

    securityRoles    = { accountId = aws_organizations_account.audit.id }
    accessManagement = { enabled = true }
  }
}

# Create the AWS Control Tower Landing Zone
resource "aws_controltower_landing_zone" "lz" {
  manifest_json = jsonencode(local.lz_manifest)
  version       = "3.3"

  timeouts {
    create = "90m"
    delete = "90m"
  }
}


