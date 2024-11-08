#!/usr/bin/env bash

source /root/.bashrc
function prop { key="${2}=" file="/root/.aws/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }
cd /topzone/tz-local/resource/jenkins/helm

#set -x
shopt -s expand_aliases
alias k='kubectl --kubeconfig ~/.kube/config'

eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
AWS_REGION=$(prop 'config' 'region')
aws_account_id=$(aws sts get-caller-identity --query Account --output text)
aws_access_key_id=$(prop 'credentials' 'aws_access_key_id')
aws_secret_access_key=$(prop 'credentials' 'aws_secret_access_key')

helm repo add jenkins https://charts.jenkins.io
helm search repo jenkins

helm list --all-namespaces -a
#k delete namespace jenkins
k create namespace jenkins
k apply -f jenkins.yaml

cp -Rf values.yaml values.yaml_bak
sed -i "s|jenkins_aws_access_key|${aws_access_key_id}|g" values.yaml_bak
sed -i "s|jenkins_aws_secret_key|${aws_secret_access_key}|g" values.yaml_bak
sed -i "s|aws_region|${AWS_REGION}|g" values.yaml_bak
sed -i "s|eks_project|${eks_project}|g" values.yaml_bak
sed -i "s|tz-registrykey|registry-creds|g" values.yaml_bak

#helm delete jenkins -n jenkins
#helm show values jenkins/jenkins > values.yaml
APP_VERSION=4.3.27
#--reuse-values
helm upgrade --reuse-values --debug --install jenkins jenkins/jenkins  -f values.yaml_bak -n jenkins \
  --version ${APP_VERSION}
#k patch svc jenkins --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":31000}]' -n jenkins
#k patch svc jenkins -p '{"spec": {"ports": [{"port": 8080,"targetPort": 8080, "name": "http"}], "type": "ClusterIP"}}' -n jenkins --force

#kubectl cp plugin.txt jenkins/jenkins-0:/tmp/plugin.txt
#kubectl -n jenkins exec -it jenkins-0 /bin/bash
#jenkins-plugin-cli --plugin-file /tmp/plugin.txt --plugins delivery-pipeline-plugin:1.3.2 deployit-plugin

cp -Rf jenkins-ingress.yaml jenkins-ingress.yaml_bak
sed -i "s/eks_project/${eks_project}/g" jenkins-ingress.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" jenkins-ingress.yaml_bak
k apply -f jenkins-ingress.yaml_bak -n jenkins

echo "waiting for starting a jenkins server!"
sleep 60

aws ecr create-repository \
    --repository-name devops-jenkins-${eks_project} \
    --image-tag-mutability IMMUTABLE

aws s3api create-bucket --bucket jenkins-${eks_project} --region ${AWS_REGION} --create-bucket-configuration LocationConstraint=${AWS_REGION}

aws ecr get-login-password --region ${AWS_REGION}
#--profile ${eks_project}
#
#aws ecr get-login-password --region ${AWS_REGION} \
#      | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com

ECR_REGISTRY="${aws_account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com"
mkdir -p /root/.docker
echo "{\"credHelpers\":{\"$ECR_REGISTRY\":\"ecr-login\"}}" > /root/.docker/config2.json
kubectl -n jenkins delete configmap docker-config
kubectl -n jenkins create configmap docker-config --from-file=/root/.docker/config2.json

kubectl -n jenkins delete secret aws-secret
kubectl -n jenkins create secret generic aws-secret \
  --from-file=/root/.aws/credentials

#kubectl cp plugin.txt jenkins/jenkins-0:/tmp/plugin.txt
#kubectl -n jenkins exec -it jenkins-0 /bin/bash
# jenkins-plugin-cli --list
#jenkins-plugin-cli --plugin-file /tmp/plugin.txt --plugins delivery-pipeline-plugin:1.3.2 deployit-plugin

#aws ecr create-repository --repository-name tz-devops-admin --region ${AWS_REGION}
#aws ecr delete-repository --repository-name tz-devops-admin --force --region ${AWS_REGION}

echo "
##[ Jenkins ]##########################################################
#  - URL: http://jenkins.default.${eks_project}.${eks_domain}
#
#  - ID: admin
#  - Password:
#    kubectl -n jenkins exec -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/chart-admin-password && echo
#######################################################################
" >> /topzone/info
cat /topzone/info

sleep 120

exit 0



