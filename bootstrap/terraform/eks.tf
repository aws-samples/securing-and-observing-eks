################################################################################
# EKS Cluster
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.5"

  cluster_name                   = local.name
  cluster_version                = "1.29"
  cluster_endpoint_public_access = true

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    aws-guardduty-agent = {
      most_recent = true
    }

  }
  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API"

  eks_managed_node_groups = {
    default = {
      instance_types = ["m5.large", "m5a.large"]
      iam_role_attach_cni_policy = true

      min_size     = 1
      max_size     = 5
      desired_size = 3

      ebs_optimized     = true
      enable_monitoring = true
    }
  }

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.name
  })
}
