################################################################################
# EKS Auto Mode Cluster
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.5"

  cluster_name                   = local.name
  cluster_version                = var.version
  cluster_endpoint_public_access = true

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    aws-guardduty-agent = {
      most_recent = true
    }
  }

  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  tags = local.tags

  depends_on = [aws_vpc_endpoint.guardduty]

}
