#!/usr/bin/env bash

#set -x

## https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/add-user-role.html
#bash /vagrant/tz-local/resource/makeuser/eks/eks-users.sh

cd /vagrant/tz-local/resource/makeuser/eks

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')

aws_account_id=$(aws sts get-caller-identity --query Account --output text)

export AWS_DEFAULT_PROFILE="default"
aws sts get-caller-identity
kubectl -n kube-system get configmap aws-auth -o yaml
kubectl get node

kubectl create ns devops
kubectl create ns devops-dev

eks_role=$(aws iam list-roles --out=text | grep "${eks_project}2" | grep "0000000" | tail -n 1 | awk '{print $7}')
echo eks_role: ${eks_role}
aws iam create-policy --policy-name ${eks_project}-ecr-policy --policy-document file://eks-policy.json
aws iam update-assume-role-policy --role-name ${eks_role} --policy-document file://eks-role.json
aws iam attach-role-policy --policy-arn arn:aws:iam::487604454824:policy/${eks_project}-ecr-policy --role-name ${eks_role}

ec2_role=$(aws iam list-roles --out=text | grep "${eks_project}2" | grep "000000" | tail -n 1 | awk '{print $7}')
echo ec2_role: ${ec2_role}
cp eks-roles-configmap.yaml eks-roles-configmap.yaml_bak
sed -i "s/aws_account_id/${aws_account_id}/g" eks-roles-configmap.yaml_bak
sed -i "s/ec2_role/${ec2_role}/g" eks-roles-configmap.yaml_bak
sed -i "s/eks_role/${eks_role}/g" eks-roles-configmap.yaml_bak
kubectl apply -f eks-roles-configmap.yaml_bak

# add a eks-users
#kubectl delete -f eks-roles.yaml
#kubectl delete -f eks-rolebindings.yaml
#cp eks-roles-configmap.yaml eks-roles-configmap.yaml_bak
#sed -i "s/aws_account_id/${aws_account_id}/g" eks-roles-configmap.yaml_bak
#sed -i "s/eks_project/${eks_project}/g" eks-roles-configmap.yaml_bak
#kubectl delete -f eks-roles-configmap.yaml_bak
#kubectl delete -f eks-console-full-access.yaml
#kubectl delete -f eks-console-restricted-access.yaml

#cp eks-roles-configmap-min.yaml eks-roles-configmap-min.yaml_bak
#sed -i "s/eks_project/${eks_project}/g" eks-roles-configmap-min.yaml_bak
#kubectl delete -f eks-roles-configmap-min.yaml_bak
#kubectl apply -f eks-roles-configmap-min.yaml_bak

#kubectl apply -f eks-roles.yaml
#kubectl apply -f eks-rolebindings.yaml
#kubectl apply -f eks-roles-configmap.yaml_bak
#kubectl apply -f eks-console-full-access.yaml

exit 0

vault secrets enable aws
vault secrets enable consul
vault auth enable kubernetes
vault secrets enable database
vault secrets enable pki
vault secrets enable -version=2 kv
vault secrets enable -path=kv kv
vault secrets enable -path=secret/ kv
vault auth enable userpass

aws configure --profile devops
export AWS_DEFAULT_PROFILE="devops"
aws sts get-caller-identity

kubectl get node
kubectl get pods -n devops
kubectl get all -n devops

kubectl config set-context devops-dev --user=doogee.hong --namespace=devops-dev
kubectl config use-context devops-dev

exit 0
