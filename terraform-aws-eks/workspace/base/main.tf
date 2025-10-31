provider "aws" {
  region = local.region
}

################################################################################
# EKS Module
################################################################################

#  terraform import aws_eks_identity_provider_config.eks_provider_config topzone-k8s:sts
# resource "aws_eks_identity_provider_config" "eks_provider_config" {
#   cluster_name = "topzone-k8s" # local.name
#   oidc {
#     client_id                     = "sts.amazonaws.com"
#     identity_provider_config_name = "sts"
#     issuer_url                    = module.eks.cluster_oidc_issuer_url
#   }
#   tags = {
#     "application" = "topzone-k8s"
#     "environment" = "prod"
#   }
# }

# aws eks describe-identity-provider-config \
#     --cluster-name topzone-k8s \
#     --identity-provider-config type=oidc,name="sts"

# aws eks disassociate-identity-provider-config \
#   --cluster-name topzone-k8s \
#   --identity-provider-config type=oidc,name="sts"

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                    = local.name
  kubernetes_version      = "1.31"
  endpoint_private_access = true
  endpoint_public_access  = true
  create_cloudwatch_log_group = false

  authentication_mode = "API_AND_CONFIG_MAP"

  addons = {
    coredns = {
      most_recent = true
      resolve_conflicts_on_update = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  create_kms_key = true
  encryption_config = {
    resources = ["secrets"]
  }
  kms_key_deletion_window_in_days = 7
  enable_kms_key_rotation         = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }


  # Disable automatic cluster creator permissions - we'll configure it explicitly via access_entries
  enable_cluster_creator_admin_permissions = false

  # Access entries for IAM roles and users
  # Node groups are automatically handled, but additional roles/users need explicit entries
  # Using kubernetes_groups for RBAC-based access control
  access_entries = {
    # Root account - full admin access (explicit configuration)
    "root-account" = {
      kubernetes_groups = ["system:masters"]
      principal_arn    = "arn:aws:iam::${var.account_id}:root"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # k8sAdmin role
    "${local.name}-k8sAdmin" = {
      kubernetes_groups = ["${local.name}-k8sAdmin"]
      principal_arn    = "arn:aws:iam::${var.account_id}:role/${local.name}-k8sAdmin"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # k8sDev role
    "${local.name}-k8sDev" = {
      kubernetes_groups = ["${local.name}-k8sDev"]
      principal_arn    = "arn:aws:iam::${var.account_id}:role/${local.name}-k8sDev"
      policy_associations = {
        dev = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # devops user
    "devops-user" = {
      kubernetes_groups = ["system:masters"]
      principal_arn    = "arn:aws:iam::${var.account_id}:user/devops"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # adminuser
    "adminuser" = {
      kubernetes_groups = ["system:masters"]
      principal_arn    = "arn:aws:iam::${var.account_id}:user/adminuser"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # doohee@topzone.me user
    "doohee-user" = {
      kubernetes_groups = ["system:masters", "system:nodes"]
      principal_arn    = "arn:aws:iam::${var.account_id}:user/doohee@topzone.me"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    devops = {
      desired_size = 3
      min_size     = 3
      max_size     = 3
      instance_types = [local.instance_type]
      ami_type       = "AL2023_x86_64_STANDARD"
      subnets = [element(module.vpc.private_subnets, 0)]
      disk_size = 30
      labels = {
        team = "devops"
        environment = "prod"
      }
      update_config = {
        max_unavailable_percentage = 80
      }
      vpc_security_group_ids = [
        aws_security_group.worker_group_devops.id
      ]
    }
//    consul = {
//      desired_size = 0
//      min_size     = 2
//      max_size     = 1
//      instance_types = ["t3.large"]
//      subnets = [element(module.vpc.private_subnets, 0)]
//      disk_size = 100
//      labels = {
//        team = "devops"
//        environment = "consul"
//      }
//      update_config = {
//        max_unavailable_percentage = 80
//      }
//      vpc_security_group_ids = [
//        aws_security_group.worker_group_devops.id
//      ]
//    }

  }

  tags = local.tags
}

################################################################################
# Disabled creation
################################################################################
module "disabled_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  create = false
}

module "disabled_eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 21.0"

  create = false
}

