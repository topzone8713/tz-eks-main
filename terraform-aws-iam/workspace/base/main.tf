provider "aws" {
  region = "ap-northeast-2"
}

provider "aws" {
  region = "ap-northeast-2"

  alias = "current"
}

data "aws_caller_identity" "iam" {}

data "aws_caller_identity" "current" {
  provider = aws.current
}
