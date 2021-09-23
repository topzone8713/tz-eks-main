provider "aws" {
  region = "aws_region"
}

provider "aws" {
  region = "aws_region"

  alias = "development"
}

data "aws_caller_identity" "iam" {}

data "aws_caller_identity" "development" {
  provider = aws.development
}

############
# IAM users
############
module "iam_user1" {
  source = "../../modules/iam-user"

  name = "user1"

  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

module "iam_user2" {
  source = "../../modules/iam-user"

  name = "user2"

  create_iam_user_login_profile = false
  create_iam_access_key         = false
}

#####################################################################################
# Several IAM assumable roles (admin, poweruser, readonly) in development AWS account
# Note: Anyone from IAM account can assume them.
#####################################################################################
module "iam_assumable_roles_in_prod" {
  source = "../../modules/iam-assumable-roles"

  trusted_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.iam.account_id}:root",
    "arn:aws:iam::472304975363:user/adminuser"
  ]

  create_admin_role     = true
  create_poweruser_role = true

  create_readonly_role       = true
  readonly_role_requires_mfa = false

  providers = {
    aws = aws.development
  }
}

module "iam_assumable_role_manager" {
  source = "../../modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.iam.account_id}:root",
  ]

  create_role = true

  role_name         = "manager"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonCognitoReadOnly",
    "arn:aws:iam::aws:policy/AlexaForBusinessFullAccess",
  ]

  providers = {
    aws = aws.development
  }
}

################################################################################################
# IAM group where user1 and user2 are allowed to assume readonly role in development AWS account
# Note: IAM AWS account is default, so there is no need to specify it here.
################################################################################################
module "iam_group_complete" {
  source = "../../modules/iam-group-with-assumable-roles-policy"

  name = "development-readonly"

  assumable_roles = [module.iam_assumable_roles_in_prod.readonly_iam_role_arn]

  group_users = [
    module.iam_user1.this_iam_user_name,
    module.iam_user2.this_iam_user_name,
  ]
}

################################################################################################
# IAM group where user1 is allowed to assume admin role in development AWS account
# Note: IAM AWS account is default, so there is no need to specify it here.
################################################################################################
module "iam_group_with_assumable_roles_policy_development_admin" {
  source = "../../modules/iam-group-with-assumable-roles-policy"

  name = "development-admin"

  assumable_roles = [module.iam_assumable_roles_in_prod.admin_iam_role_arn]

  group_users = [
    module.iam_user1.this_iam_user_name,
  ]
}

################################################################################################
# IAM group where user2 is allowed to assume manager role in development AWS account
# Note: IAM AWS account is default, so there is no need to specify it here.
################################################################################################
module "iam_group_with_assumable_roles_policy_development_manager" {
  source = "../../modules/iam-group-with-assumable-roles-policy"

  name = "development-manager"

  assumable_roles = [module.iam_assumable_role_manager.this_iam_role_arn]

  group_users = [
    module.iam_user2.this_iam_user_name,
  ]
}

####################################################
# Extending policies of IAM group development-admin
####################################################
module "iam_group_complete_with_manager_policy" {
  source = "../../modules/iam-group-with-policies"

  name = module.iam_group_complete.group_name

  create_group = false

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]
}
