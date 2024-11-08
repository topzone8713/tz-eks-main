#!/usr/bin/env bash

source /root/.bashrc
function prop { key="${2}=" file="/root/.aws/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }
cd /topzone/tz-local/resource/ingress_nginx

NS=$1
if [[ "${NS}" == "" ]]; then
  NS=default
fi
eks_project=$2
if [[ "${eks_project}" == "" ]]; then
  eks_project=$(prop 'project' 'project')
fi
eks_domain=$3
if [[ "${eks_domain}" == "" ]]; then
  eks_domain=$(prop 'project' 'domain')
fi
HOSTZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '${eks_domain}.']" | grep '"Id"'  | awk '{print $2}' | sed 's/\"//g;s/,//' | cut -d'/' -f3)
echo $HOSTZONE_ID

#set -x
shopt -s expand_aliases
alias k="kubectl -n ${NS} --kubeconfig ~/.kube/config"

#kubectl delete ns ${NS}
kubectl create ns ${NS}

DEVOPS_ELB=$(kubectl get svc | grep ingress-nginx-controller | grep LoadBalancer | head -n 1 | awk '{print $4}')
if [[ "${DEVOPS_ELB}" == "" ]]; then
  echo "No elb! check nginx-ingress-controller with LoadBalancer type!"
  exit 1
fi
echo "DEVOPS_ELB: $DEVOPS_ELB"
# Creates route 53 records based on DEVOPS_ELB
CUR_ELB=$(aws route53 list-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} --query "ResourceRecordSets[?Name == '\\052.${NS}.${eks_project}.${eks_domain}.']" | grep 'Value' | awk '{print $2}' | sed 's/"//g')
echo "${NS}.${eks_project}.${eks_domain} CUR_ELB: $CUR_ELB"
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
 --change-batch '{ "Comment": "'"${eks_project}"' utils", "Changes": [{"Action": "DELETE", "ResourceRecordSet": {"Name": "*.'"${NS}"'.'"${eks_project}"'.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${CUR_ELB}"'"}]}}]}'
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
 --change-batch '{ "Comment": "'"${eks_project}"' utils", "Changes": [{"Action": "CREATE", "ResourceRecordSet": { "Name": "*.'"${NS}"'.'"${eks_project}"'.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${DEVOPS_ELB}"'"}]}}]}'

kubectl apply -f ingress-nginx-configmap.yaml -n ${NS}

cp -Rf nginx-ingress.yaml nginx-ingress.yaml_bak
sed -i "s|NS|${NS}|g" nginx-ingress.yaml_bak
sed -i "s/eks_project/${eks_project}/g" nginx-ingress.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" nginx-ingress.yaml_bak
k delete -f nginx-ingress.yaml_bak -n ${NS}
k delete ingress $(k get ingress nginx-test-tls -n ${NS}) -n ${NS}
k delete svc nginx -n ${NS}
k apply -f nginx-ingress.yaml_bak -n ${NS}
sleep 10
curl -v http://test.${NS}.${eks_project}.${eks_domain}
echo curl http://test.${NS}.${eks_project}.${eks_domain}
k delete -f nginx-ingress.yaml_bak

#### https ####
cp -Rf nginx-ingress-https.yaml nginx-ingress-https.yaml_bak
sed -i "s/NS/${NS}/g" nginx-ingress-https.yaml_bak
sed -i "s/eks_project/${eks_project}/g" nginx-ingress-https.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" nginx-ingress-https.yaml_bak
k delete -f nginx-ingress-https.yaml_bak -n ${NS}
k delete ingress nginx-test-tls -n ${NS}
k apply -f nginx-ingress-https.yaml_bak -n ${NS}
kubectl get csr -o name | xargs kubectl certificate approve
sleep 10
curl -v http://test.${NS}.${eks_project}.${eks_domain}
curl -v https://test.${NS}.${eks_project}.${eks_domain}

exit 0
