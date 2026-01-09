module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    amc-cluster-wg = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["m7i-flex.large"] # Perfect choice!
      capacity_type  = "ON_DEMAND"

      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  tags = local.tags
}