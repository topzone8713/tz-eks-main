resource "aws_iam_role" "bastion-eks-main-role" {
  name               = "bastion-${local.cluster_name}-role"
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

resource "aws_iam_instance_profile" "bastion-eks-main-role" {
  name = "bastion-${local.cluster_name}-role"
  role = aws_iam_role.bastion-eks-main-role.name
}

resource "aws_iam_role_policy" "admin-policy" {
  name = "bastion-${local.cluster_name}-policy"
  role = aws_iam_role.bastion-eks-main-role.id

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


#########################################
# IAM policy
#########################################
module "iam_policy" {
  source = "../../modules/iam-policy"
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
}
resource "aws_iam_role_policy_attachment" "eks-main-s3full-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = module.eks.cluster_iam_role_name
}

module "es_s3_iam_policy" {
  source = "../../modules/iam-policy"
  name        = "${local.cluster_name}-es-s3-policy"
  path        = "/"
  description = "${local.cluster_name}-es-s3-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::devops-es-${local.cluster_name}",
        "arn:aws:s3:::devops-es-${local.cluster_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks-main-es-s3-policy" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-es-s3-policy"
  role       = var.map_roles[0].username
}

