#!/usr/bin/env bash

# https://learn.hashicorp.com/tutorials/consul/service-mesh-deploy?in=consul/gs-consul-service-mesh
#https://www.youtube.com/watch?v=_jTnlXgYUyg

#bash /vagrant/tz-local/resource/consul/mesh/install.sh
cd /vagrant/tz-local/resource/consul/mesh

#set -x
shopt -s expand_aliases
alias k='kubectl'

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
basic_password=$(prop 'project' 'basic_password')

helm search repo hashicorp/consul
helm repo update

pushd `pwd`
cd /vagrant/tz-local/resource/consul
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
kubectl -n consul create secret generic consul-gossip-encryption-key --from-literal=key=$(consul keygen)
#cp values2.yaml values2.yaml_bak
#helm upgrade --debug --install --reuse-values consul hashicorp/consul -f /vagrant/tz-local/resource/consul/values2.yaml_bak -n consul --version 0.32.1
popd

kubectl -n consul exec consul-server-0 -- consul config read -name tz-consul-service -kind service-defaults
kubectl -n consul get ServiceDefaults tz-consul-service -o yaml
kubectl -n consul describe servicedefaults tz-consul-service

kubectl -n consul get pods --selector app=consul
kubectl -n consul exec -it consul-server-0 -- consul members
kubectl -n consul get pods --selector consul.hashicorp.com/connect-inject-status=injected

kubectl -n consul delete -f hashicups
kubectl -n consul apply -f hashicups
#kubectl -n consul apply -f hashicups/public-api.yaml
#kubectl -n delete apply -f hashicups/public-api.yaml

kubectl -n consul port-forward svc/public-api 8080:8080
kubectl -n consul port-forward svc/frontend 8081:80
kubectl -n consul port-forward svc/product-api 9090:9090
#  http://localhost:9090/coffees
kubectl -n consul apply -f service-to-service.yaml

kubectl -n consul apply -f deploy-service/service.yaml
kubectl -n consul apply -f deploy-service/v1
kubectl -n consul apply -f deploy-service/service-router.yaml
kubectl -n consul port-forward svc/product-api-new 9090:9090
#  http://localhost:9090/coffees
kubectl -n consul apply -f deploy-service/v2
kubectl -n consul port-forward svc/product-api-new 9091:9090
#  http://localhost:9090/coffees

kubectl -n consul apply -f deploy-service/service-resolver.yaml
kubectl -n consul apply -f deploy-service/service-splitter.yaml

exit 0

kubectl run -it busybox --image=alpine:3.6 -n consul --overrides='{ "spec": { "nodeSelector": { "team": "devops", "environment": "consul" } } }' -- sh
kubectl -n consul exec -it busybox -- sh


kubectl port-forward --address 0.0.0.0 consul-server-0 8501:8501
export CONSUL_HTTP_ADDR=https://127.0.0.1:8501
kubectl -n consul get secret consul-ca-cert -o jsonpath="{.data['tls\.crt']}" | base64 --decode > ca.pem
consul members -ca-file ca.pem
