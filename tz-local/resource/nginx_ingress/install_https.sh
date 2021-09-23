#!/usr/bin/env bash

# http://kimpaper.github.io/2020/05/13/kubernetes-certmanager/

#bash /vagrant/tz-local/resource/nginx_ingress/install_https.sh
cd /vagrant/tz-local/resource/nginx_ingress

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}

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

#set -x
shopt -s expand_aliases
alias k="kubectl -n ${NS} --kubeconfig ~/.kube/config"

bash install.sh ${NS} ${eks_project} ${eks_domain}

k create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

## Install using helm v3+
helm uninstall cert-manager --namespace cert-manager
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=false \
  --version v0.15.2

k get pods --namespace cert-manager
sleep 20

# Install needed CRDs
k apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager.crds.yaml

cp -Rf nginx-ingress-https.yaml nginx-ingress-https.yaml_bak
sed -i "s/NS/${NS}/g" nginx-ingress-https.yaml_bak
sed -i "s/eks_project/${eks_project}/g" nginx-ingress-https.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" nginx-ingress-https.yaml_bak
k delete -f nginx-ingress-https.yaml_bak
k delete ingress nginx-test-tls
#k delete svc nginx
k apply -f nginx-ingress-https.yaml_bak
kubectl get csr -o name | xargs kubectl certificate approve

kubectl get certificate -n ${NS}
kubectl describe certificate nginx-test-tls -n ${NS}

kubectl get secrets --all-namespaces | grep nginx-test-tls
kubectl get certificates --all-namespaces | grep nginx-test-tls

k delete -f nginx-ingress-https.yaml_bak
