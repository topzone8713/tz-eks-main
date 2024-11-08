locals {
  cluster_name                  = var.cluster_name
  name                          = local.cluster_name
  region                        = var.region
  environment                   = var.environment
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler-chart"
  tzcorp_zone_id                = var.tzcorp_zone_id
  tzcorp_hosted_zone            = var.tzcorp_hosted_zone
  tags                          = {
    application: local.cluster_name,
    environment: local.environment,
  }
  VCP_BCLASS = var.VCP_BCLASS
  VPC_CIDR   = "${local.VCP_BCLASS}.0.0/16"
  instance_type = var.instance_type

  allowed_management_cidr_blocks = [
    local.VPC_CIDR,
  ]

  allowed_internal_cidr_blocks = [
    local.VPC_CIDR,
  ]

  aws_auth_configmap_yaml = <<-EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapAccounts: |
    - "${var.account_id}"
  mapRoles: |
    - "groups":
      - "system:bootstrappers"
      - "system:nodes"
      "rolearn": "arn:aws:iam::${var.account_id}:role/devops-eks-node-group-2023042005263524540000000b"
      "username": "system:node:{{EC2PrivateDNSName}}"
    - "groups":
      - "${local.cluster_name}-k8sAdmin"
      "rolearn": "arn:aws:iam::${var.account_id}:role/${local.cluster_name}-k8sAdmin"
      "username": "${local.cluster_name}-k8sAdmin"
    - "groups":
      - "${local.cluster_name}-k8sDev"
      "rolearn": "arn:aws:iam::${var.account_id}:role/${local.cluster_name}-k8sDev"
      "username": "${local.cluster_name}-k8sDev"
  mapUsers: |
    - "groups":
      - "system:masters"
      "userarn": "arn:aws:iam::${var.account_id}:user/devops"
      "username": "devops"
    - "groups":
      - "system:masters"
      "userarn": "arn:aws:iam::${var.account_id}:user/adminuser"
      "username": "adminuser"
    - "groups":
      - "system:masters"
      - "system:nodes"
      "userarn": "arn:aws:iam::${var.account_id}:user/doohee@topzone.me"
      "username": "doohee@topzone.me"
    - "groups":
      - "${local.cluster_name}-k8sDev"
      - "system:nodes"
      "userarn": "arn:aws:iam::${var.account_id}:user/doogee"
      "username": "doogee"
EOT

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${var.account_id}:role/${local.cluster_name}-k8sAdmin"
      username = "${local.cluster_name}-k8sAdmin"
      groups   = ["${local.cluster_name}-k8sAdmin"]
    },
    {
      rolearn  = "arn:aws:iam::${var.account_id}:role/${local.cluster_name}-k8sDev"
      username = "${local.cluster_name}-k8sDev"
      groups   = ["${local.cluster_name}-k8sDev"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/devops"
      username = "devops"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/adminuser"
      username = "adminuser"
      groups   = ["system:masters"]
    },
//    {
//      userarn  = "arn:aws:iam::${var.account_id}:user/${local.cluster_name}-k8sAdmin"
//      username = "${local.cluster_name}-k8sAdmin"
//      groups   = ["system:masters","system:nodes"]
//    },
//    {
//      userarn  = "arn:aws:iam::${var.account_id}:user/${local.cluster_name}-k8sDev"
//      username = "${local.cluster_name}-k8sDev"
//      groups   = ["system:masters","system:nodes"]
//    },
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/doohee@topzone.me"
      username = "doohee@topzone.me"
      groups   = ["system:masters","system:nodes"]
    }
  ]

}
