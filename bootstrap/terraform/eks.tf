################################################################################
# EKS Auto Mode Cluster
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.1"

  name                   = local.name
  kubernetes_version     = var.kubernetes_version
  endpoint_public_access = true

  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  addons = {
    aws-guardduty-agent = {
      most_recent = true
    }

    # Network Flow Monitor agent. Auto Mode already provides the Pod Identity
    # capability, so the eks-pod-identity-agent addon is not required here.
    # The addon owns its own namespace, so only the service account is named.
    aws-network-flow-monitoring-agent = {
      most_recent = true

      pod_identity_association = [{
        role_arn        = aws_iam_role.nfm_agent.arn
        service_account = "aws-network-flow-monitor-agent-service-account"
      }]
    }
  }

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  tags = local.tags

  # Both agent addons need their backend authorized before they start, or they come
  # up unable to publish: the NFM agent needs its IAM policy attached, and the
  # GuardDuty agent crashloops on AccessDeniedException until Runtime Monitoring
  # is enabled on the detector.
  depends_on = [
    aws_vpc_endpoint.guardduty,
    aws_iam_role_policy_attachment.nfm_agent,
    aws_guardduty_detector_feature.eks_runtime_monitoring,
  ]

}
