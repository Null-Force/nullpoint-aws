# Main Terraform configuration

## Enable an AWS Organization configuration
resource "aws_organizations_organization" "org" { feature_set = "ALL" }


## Create accounts within the AWS Organization
resource "aws_organizations_account" "log" {
  name      = "LogArchive"
  email     = var.email_log_archive
  role_name = "OrganizationAccountAccessRole"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "audit" {
  name      = "Audit"
  email     = var.email_audit
  role_name = "OrganizationAccountAccessRole"
  parent_id = aws_organizations_organization.org.roots[0].id
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

# Create IAM roles for AWS Control Tower
data "aws_iam_policy_document" "ct_admin" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["controltower.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ct_admin" {
  name               = "AWSControlTowerAdmin"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.ct_admin.json
}

resource "aws_iam_role_policy_attachment" "ct_admin" {
  role       = aws_iam_role.ct_admin.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSControlTowerServiceRolePolicy"
}


# Create IAM roles for AWS Control Tower CloudTrail
data "aws_iam_policy_document" "ct_cloudtrail" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ct_cloudtrail" {
  name               = "AWSControlTowerCloudTrailRole"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.ct_cloudtrail.json
}

resource "aws_iam_role_policy" "ct_cloudtrail" {
  name = "AWSControlTowerCloudTrailRolePolicy"
  role = aws_iam_role.ct_cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "arn:aws:logs:*:*:log-group:aws-controltower/CloudTrailLogs:*"
      }
    ]
  })
}


# Create IAM roles for AWS Control Tower StackSet
data "aws_iam_policy_document" "ct_stackset" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudformation.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ct_stackset" {
  name               = "AWSControlTowerStackSetRole"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.ct_stackset.json
}

resource "aws_iam_role_policy" "ct_stackset" {
  name = "AWSControlTowerStackSetRolePolicy"
  role = aws_iam_role.ct_stackset.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = ["arn:aws:iam::*:role/AWSControlTowerExecution"]
      }
    ]
  })
}


# Create IAM roles for AWS Control Tower Config
data "aws_iam_policy_document" "ct_config_org" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ct_config_org" {
  name               = "AWSControlTowerConfigAggregatorRoleForOrganizations"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.ct_config_org.json
}

resource "aws_iam_role_policy_attachment" "ct_config_org" {
  role       = aws_iam_role.ct_config_org.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}


# Manifes configurations
locals {
  governed_regions = ["eu-central-1"]

  lz_manifest = {
    governedRegions = local.governed_regions
    organizationStructure = {
      security = { name = "Security" }
      sandbox  = { name = "Sandbox" }
    }
    centralizedLogging = {
      accountId = aws_organizations_account.log.id
      configurations = {
        loggingBucket       = { retentionDays = 90 }
        accessLoggingBucket = { retentionDays = 90 }
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