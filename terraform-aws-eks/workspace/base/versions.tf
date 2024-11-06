terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
  }

  backend "s3" {
    region  = "ap-northeast-2"
    bucket  = "terraform-state-topzone-k8s-001"
    key     = "terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-topzone-k8s-lock-001"
  }
}
resource "aws_s3_bucket" "tfstate" {
  bucket = "terraform-state-${local.cluster_name}-001"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = "terraform-state-${local.cluster_name}-001"
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-${local.cluster_name}-lock-001"
  hash_key       = "LockID"
  billing_mode   = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}
