##################################################################
# EKS k8sDev Role
##################################################################
resource "aws_iam_group" "k8sDev" {
  name = "${local.cluster_name}-k8sDev"
  path = "/users/"
}
resource "aws_iam_group_policy" "k8sDev_policy" {
  name  = "${local.cluster_name}-k8sDev"
  group = aws_iam_group.k8sDev.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Full",
      "Action": [
            "s3:ListAllMyBuckets",
			"s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
			"arn:aws:s3:::*"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_policy" "k8sDev" {
  name        = "${local.cluster_name}-k8sDev"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "${aws_iam_role.k8sDev.arn}"
    }]
  })
}

// https://s3.console.aws.amazon.com/s3/buckets/hypen-eks-main-t-repo?region=ap-northeast-2&tab=objects
resource "aws_iam_role" "k8sDev" {
  name     = "${local.cluster_name}-k8sDev"
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
resource "aws_iam_user_policy_attachment" "k8sDev" {
  user       = aws_iam_user.k8sDev.name
  policy_arn = aws_iam_policy.k8sDev.arn
}
resource "aws_iam_group_membership" "k8sDev" {
  name = "${local.cluster_name}-k8sDev"
  users = [
    "${local.cluster_name}-k8sDev",
    aws_iam_user.devops.name,
  ]
  group = aws_iam_group.k8sDev.name
}

resource "aws_iam_group_policy" "k8sDev_common_policy" {
  name  = "${local.cluster_name}-common_k8sDev"
  group = aws_iam_group.k8sDev.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeRole",
			"Action": [
				"sts:AssumeRole"
			],
			"Effect": "Allow",
			"Resource": "${aws_iam_group.k8sDev.arn}"
		},
    {
			"Sid": "ListUsersForConsole",
			"Effect": "Allow",
			"Action": "iam:ListUsers",
			"Resource": "arn:aws:iam::*:*"
		},
		{
			"Sid": "ViewAndUpdateAccessKeys",
			"Effect": "Allow",
			"Action": [
				"iam:UpdateAccessKey",
				"iam:CreateAccessKey",
				"iam:ListAccessKeys"
			],
			"Resource": "arn:aws:iam::*:user/&{aws:username}"
		},
    {
			"Sid": "S3List",
			"Effect": "Allow",
			"Action": [
				"s3:ListAllMyBuckets"
			],
			"Resource": "arn:aws:s3:::*"
		},
		{
			"Sid": "CloudfrontReadOnly1",
			"Effect": "Allow",
			"Action": [
				"acm:ListCertificates",
				"cloudfront:GetDistribution",
				"cloudfront:GetDistributionConfig",
				"cloudfront:ListDistributions",
				"cloudfront:ListCloudFrontOriginAccessIdentities",
				"elasticloadbalancing:DescribeLoadBalancers",
				"iam:ListServerCertificates",
				"sns:ListSubscriptionsByTopic",
				"sns:ListTopics",
				"waf:GetWebACL",
				"waf:ListWebACLs"
			],
			"Resource": "*"
		},
		{
			"Sid": "Route53ReadOnly",
			"Effect": "Allow",
			"Action": [
				"route53domains:Get*",
				"route53domains:List*",
				"route53domains:*",
				"route53:GetHostedZoneCount",
				"route53:ListHostedZonesByName",
				"route53:GetHostedZone",
				"route53:ListResourceRecordSets"
			],
			"Resource": "*"
		},
		{
			"Sid": "LambdaReadOnly",
			"Effect": "Allow",
			"Action": [
				"lambda:*"
			],
			"Resource": "*"
		},
		{
			"Sid": "CloudwatchReadOnly",
			"Effect": "Allow",
			"Action": [
				"cloudwatch:*"
			],
			"Resource": "*"
		},
		{
			"Sid": "CloudformationReadOnly",
			"Effect": "Allow",
			"Action": [
				"cloudformation:ListExports",
				"cloudformation:DescribeChangeSetHooks",
				"cloudformation:ListTypeRegistrations",
				"cloudformation:DescribeStackEvents",
				"cloudformation:BatchDescribeTypeConfigurations",
				"cloudformation:DescribeChangeSet",
				"cloudformation:ListStackResources",
				"cloudformation:ListGeneratedTemplates",
				"cloudformation:GetGeneratedTemplate",
				"cloudformation:ListStackInstanceResourceDrifts",
				"cloudformation:GetStackPolicy",
				"cloudformation:ValidateTemplate",
				"cloudformation:DetectStackSetDrift",
				"cloudformation:DescribeOrganizationsAccess",
				"cloudformation:ListResourceScanResources",
				"cloudformation:EstimateTemplateCost",
				"cloudformation:DescribeStackSetOperation",
				"cloudformation:DescribeType",
				"cloudformation:ListImports",
				"cloudformation:DescribeTypeRegistration",
				"cloudformation:ListResourceScanRelatedResources",
				"cloudformation:ListStackInstances",
				"cloudformation:DescribeStackResource",
				"cloudformation:ListStackSetOperationResults",
				"cloudformation:ListStackSetAutoDeploymentTargets"
			],
			"Resource": "*"
		}
  ]
}
EOF
}
