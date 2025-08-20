# AWS Control Tower StackSet Role - CloudFormation operations

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