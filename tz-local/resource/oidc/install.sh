#!/usr/bin/env bash

#https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
#https://veluxer62.github.io/study/kubernetes-study-05/

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
AWS_REGION=$(prop 'config' 'region')
eks_project=$(prop 'project' 'project')

# IAM OIDC 공급자 생성
tmp=$(aws eks describe-cluster --name ${eks_project} --query "cluster.identity.oidc.issuer" --output text)
tmp=$(aws iam list-open-id-connect-providers | grep ${tmp##*/})
tmp=${tmp##*/}
OIDC_URL=${tmp:0:-1}

eksctl utils associate-iam-oidc-provider --cluster ${eks_project} --approve

# IAM 정책 생성
#aws iam delete-policy --policy-arn "arn:aws:iam::aws_account_id:policy/oidc-policy"
sed -i "s/eks_project/${eks_project}/g" policy.json

tmp=$(aws iam create-policy --policy-name oidc-policy --policy-document file://policy.json)
IAM_POLICY_ARN=$(echo ${tmp} | jq '.Policy.Arn')

# 서비스 계정에 대한 IAM 역할 생성
eksctl delete iamserviceaccount \
    --name tz-oidc-service-account \
    --namespace default \
    --cluster ${eks_project}

eksctl create iamserviceaccount \
    --name tz-oidc-service-account \
    --namespace default \
    --cluster ${eks_project} \
    --attach-policy-arn ${IAM_POLICY_ARN} \
    --approve \
    --override-existing-serviceaccounts

kubectl run -n default awscli -it --rm --image=amazon/aws-cli \
  --serviceaccount='tz-oidc-service-account' --command -- sh

# IAM 역할을 서비스 계정에 연결
kubectl annotate serviceaccount -n default tz-oidc-service-account \
  eks.amazonaws.com/role-arn=arn:aws:iam::aws_account_id:role/${eks_project}-oidc

kubectl delete pods -n kube-system -l k8s-app=aws-node
kubectl get pods -n kube-system -l k8s-app=aws-node

kubectl exec -n kube-system \
  $(kubectl get pods -n kube-system -l k8s-app=aws-node | grep aws-node | head -n 1 | awk '{print $1}') \
  env | grep AWS_ROLE_ARN

