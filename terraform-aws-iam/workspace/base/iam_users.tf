#################################################################
# devops
#################################################################
resource "aws_iam_user" "devops" {
  name = "devops1@gmail.com"
}
resource "aws_iam_access_key" "access_key_devops" {
  user = aws_iam_user.devops.name
}
resource "aws_iam_user_login_profile" "login_profile_devops" {
  user = aws_iam_user.devops.name
  password_reset_required = false
}
output "access_key_id_devops" {
  value = aws_iam_access_key.access_key_devops.id
}
output "access_key_devops" {
  value = aws_iam_access_key.access_key_devops.secret
  sensitive = true
}
output "password_devops" {
  value = aws_iam_user_login_profile.login_profile_devops.password
}

// terraform output -json | jq -r .access_key_id_devops.value
// terraform output -json | jq -r .access_key_devops.value
resource "aws_iam_user" "k8sAdmin" {
  name = "${local.cluster_name}-k8sAdmin"
}
resource "aws_iam_user" "k8sDev" {
  name = "${local.cluster_name}-k8sDev"
}
