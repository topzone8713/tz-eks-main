provider "aws" {
  region = local.region
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = "1.33"

  endpoint_private_access = true
  endpoint_public_access  = true
  create_cloudwatch_log_group = false

  authentication_mode = "API_AND_CONFIG_MAP"

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  create_kms_key = true
  encryption_config = {
    resources = ["secrets"]
  }
  kms_key_deletion_window_in_days = 7
  enable_kms_key_rotation         = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

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

  enable_cluster_creator_admin_permissions = false

  access_entries = {
    root-account = {
      principal_arn = "arn:aws:iam::${var.account_id}:root"
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

  eks_managed_node_groups = {
    devops = {
      instance_types = [local.instance_type]
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size     = 3
      max_size     = 3
      desired_size = 3

      # Note: desired_size is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack

      subnets = [element(module.vpc.private_subnets, 0)]
      disk_size = 30

      labels = {
        team        = "devops"
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

      # Optional: Additional nodeadm configuration
      # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
      # cloudinit_pre_nodeadm = [
      #   {
      #     content_type = "application/node.eks.aws"
      #     content      = <<-EOT
      #       ---
      #       apiVersion: node.eks.aws/v1alpha1
      #       kind: NodeConfig
      #       spec:
      #         kubelet:
      #           config:
      #             shutdownGracePeriod: 30s
      #     EOT
      #   }
      # ]
    }
  }

  tags = local.tags
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name = "${local.name}-ebs-csi"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  tags = local.tags

  depends_on = [module.eks]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn = module.ebs_csi_irsa.arn

  tags = local.tags

  depends_on = [module.ebs_csi_irsa]
}
