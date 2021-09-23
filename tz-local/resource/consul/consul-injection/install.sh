#!/usr/bin/env bash

#bash /vagrant/tz-local/resource/consul/consul-injection/install.sh
cd /vagrant/tz-local/resource/consul/consul-injection

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')

kubectl delete -f consul-demo.yaml -n consul --grace-period=0 --force
kubectl apply -f consul-demo.yaml -n consul

vault policy write tz-consul-devops-dev /vagrant/tz-local/resource/vault/data/devops-dev.hcl
vault write auth/kubernetes/role/consul-agent-demo2-role \
        bound_service_account_names=consul-agent-demo2-account \
        bound_service_account_namespaces=consul \
        policies=tz-vault-devops-dev \
        ttl=24h

kubectl delete -f consul-demo2.yaml -n consul --grace-period=0 --force
kubectl apply -f consul-demo2.yaml -n consul

