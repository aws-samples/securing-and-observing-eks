data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "s3_read_only" {
  name               = "PodIdentityAmazonS3ReadOnlyAccess"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.s3_read_only.name
}

resource "aws_iam_role" "containerinsight_role" {
  name               = "PodIdentityAmazonCloudWatchObservabilityRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "containerinsight_role" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.containerinsight_role.name
}

# Consumed by the aws-network-flow-monitoring-agent addon via EKS Pod Identity.
# The agent uses this role to publish telemetry reports to the Network Flow Monitor endpoint.
resource "aws_iam_role" "nfm_agent" {
  name               = "${local.name}-nfm-agent"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "nfm_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchNetworkFlowMonitorAgentPublishPolicy"
  role       = aws_iam_role.nfm_agent.name
}
