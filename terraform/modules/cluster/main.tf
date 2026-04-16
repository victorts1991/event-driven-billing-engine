# --- Cluster EKS ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.prefix}-cluster"
  cluster_version = "1.30"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Permite acesso público ao endpoint (essencial para o runner do GitHub Actions)
  cluster_endpoint_public_access = true

  # --- CONFIGURAÇÃO DE ACESSO ---
  # 1. Garante que quem criou o cluster via API tenha acesso admin inicial
  enable_cluster_creator_admin_permissions = true

  # 2. Mapeia explicitamente o usuário atual do IAM para o RBAC do Kubernetes como Administrator
  access_entries = {
    admin_user = {
      principal_arn = var.admin_principal_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # --- WORKER NODES (Managed Node Groups) ---
  eks_managed_node_groups = {
    billing_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Instâncias t3.medium 
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT" # Economia máxima usando instâncias Spot

      ami_type       = "AL2_x86_64"

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