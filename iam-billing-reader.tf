# Billing Reader Role - Billing Read Only Access

data "aws_iam_policy_document" "ct_billing_reader" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "ct_billing_reader" {
  name               = "AWSControlTowerBillingReader"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.ct_billing_reader.json

  tags = {
    Purpose = "Control Tower Billing Read Access"
    Access  = "Billing Read Only"
  }
}

resource "aws_iam_role_policy_attachment" "billing_reader" {
  role       = aws_iam_role.ct_billing_reader.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAccountUsageReportAccess"

  depends_on = [aws_iam_role.ct_billing_reader]
}

# Additional billing read permissions via inline policy
resource "aws_iam_role_policy" "billing_reader_additional" {
  name = "BillingReaderAdditionalPermissions"
  role = aws_iam_role.ct_billing_reader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetRightsizingRecommendation",
          "ce:GetUsageReport",
          "ce:ListCostAndUsageSpecifications",
          "budgets:ViewBudget",
          "aws-portal:ViewBilling",
          "aws-portal:ViewAccount"
        ]
        Resource = "*"
      }
    ]
  })
}