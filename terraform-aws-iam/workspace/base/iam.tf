################################################################
resource "aws_iam_role" "bastion-role" {
  name               = "bastion-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "bastion-role" {
  name = "bastion-role"
  role = aws_iam_role.bastion-role.name
}

resource "aws_iam_role_policy" "bastion-policy" {
  name = "bastion-policy"
  role = aws_iam_role.bastion-role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

# #########################################
# # IAM ECR policy
# #########################################
# module "iam_ecr_policy" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   name        = "${local.cluster_name}-ecr-policy"
#   path        = "/"
#   description = "${local.cluster_name}-ecr-policy"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "ecr:*"
#       ],
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }
# resource "aws_iam_role_policy_attachment" "eks-main-ecr-policy" {
#   policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ecr-policy"
#   role       = local.cluster_iam_role_name
#   depends_on = [module.iam_ecr_policy]
# }

# #########################################
# # cert-manager dns-01
# #########################################
# module "cert_manager_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   create_role = true
#   role_name = "cert_manager-${local.cluster_name}"
#   tags = {Role = "cert_manager-${local.cluster_name}-with-oidc"}
#   provider_url  = replace(local.cluster_oidc_issuer_url, "https://", "")
#   role_policy_arns = [aws_iam_policy.cert_manager_policy.arn]
#   oidc_fully_qualified_subjects = [
#     "system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"
#   ]
# }
#
# resource "aws_iam_policy" "cert_manager_policy" {
#   name        = "${local.cluster_name}-cert-manager-policy"
#   path        = "/"
#   description = "Policy, which allows CertManager to create Route53 records"
#
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Action" : "route53:GetChange",
#         "Resource" : "arn:aws:route53:::change/*"
#       },
#       {
#         "Effect": "Allow",
#         "Action": [
#           "route53:ChangeResourceRecordSets",
#           "route53:ListResourceRecordSets"
#         ],
#         "Resource": "arn:aws:route53:::hostedzone/*"
#       },
#       {
#         "Effect": "Allow",
#         "Action": "route53:ListHostedZonesByName",
#         "Resource": "*"
#       }
#     ]
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "eks-main-cert_manager_policy" {
#   policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-cert-manager-policy"
#   role       = local.cluster_iam_role_name
#   depends_on = [aws_iam_policy.cert_manager_policy]
# }

//#########################################
//# velero
//#########################################
//resource "aws_iam_user" "velero" {
//  name = "${local.cluster_name}-velero"
//}
//resource "aws_iam_policy" "velero_policy" {
//  name        = "${local.cluster_name}-velero"
//  description = "${local.cluster_name}-velero"
//  policy = <<EOT
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Effect": "Allow",
//            "Action": [
//                "ec2:DescribeVolumes",
//                "ec2:DescribeSnapshots",
//                "ec2:CreateTags",
//                "ec2:CreateVolume",
//                "ec2:CreateSnapshot",
//                "ec2:DeleteSnapshot"
//            ],
//            "Resource": "*"
//        },
//        {
//            "Effect": "Allow",
//            "Action": [
//                "s3:GetObject",
//                "s3:DeleteObject",
//                "s3:PutObject",
//                "s3:AbortMultipartUpload",
//                "s3:ListMultipartUploadParts"
//            ],
//            "Resource": [
//                "arn:aws:s3:::/*"
//            ]
//        },
//        {
//            "Effect": "Allow",
//            "Action": [
//                "s3:ListBucket"
//            ],
//            "Resource": [
//                "arn:aws:s3:::"
//            ]
//        }
//    ]
//}
//EOT
//}
//resource "aws_iam_user_policy_attachment" "velero_attachment" {
//  user       = aws_iam_user.velero.name
//  policy_arn = aws_iam_policy.velero_policy.arn
//}
//
//resource "aws_iam_access_key" "velero_access_key" {
//  user = aws_iam_user.velero.name
//}
//output "access_key_id" {
//  value       = aws_iam_access_key.velero_access_key.id
//}
//output "secret_access_key" {
//  sensitive   = true
//  value       = aws_iam_access_key.velero_access_key.secret
//}
