#!/usr/bin/env bash

#https://www.padok.fr/en/blog/efs-provisioner-kubernetes#create
#https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
#https://faun.pub/aws-eks-volumes-architecture-in-a-statefull-app-in-multiple-azs-6ca1b05f80eb
#https://www.44bits.io/ko/post/amazon-efs-on-kubernetes-by-using-efs-provisioner
#https://pseonghoon.github.io/post/k8s-and-nfs/

#bash /vagrant/tz-local/resource/dynamic-provisioning/efs/install.sh
cd /vagrant/tz-local/resource/dynamic-provisioning/efs

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
AWS_REGION=$(prop 'config' 'region')
aws_account_id=$(aws sts get-caller-identity --query Account --output text)

shopt -s expand_aliases
alias k='kubectl --kubeconfig ~/.kube/config'

#[ efs_csi_driver ]###############################################################################################

#aws eks describe-cluster --name ${eks_project} --query "cluster.identity.oidc.issuer" --output text
#aws iam list-open-id-connect-providers | grep FF6110F0C3F3DB3B33053A1485C4599A
#eksctl utils associate-iam-oidc-provider --cluster ${eks_project} --approve

policy_name="efs_provisioner_policy_${eks_project}"
echo "policy_name: ${policy_name}"

NS=$1
if [[ "${NS}" == "" ]]; then
  NS=devops
fi

efs_name="tz-efs-${eks_project}"
echo "efs_name: ${efs_name}"

aws iam create-policy \
    --policy-name ${policy_name} \
    --policy-document file://iam_role_policy_efs.json

eksctl delete iamserviceaccount \
    --cluster ${eks_project} \
    --namespace devops-dev \
    --name efs-provisioner-sa
eksctl create iamserviceaccount \
    --name efs-provisioner-sa \
    --namespace devops-dev \
    --cluster ${eks_project} \
    --region ${AWS_REGION} \
    --attach-policy-arn arn:aws:iam::${aws_account_id}:policy/${policy_name} \
    --override-existing-serviceaccounts \
    --approve
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
#helm uninstall aws-efs-csi-driver --namespace kube-system
helm upgrade --debug --install --reuse-values \
    aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-provisioner-sa \
    --version "2.1.6"

VPC_ID=$(aws eks describe-cluster \
    --name ${eks_project} \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --output text)
echo "VPC_ID: ${VPC_ID}"

cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids ${VPC_ID} \
    --query "Vpcs[].CidrBlock" \
    --output text)
echo "cidr_range: ${cidr_range}"

security_group_id=$(aws ec2 create-security-group \
    --group-name ${efs_name} \
    --description "${efs_name} sg" \
    --vpc-id ${VPC_ID} \
    --output text)

security_group_id=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values=${efs_name} \
    --query "SecurityGroups[*].{ID:GroupId}" \
    --output text)
echo "security_group_id: ${security_group_id}"

aws ec2 authorize-security-group-ingress \
    --group-id ${security_group_id} \
    --protocol tcp \
    --port 2049 \
    --cidr ${cidr_range}

