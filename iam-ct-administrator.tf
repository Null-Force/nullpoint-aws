# Control Tower Administrator role for human users (MFA required)

data "aws_iam_policy_document" "ct_administrator" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "ct_administrator" {
  name               = "ControlTowerAdministrator"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ct_administrator.json

  tags = {
    Purpose = "Human administrative access to Control Tower resources"
    Access  = "Control Tower Full Administration with MFA"
  }
}

# Core Control Tower permissions
resource "aws_iam_role_policy_attachment" "ct_administrator_organizations" {
  role       = aws_iam_role.ct_administrator.name
  policy_arn = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"

  depends_on = [aws_iam_role.ct_administrator]
}


# Additional permissions for problematic services
resource "aws_iam_role_policy" "ct_administrator_additional" {
  name = "ControlTowerAdministratorAdditional"
  role = aws_iam_role.ct_administrator.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # ServiceCatalog permissions
          "servicecatalog:*",

          # Cost Optimization Hub permissions  
          "cost-optimization-hub:*",
          "ce:*",

          # Security Hub permissions
          "securityhub:*",

          # SSO/Identity Center permissions
          "sso:*",
          "sso-directory:*",
          "identitystore:*",

          # Control Tower specific permissions
          "controltower:*",
          
          # Config permissions
          "config:*",
          
          # CloudFormation permissions
          "cloudformation:*",

          # Additional IAM permissions for role management
          "iam:ListRoles",
          "iam:GetRole",
          "iam:PassRole",
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
      },
      {
        # Allow assumption of Control Tower execution role
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          aws_iam_role.ct_execution.arn,
          aws_iam_role.ct_admin.arn
        ]
      }
    ]
  })
}