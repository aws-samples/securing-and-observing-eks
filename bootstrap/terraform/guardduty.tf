resource "aws_vpc_endpoint" "guardduty" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${local.region}.guardduty-data"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.guardduty_endpoint.id
  ]

  subnet_ids = module.vpc.private_subnets

  private_dns_enabled = true
}

resource "aws_security_group" "guardduty_endpoint" {
  name        = "guardduty-endpoint-security-group"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for GuardDuty VPC endpoint"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }
}

################################################################################
# GuardDuty detector
#
# The VPC endpoint above and the aws-guardduty-agent addon in eks.tf are only the
# plumbing. Nothing authorizes the agent to publish until EKS_RUNTIME_MONITORING
# is ENABLED on the account's detector. Without it the agent starts, reaches the
# guardduty-data endpoint, then exits on AccessDeniedException and crashloops.
################################################################################

# GuardDuty allows one detector per account per Region. A fresh workshop account
# has none, so the template must create it; an account that already has one (for
# example a shared dev account) must reuse it or the apply fails. Leave this true
# for attendee accounts and set it to false where a detector already exists.
variable "create_guardduty_detector" {
  description = "Create the GuardDuty detector. Set to false to reuse the detector that already exists in this account and Region."
  type        = bool
  default     = true
}

data "aws_guardduty_detector" "existing" {
  count = var.create_guardduty_detector ? 0 : 1
}

resource "aws_guardduty_detector" "this" {
  count = var.create_guardduty_detector ? 1 : 0

  enable = true

  # Shortest available interval so findings surface while attendees are watching.
  # Only applied when this template owns the detector; reusing an existing one
  # deliberately leaves its account-wide settings alone.
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = local.tags
}

locals {
  guardduty_detector_id = var.create_guardduty_detector ? one(aws_guardduty_detector.this[*].id) : one(data.aws_guardduty_detector.existing[*].id)
}

# The fix for the crashloop. EKS_ADDON_MANAGEMENT stays DISABLED because the
# addon is declared explicitly in eks.tf; setting it to ENABLED makes GuardDuty
# install and own that addon and the two would fight over the same resource.
resource "aws_guardduty_detector_feature" "eks_runtime_monitoring" {
  detector_id = local.guardduty_detector_id
  name        = "EKS_RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = "DISABLED"
  }
}

# Surfaces control-plane audit findings, which is what the cluster-admin binding
# on the kube-system default service account in apps.tf is built to trigger.
resource "aws_guardduty_detector_feature" "eks_audit_logs" {
  detector_id = local.guardduty_detector_id
  name        = "EKS_AUDIT_LOGS"
  status      = "ENABLED"
}