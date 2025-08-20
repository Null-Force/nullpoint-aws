# AWS Control Tower Admin Role - Primary Control Tower management

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

# Note: AWSControlTowerServiceRolePolicy may not exist in all regions/accounts
# Using AdministratorAccess for Control Tower admin role instead
resource "aws_iam_role_policy_attachment" "ct_admin_service" {
  role       = aws_iam_role.ct_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

  depends_on = [aws_iam_role.ct_admin]
}

resource "aws_iam_role_policy_attachment" "ct_admin_billing" {
  role       = aws_iam_role.ct_admin.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"

  depends_on = [aws_iam_role.ct_admin]
}