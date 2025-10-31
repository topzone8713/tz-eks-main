#########################################
# IAM ECR policy
#########################################
module "iam_ecr_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  name        = "${local.cluster_name}-ecr-policy"
  path        = "/"
  description = "${local.cluster_name}-ecr-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "eks-main-ecr-policy" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ecr-policy"
  role       = module.eks.cluster_iam_role_name
  depends_on = [module.iam_ecr_policy]
}

#########################################
# cert-manager IRSA (direct IAM resources)
#########################################

data "aws_iam_policy_document" "cert_manager_irsa_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = [
        "system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"
      ]
    }
  }
}

resource "aws_iam_role" "cert_manager_irsa" {
  name               = "cert_manager-${local.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_irsa_trust.json
  tags               = { Role = "cert_manager-${local.cluster_name}-irsa" }
}

resource "aws_iam_role_policy_attachment" "cert_manager_irsa_attach" {
  role       = aws_iam_role.cert_manager_irsa.name
  policy_arn = aws_iam_policy.cert_manager_policy.arn
}

resource "aws_iam_policy" "cert_manager_policy" {
  name        = "${local.cluster_name}-cert-manager-policy"
  path        = "/"
  description = "Policy, which allows CertManager to create Route53 records"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "route53:GetChange",
        "Resource" : "arn:aws:route53:::change/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource": "arn:aws:route53:::hostedzone/*"
      },
      {
        "Effect": "Allow",
        "Action": "route53:ListHostedZonesByName",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks-main-cert_manager_policy" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-cert-manager-policy"
  role       = module.eks.cluster_iam_role_name
  depends_on = [aws_iam_policy.cert_manager_policy]
}


