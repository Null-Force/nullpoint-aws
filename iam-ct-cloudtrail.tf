# AWS Control Tower CloudTrail Role - CloudTrail logging service

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