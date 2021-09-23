#!/usr/bin/env bash

#bash /vagrant/tz-local/resource/mysql/install.sh
cd /vagrant/tz-local/resource/mysql

#set -x
shopt -s expand_aliases
alias k='kubectl --kubeconfig ~/.kube/config'

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
NS=devops-dev

k apply -f storageclass.yaml -n ${NS}

helm repo add stable https://charts.helm.sh/stable
helm repo update
helm uninstall mysql -n ${NS}
helm upgrade --install --reuse-values mysql stable/mysql -n ${NS} -f values.yaml

#k patch deployment/mysql -p '{"spec": {"template": {"spec": {"nodeSelector": {"team": "devops"}}}}}' -n ${NS}
#k patch deployment/mysql -p '{"spec": {"template": {"spec": {"nodeSelector": {"environment": "dev"}}}}}' -n ${NS}
sleep 240

MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace ${NS} mysql -o jsonpath="{.data.mysql-root-password}" | base64 --decode; echo)
echo $MYSQL_ROOT_PASSWORD

#k patch svc mysql -n ${NS} -p '{"spec": {"type": "LoadBalancer"}}'
#kubectl -n ${NS} port-forward svc/mysql 3306

#MYSQL_HOST=localhost
MYSQL_HOST=$(kubectl get svc mysql -n ${NS} | tail -n 1 | awk '{print $4}')
echo ${MYSQL_HOST}
MYSQL_PORT=3306

sudo apt-get update && sudo apt-get install mysql-client -y
mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} --user=root -p${MYSQL_ROOT_PASSWORD} -e "CREATE database test_db;"
mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} --user=root -p${MYSQL_ROOT_PASSWORD} -e "SHOW databases;"
echo mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} --user=root -p${MYSQL_ROOT_PASSWORD} -e "SHOW databases;"
#mysql_config_editor print --all

exit 0

ELB_NM=$(echo $MYSQL_HOST | cut -d "." -f 1 | cut -d "-" -f 1)
echo ${ELB_NM}
SQG=$(aws elb describe-load-balancers --load-balancer-name ${ELB_NM} | grep SecurityGroups -A 1 | tail -n 1 | awk -F\" '{print $2}')
echo ${SQG}
aws ec2 authorize-security-group-ingress --group-id ${SQG} --protocol tcp --port 22 --cidr 43.224.104.241/32
aws ec2 describe-security-groups --group-id ${SQG}

