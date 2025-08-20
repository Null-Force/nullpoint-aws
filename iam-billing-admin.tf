# Billing Admin Role - Infrastructure Read + Billing Full Access

data "aws_iam_policy_document" "ct_billing_admin" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "ct_billing_admin" {
  name               = "AWSControlTowerBillingAdmin"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.ct_billing_admin.json

  tags = {
    Purpose = "Control Tower Billing Administration"
    Access  = "Infrastructure Read + Billing Full"
  }
}

resource "aws_iam_role_policy_attachment" "billing_admin_readonly" {
  role       = aws_iam_role.ct_billing_admin.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"

  depends_on = [aws_iam_role.ct_billing_admin]
}

resource "aws_iam_role_policy_attachment" "billing_admin_billing" {
  role       = aws_iam_role.ct_billing_admin.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"

  depends_on = [aws_iam_role.ct_billing_admin]
}

# Comprehensive billing administration policy
resource "aws_iam_role_policy" "billing_admin_comprehensive" {
  name = "BillingAdminComprehensivePolicy"
  role = aws_iam_role.ct_billing_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # AWS Forecast permissions
        Effect = "Allow"
        Action = [
          "forecast:*"
        ]
        Resource = "*"
      },
      {
        # IAM PassRole for Forecast
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "forecast.amazonaws.com"
          }
        }
      },
      {
        # Comprehensive billing and cost management permissions
        Effect = "Allow"
        Action = [
          "account:GetAccountInformation",
          "aws-portal:*Billing",
          "aws-portal:*PaymentMethods", 
          "aws-portal:*Usage",
          "billing:*",
          "budgets:*",
          "ce:*",
          "consolidatedbilling:*",
          "cur:*",
          "freetier:*",
          "invoicing:*",
          "mapcredits:*",
          "payments:*",
          "pricing:DescribeServices",
          "purchase-orders:*",
          "support:CreateCase",
          "support:AddAttachmentsToSet",
          "sustainability:GetCarbonFootprintSummary",
          "tax:*"
        ]
        Resource = "*"
      },
      {
        # Cost Optimization Hub permissions
        Effect = "Allow"
        Action = [
          "cost-optimization-hub:*",
          "organizations:EnableAWSServiceAccess"
        ]
        Resource = "*"
      },
      {
        # Service-linked role creation for Cost Optimization Hub
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/aws-service-role/cost-optimization-hub.bcm.amazonaws.com/AWSServiceRoleForCostOptimizationHub"
        ]
        Condition = {
          StringLike = {
            "iam:AWSServiceName" = "cost-optimization-hub.bcm.amazonaws.com"
          }
        }
      },
      {
        # Organizations service access for Cost Optimization Hub
        Effect = "Allow"
        Action = [
          "organizations:EnableAWSServiceAccess"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "organizations:ServicePrincipal" = [
              "cost-optimization-hub.bcm.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}