terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

#   backend "s3" {
#     region  = "ap-northeast-2"
#     bucket  = "terraform-state-topzone-k8s-101"
#     key     = "terraform.tfstate"
#     encrypt        = true
#     dynamodb_table = "terraform-topzone-k8s-lock-101"
#   }
}
resource "aws_s3_bucket" "tfstate" {
  bucket = "terraform-state-${local.cluster_name}-101"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = "terraform-state-${local.cluster_name}-101"
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-${local.cluster_name}-lock-101"
  hash_key       = "LockID"
  billing_mode   = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}
