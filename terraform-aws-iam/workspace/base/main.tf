provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  region = "us-west-1"

  alias = "current"
}

data "aws_caller_identity" "iam" {}

data "aws_caller_identity" "current" {
  provider = aws.current
}

############
# IAM users
############
module "adminuser" {
  source = "../../modules/iam-user"
  name = "adminuser"
  create_iam_user_login_profile = false
  create_iam_access_key         = false
}