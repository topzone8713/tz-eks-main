output "iam_account_id" {
  description = "IAM AWS account id (this code is managing resources in this account)"
  value       = data.aws_caller_identity.iam.account_id
}

output "current_account_id" {
  description = "current AWS account id"
  value       = data.aws_caller_identity.current.account_id
}

output "this_group_users" {
  description = "List of IAM users in IAM group"
  value       = module.iam_managed_policy_admingroup.this_group_users
}

output "this_group_name" {
  description = "IAM group name"
  value       = module.iam_managed_policy_admingroup.this_group_name
}

//output "this_assumable_roles" {
//  description = "List of ARNs of IAM roles which members of IAM group can assume"
//  value       = module.iam_managed_policy_admingroup.this_assumable_roles
//}
//
//output "this_policy_arn" {
//  description = "Assume role policy ARN for IAM group"
//  value       = module.iam_managed_policy_admingroup.this_policy_arn
//}
