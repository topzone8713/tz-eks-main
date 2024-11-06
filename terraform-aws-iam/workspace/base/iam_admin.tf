##################################################################
# EKS k8sAdmin Role
##################################################################
resource "aws_iam_group" "k8sAdmin" {
  name = "${local.cluster_name}-k8sAdmin"
  path = "/users/"
}
resource "aws_iam_group_policy" "k8sAdmin_policy" {
  name  = "${local.cluster_name}-k8sAdmin"
  group = aws_iam_group.k8sAdmin.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = "${aws_iam_role.k8sAdmin.arn}"
      },
    ]
  })
}
resource "aws_iam_policy" "k8sAdmin" {
  name        = "${local.cluster_name}-k8sAdmin"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "${aws_iam_role.k8sAdmin.arn}"
    }]
  })
}

resource "aws_iam_role" "k8sAdmin" {
  name     = "${local.cluster_name}-k8sAdmin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "sts:AssumeRole",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
    }]
  })
}
resource "aws_iam_user_policy_attachment" "k8sAdmin" {
  user       = "devops1@gmail.com"
  policy_arn = aws_iam_policy.k8sAdmin.arn
}
resource "aws_iam_group_membership" "k8sAdmin" {
  name = "${local.cluster_name}-k8sAdmin"
  users = [
    "${local.cluster_name}-k8sAdmin",
    "devops1@gmail.com"
  ]
  group = aws_iam_group.k8sAdmin.name
}
