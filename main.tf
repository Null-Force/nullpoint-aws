# Main Terraform configuration

## Enable an AWS Organization configuration
resource "aws_organizations_organization" "org" { feature_set = "ALL" }

