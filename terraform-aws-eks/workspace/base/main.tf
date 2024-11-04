provider "aws" {
  region = local.region
}

################################################################################
# EKS Module
################################################################################

# resource "aws_eks_identity_provider_config" "eks_provider_config" {
#   cluster_name = local.name
#   oidc {
#     client_id                     = "sts.amazonaws.com"
#     identity_provider_config_name = "sts"
#     issuer_url                    = module.eks.cluster_oidc_issuer_url
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

  cluster_name                    = local.name
  cluster_version                 = "1.29"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  create_cloudwatch_log_group     = false

  authentication_mode             = "API_AND_CONFIG_MAP"

#   create_aws_auth_configmap = true
#   manage_aws_auth_configmap = true
#   aws_auth_roles = local.aws_auth_roles
#   aws_auth_users = local.aws_auth_users
#   aws_auth_accounts = [
#     var.account_id
#   ]
#

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    eks-pod-identity-agent = {}
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  create_kms_key = true
  cluster_encryption_config = {
    "resources": [
      "secrets"
    ]
  }
  kms_key_deletion_window_in_days = 7
  enable_kms_key_rotation         = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = [local.instance_type]

    attach_cluster_primary_security_group = false
    vpc_security_group_ids                = [aws_security_group.all_worker_mgmt.id]
    # Force gp3 & encryption (https://github.com/bottlerocket-os/bottlerocket#default-volumes)
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs         = {
          volume_size           = 50
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 150
          encrypted             = true
          delete_on_termination = true
        }
      }
//      xvdb = {
//        device_name = "/dev/xvdb"
//        ebs         = {
//          volume_size           = 50
//          volume_type           = "gp3"
//          iops                  = 3000
//          throughput            = 150
//          encrypted             = true
//          delete_on_termination = true
//        }
//      }
    }
  }

  enable_cluster_creator_admin_permissions = true

#   access_entries = {
#     example = {
#       kubernetes_groups = []
#       principal_arn     = "arn:aws:iam::xxxxxxxxx:role/topzone-k8s-k8sAdmin"
#       policy_associations = {
#         example = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
#           access_scope = {
#             namespaces = ["default"]
#             type       = "namespace"
#           }
#         }
#       }
#     }
#   }

  eks_managed_node_groups = {
    devops = {
      desired_size = 4
      min_size     = 4
      max_size     = 7
      instance_types = [local.instance_type]
      subnets = [element(module.vpc.private_subnets, 0)]
      disk_size = 30
      labels = {
        team = "devops"
        environment = "prod"
      }
      update_config = {
        max_unavailable_percentage = 80 # or set `max_unavailable`
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

  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }

  tags = local.tags
}

################################################################################
# Disabled creation
################################################################################
module "disabled_eks" {
  source  = "terraform-aws-modules/eks/aws"

  create = false
}

module "disabled_eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  create = false
}

