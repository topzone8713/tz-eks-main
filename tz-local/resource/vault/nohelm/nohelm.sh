#!/usr/bin/env bash

# https://blog.medinvention.dev/vault-consul-kubernetes-deployment/
# https://github.com/mmohamed/vault-kubernetes
# https://luniverse.io/vault-service-1/?lang=ko

##1- build cfssl
wget https://dl.google.com/go/go1.16.2.linux-amd64.tar.gz
tar xvfz go1.16.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.16.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

sudo apt-get update
sudo apt install build-essential -y
git clone https://github.com/cloudflare/cfssl.git
cd cfssl
make

sudo cp bin/cfssl /usr/sbin
sudo cp bin/cfssljson /usr/sbin

#2- Consul deployment :

# install for test on host
mkdir sample && cd sample
wget https://releases.hashicorp.com/consul/1.8.4/consul_1.8.4_linux_amd64.zip
sudo apt-get install -y unzip jq
unzip consul_1.8.4_linux_amd64.zip
sudo mv consul /usr/local/bin/
cd ..
rm -Rf sample

# Generate CA and sign request for Consul
cd /vagrant/tz-local/resource/vault/nohelm

cfssl gencert -initca consul/ca/ca-csr.json | cfssljson -bare ca
# Generate SSL certificates for Consul
cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=consul/ca/ca-config.json \
-profile=default \
consul/ca/consul-csr.json | cfssljson -bare consul
# Perpare a GOSSIP key for Consul members communication encryptation
GOSSIP_ENCRYPTION_KEY=$(consul keygen)

#2. Create secret with Gossip key and public/private keys
k create namespace vault
k delete secret consul
k -n vault create secret generic consul \
--from-literal=key="${GOSSIP_ENCRYPTION_KEY}" \
--from-file=ca.pem \
--from-file=consul.pem \
--from-file=consul-key.pem
k get secret consul -n vault

#3. Deploy 3 Consul members (Statefulset)
kubectl delete -f consul/service.yaml
kubectl delete -f consul/rbac.yaml
kubectl delete -f consul/config.yaml
kubectl delete -f consul/consul.yaml

kubectl apply -f consul/service.yaml
kubectl apply -f consul/rbac.yaml
kubectl apply -f consul/config.yaml
kubectl apply -f consul/consul.yaml

#4. Prepare SSL certificates for Consul client, it will be used by vault consul client (sidecar).
cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=consul/ca/ca-config.json \
-profile=default \
consul/ca/consul-csr.json | cfssljson -bare client-vault

#5. Create secret for Consul client (like members)
k -n vault create secret generic client-vault \
--from-literal=key="${GOSSIP_ENCRYPTION_KEY}" \
--from-file=ca.pem \
--from-file=client-vault.pem \
--from-file=client-vault-key.pem

#3- Vault deployment :
kubectl apply -f vault/service.yaml
kubectl apply -f vault/config.yaml
kubectl apply -f vault/vault.yaml

#5- UI:
kubectl apply -f ingress.yaml
#k -n vault patch svc consul-ui --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":31699}]'
#k -n vault patch svc vault-ui --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":31700}]'

#6- Vault Injector deployment
kubectl apply -f vault-injector/service.yaml
kubectl apply -f vault-injector/rbac.yaml
kubectl apply -f vault-injector/deployment.yaml
kubectl apply -f vault-injector/webhook.yaml # webhook must be created after deployment


