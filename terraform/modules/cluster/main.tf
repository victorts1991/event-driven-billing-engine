# --- Cluster EKS ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.prefix}-cluster"
  cluster_version = "1.30"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true
  
  include_oidc_root_ca_thumbprint = true

  # --- WORKER NODES (Managed Node Groups) ---
  eks_managed_node_groups = {
    billing_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT" 

      ami_type       = "AL2023_x86_64"

      labels = {
        role = "worker"
      }
    }
  }

  tags = {
    Project = var.prefix
    ManagedBy = "Terraform"
  }
}