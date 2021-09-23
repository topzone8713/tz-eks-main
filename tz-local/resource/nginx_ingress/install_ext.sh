#!/usr/bin/env bash

#bash /vagrant/tz-local/resource/nginx_ingress/install_ext.sh

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}

NS=$1
if [[ "${NS}" == "" ]]; then
  NS=devops
fi
eks_domain=$2
if [[ "${eks_domain}" == "" ]]; then
  eks_domain="mydevops.net"
fi
HOSTZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '${eks_domain}.']" | grep '"Id"'  | awk '{print $2}' | sed 's/\"//g;s/,//' | cut -d'/' -f3)
echo $HOSTZONE_ID

#set -x
shopt -s expand_aliases
alias k="kubectl -n ${NS} --kubeconfig ~/.kube/config"

#* https://medium.com/@warolv/building-the-ci-cd-of-the-future-nginx-ingress-cert-manager-945f3dc6b12e

cd /vagrant/tz-local/resource/nginx_ingress

DEVOPS_ELB=$(kubectl get svc | grep nginx-ingress-controller | head -n 1 | awk '{print $4}')
if [[ "${DEVOPS_ELB}" == "" ]]; then
  echo "No elb! check nginx-ingress-controller with LoadBalancer type!"
  exit 1
fi
# Creates route 53 records based on DEVOPS_ELB
CUR_ELB=$(aws route53 list-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} --query "ResourceRecordSets[?Name == '\\052.${eks_domain}.']" | grep 'Value' | awk '{print $2}' | sed 's/"//g')
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
 --change-batch '{ "Comment": "'"${eks_domain}"' utils", "Changes": [{"Action": "DELETE", "ResourceRecordSet": {"Name": "*.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${CUR_ELB}"'"}]}}]}'
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
 --change-batch '{ "Comment": "'"${eks_domain}"' utils", "Changes": [{"Action": "CREATE", "ResourceRecordSet": { "Name": "*.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${DEVOPS_ELB}"'"}]}}]}'

#k delete deployment nginx
#k create deployment nginx --image=nginx
#k expose deployment/nginx --port 80
##k delete svc/nginx
##k port-forward deployment/nginx 80
##k expose deployment/nginx --port 80 --type LoadBalancer

## Save as nginx-ingress.yaml
cp -Rf nginx-ingress_ext.yaml nginx-ingress.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" nginx-ingress.yaml_bak
k delete -f nginx-ingress.yaml_bak
k create -f nginx-ingress.yaml_bak
echo curl http://test.${eks_domain}
curl http://test.${eks_domain}
