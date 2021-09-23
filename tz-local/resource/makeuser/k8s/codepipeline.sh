#!/usr/bin/env bash

#https://awskrug.github.io/eks-workshop/codepipeline/configmap/

aws_account_id=$(aws sts get-caller-identity --query Account --output text)

# make a role
TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${aws_account_id}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"
echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" } ] }' > iam-role-policy
aws iam create-role --role-name EksWorkshopCodeBuildKubectlRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'
# make a role-policy
aws iam put-role-policy --role-name EksWorkshopCodeBuildKubectlRole --policy-name eks-describe --policy-document file://iam-role-policy

# patch aws-auth as a build account
ROLE="    - rolearn: arn:aws:iam::${aws_account_id}:role/EksWorkshopCodeBuildKubectlRole\n      username: build\n      groups:\n        - system:masters"
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > aws-auth-patch.yml
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat aws-auth-patch.yml)"

# patch aws-auth as an admin account
ROLE="    - rolearn: arn:aws:iam::${aws_account_id}:role/EksWorkshopCodeBuildKubectlRole\n      username: build\n      groups:\n        - system:masters"
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > aws-auth-patch.yml
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat aws-auth-patch.yml)"

