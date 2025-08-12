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