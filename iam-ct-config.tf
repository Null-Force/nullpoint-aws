# AWS Control Tower Config Role - Config aggregation service

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