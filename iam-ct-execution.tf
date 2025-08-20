# Critical Control Tower Execution Role - Required in ALL accounts

data "aws_iam_policy_document" "ct_execution" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        aws_iam_role.ct_admin.arn,
        aws_iam_role.ct_stackset.arn
      ]
    }
  }
}

resource "aws_iam_role" "ct_execution" {
  name               = "AWSControlTowerExecution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ct_execution.json

  tags = {
    Purpose = "Control Tower Cross-Account Execution Role"
    Access  = "StackSet and Cross-Account Operations"
  }
}

resource "aws_iam_role_policy_attachment" "ct_execution_admin" {
  role       = aws_iam_role.ct_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

  depends_on = [aws_iam_role.ct_execution]
}