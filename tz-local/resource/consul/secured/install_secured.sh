#!/usr/bin/env bash

# https://learn.hashicorp.com/tutorials/consul/kubernetes-secure-agents
# https://learn.hashicorp.com/tutorials/consul/access-control-setup-production#create-the-initial-bootstrap-token

######
#https://www.linkedin.com/pulse/using-consul-auto-encrypt-k8s-issac-goldstand/
#https://githubmemory.com/repo/hashicorp/consul-helm/issues

#set -x
shopt -s expand_aliases
alias k='kubectl'

cd /vagrant/tz-local/resource/consul/secured

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')

# install for test on host
wget https://releases.hashicorp.com/consul/1.8.4/consul_1.8.4_linux_amd64.zip
sudo apt-get install -y unzip jq
unzip consul_1.8.4_linux_amd64.zip
rm -Rf consul_1.8.4_linux_amd64.zip
sudo mv consul /usr/local/bin/

helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/consul

##################################################
# Install an unsecured Consul service
##################################################
cat > dc1.yaml <<EOF
global:
  name: consul
  enabled: true
  datacenter: dc1

server:
  replicas: 1
  bootstrapExpect: 1
  storage: 1Gi

connectInject:
  enabled: true
controller:
  enabled: true
EOF

helm install -f ./dc1.yaml consul hashicorp/consul --version "0.23.1"
#helm uninstall consul
#k exec -it consul-server-0 -- /bin/sh
#k patch svc consul-ui --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":31699}]'
cp -Rf ../consul-ingress.yaml ../consul-ingress.yaml_bak
sed -i "s/eks_project/${eks_project}/g" ../consul-ingress.yaml_bak
k apply -f ../consul-ingress.yaml_bak

#kubectl exec -it pod/consul-server-0 -- /bin/sh
#apk update && apk add bind-tools && apk add tcpdump
#tcpdump -an portrange 8300-8700 -A

##################################################
# Upgrade an unsecured Consul service
##################################################
# https://www.consul.io/docs/k8s/helm
consul tls ca create
consul tls cert create -server

k delete secret consul-gossip-encryption-key
k delete secret consul-ca-key
k delete secret consul-ca-cert

k create secret generic consul-gossip-encryption-key --from-literal=key=$(consul keygen)
k create secret generic consul-ca-cert \
    --from-file='tls.crt=./consul-agent-ca.pem'
k create secret generic consul-ca-key \
    --from-file='tls.key=./consul-agent-ca-key.pem'

k get secret consul-gossip-encryption-key
k get secret consul-ca-cert
k get secret consul-ca-key

openssl req -new -newkey rsa:2048 -nodes -keyout server1.dc1.consul.key -out server1.dc1.consul.csr -subj '/CN=server1.dc1.consul' -config <(
cat <<-EOF
[req]
req_extensions = req_ext
distinguished_name = dn
[ dn ]
CN = *.dc1.consul
[ req_ext ]
basicConstraints=CA:FALSE
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = server1.dc1.consul
DNS.2 = localhost
IP.1  = 127.0.0.1
EOF
)
#ls -al server1.dc1.consul*

#Step 2: sign the CSR
openssl x509 -req -in server1.dc1.consul.csr -CA consul-agent-ca.pem -CAkey consul-agent-ca-key.pem -CAcreateserial -out server1.dc1.consul.crt
openssl x509 -text -noout -in server1.dc1.consul.crt

#Create a certificate for clients:
consul tls cert create -client
#Create clients certificate
#Create the CSR:
openssl req -new -newkey rsa:2048 -nodes -keyout client.dc1.consul.key -out client.dc1.consul.csr -subj '/CN=client.dc1.consul' -config <(
cat <<-EOF
[req]
req_extensions = req_ext
distinguished_name = dn
[ dn ]
CN = *.dc1.consul
[ req_ext ]
basicConstraints=CA:FALSE
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = server1.dc1.consul
DNS.2 = localhost
IP.1  = 127.0.0.1
EOF
)
#Sign the certificate:
openssl x509 -req -in client.dc1.consul.csr -CA consul-agent-ca.pem -CAkey consul-agent-ca-key.pem -out client.dc1.consul.crt

cat > secure-dc1.yaml <<EOF
global:
  name: consul
  enabled: true
  datacenter: dc1

  gossipEncryption:
    secretName: "consul-gossip-encryption-key"
    secretKey: "key"

  tls:
    enabled: true
    enableAutoEncrypt: true
    verify: true
    serverAdditionalDNSSANs:
    - "server1.dc1.consul"
    caCert:
      secretName: "consul-ca-cert"
      secretKey: "tls.crt"
    caKey:
      secretName: "consul-ca-key"
      secretKey: "tls.key"

  acls:
    manageSystemACLs: true

server:
#  enabled: true
  replicas: 3
  bootstrapExpect: 1
  storage: 1Gi
  storageClass: "gp2"
  connect: true

client:
  enabled: true
  grpc: true
  exposeGossipPorts: true

ui:
  enabled: true
#  service:
#    enabled: true

connectInject:
  enabled: true
controller:
  enabled: true

#dns:
#  enabled: false
EOF

#helm rollback
#helm rollback && helm upgrade
#helm history consul
#pending-install
#helm upgrade -f ./secure-dc1.yaml consul hashicorp/consul --wait
helm uninstall consul
helm install -f ./secure-dc1.yaml consul hashicorp/consul --version "0.23.1"
#helm upgrade --install consul hashicorp/consul --set global.name=consul --set server.affinity=""

#kubectl port-forward consul-server-0 8501:8501
# to NodePort
#k patch svc consul-ui --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":31699}]'

#Create a certificate for cli:
consul tls cert create -cli

#Step 1: create server certificate signing requests
#openssl req -new -newkey rsa:2048 -nodes -keyout cli.client.dc1.consul.key -out cli.client.dc1.consul.csr -subj '/CN=cli.client.dc1.consul'
openssl req -new -newkey rsa:2048 -nodes -keyout cli.client.dc1.consul.key -out cli.client.dc1.consul.csr -subj '/CN=cli.client.dc1.consul' -config <(
cat <<-EOF
[req]
req_extensions = req_ext
distinguished_name = dn
[ dn ]
CN = *.dc1.consul
[ req_ext ]
basicConstraints=CA:FALSE
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = server1.dc1.consul
DNS.2 = localhost
IP.1  = 127.0.0.1
EOF
)
#ls -al cli.client.dc1.consul*
#Step 2: sign the CSR
openssl x509 -req -in cli.client.dc1.consul.csr -CA consul-agent-ca.pem -CAkey consul-agent-ca-key.pem -CAcreateserial -out cli.client.dc1.consul.crt
openssl x509 -text -noout -in cli.client.dc1.consul.crt
#Sign the certificate:
openssl x509 -req -in cli.client.dc1.consul.csr -CA consul-agent-ca.pem -CAkey consul-agent-ca-key.pem -out cli.client.dc1.consul.crt


export CONSUL_HTTP_ADDR=https://server1.dc1.consul:8501
k get secret consul-ca-cert -o jsonpath="{.data['tls\.crt']}" | base64 --decode > ca.pem
consul members -ca-file ca.pem
#consul members -http-addr="https://localhost:8501"

consul members -ca-file=consul-agent-ca.pem -client-cert=dc1-cli-consul-0.pem \
  -client-key=dc1-cli-consul-0-key.pem -http-addr="https://server1.dc1.consul:8501"

consul members -http-addr="https://server1.dc1.consul:8501"

#Configure the Consul CLI for HTTPS
export CONSUL_HTTP_ADDR=https://localhost:8501
export CONSUL_CACERT=consul-agent-ca.pem
export CONSUL_CLIENT_CERT=cli.client.dc1.consul.crt
export CONSUL_CLIENT_KEY=cli.client.dc1.consul.key
consul members

consul members \
    -http-addr="https://server1.dc1.consul:8501" \
    -ca-file="consul-agent-ca.pem" \
    -client-cert="cli.client.dc1.consul.crt" \
    -client-key="cli.client.dc1.consul.key"




