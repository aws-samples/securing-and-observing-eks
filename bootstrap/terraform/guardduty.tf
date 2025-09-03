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

module "standalone_guardduty" {
  source  = "aws-ia/guardduty/aws"
  version = "0.0.2"

  enable_guardduty             = true
  enable_s3_protection         = true
  enable_kubernetes_protection = true
  enable_malware_protection    = true
  enable_snapshot_retention    = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  tags                         = {}
}