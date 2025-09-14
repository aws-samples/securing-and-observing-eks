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
  }

  authentication_mode = "API"
  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  tags = local.tags

  depends_on = [aws_vpc_endpoint.guardduty]

}
