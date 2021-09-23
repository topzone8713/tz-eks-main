terraform {
  required_version = ">= 0.12.0"

  backend "s3" {
    region  = "ap-northeast-2"
    bucket  = "terraform-state-eks-main-01"
    key     = "terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-lock-2"
  }
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "terraform-state-${local.cluster_name}-01"
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-lock-2"
  hash_key       = "LockID"
  billing_mode   = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}

provider "aws" {
  version = ">= 2.28.1"
  region  = local.region
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

module "eks" {
  source          = "../.."
  cluster_name    = local.cluster_name
  cluster_version = "1.17"
  subnets         = module.vpc.private_subnets
  enable_irsa     = true

  tags = {
    application = local.cluster_name,
    environment = "prod",
    service = "web",
    team = "tz",
  }

  vpc_id = module.vpc.vpc_id

//  worker_groups = [
//    for subnet in module.vpc.private_subnets :
//    {
//      subnets              = [subnet],
//      asg_desired_capacity = 3,
//      instance_type        = "m5.large",
//    }
//  ]

  worker_groups = [
    {
      name                 = "devops"
      instance_type        = local.instance_type
      additional_userdata           = "echo devops-eks"
      asg_desired_capacity = 1
      min_capacity = 1
      max_capacity = 1
      additional_security_group_ids = [aws_security_group.worker_group_devops.id]
      tags = [
        {
          key                 = "k8s.io/cluster-autoscaler/enabled"
          propagate_at_launch = "false"
          value               = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          propagate_at_launch = "false"
          value               = "true"
        },
        {
          key                 = "org"
          propagate_at_launch = "false"
          value               = "tz"
        }
      ]
    },
  ]

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }


    devops-dev = {
      desired_capacity = 2
      max_capacity     = 5
      min_capacity     = 3
      instance_types = [local.instance_type]
      subnets = [element(module.vpc.private_subnets, 0)]
      disk_size = 30
      k8s_labels = {
        team = "devops"
        environment = "dev"
      }
    },
    consul = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 1
      instance_types = [local.instance_type]
      subnets = [element(module.vpc.private_subnets, 1)]
      disk_size = 100
      k8s_labels = {
        team = "devops"
        environment = "consul"
      }
    },
    datadog = {
      desired_capacity = 2
      max_capacity     = 7
      min_capacity     = 2
      instance_types = [local.instance_type]
      subnets = [element(module.vpc.private_subnets, 1)]
      disk_size = 30
      k8s_labels = {
        team = "devops"
        environment = "datadog"
      }
    },
    elk = {
      desired_capacity = 6
      max_capacity     = 7
      min_capacity     = 4
      instance_types = ["m5.large"]
      subnets = [element(module.vpc.private_subnets, 2)]
      disk_size = 30
      k8s_labels = {
        team = "devops"
        environment = "elk"
      }
    }
  }

  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  map_roles    = local.map_roles
  map_users    = local.map_users
  map_accounts = var.map_accounts

}
