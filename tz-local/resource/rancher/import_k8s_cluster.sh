#!/usr/bin/env bash

########################################################################
# - import a cluster
########################################################################
## from Import Cluster page
## 1. create a cluster
##    Add Cluster > Other Cluster > Cluster Name: jenkins
## 2. import cluster
## https://10.0.0.10/g/clusters/add/launch/import?importProvider=other
## add "--kubeconfig=kube_config_cluster.yml"
su - ubuntu
curl --insecure -sfL https://13.52.140.204/v3/import/7ms892bw5pvjs9drjv4nddvfbkg27hgpfwt7x58pcn8t5cp5bxwb7k.yaml | kubectl apply -f -
or

wget https://13.52.140.204/v3/import/c7s225v4f9mkqnz7jtnqtvwb5m6s9pfr5mbs2lh699rd7hck26kqz2_c-gchfl.yaml --no-check-certificate
#kubectl delete -f c7s225v4f9mkqnz7jtnqtvwb5m6s9pfr5mbs2lh699rd7hck26kqz2_c-gchfl.yaml
kubectl apply -f c7s225v4f9mkqnz7jtnqtvwb5m6s9pfr5mbs2lh699rd7hck26kqz2_c-gchfl.yaml

curl --insecure -sfL https://13.52.140.204/v3/import/c7s225v4f9mkqnz7jtnqtvwb5m6s9pfr5mbs2lh699rd7hck26kqz2_c-gchfl.yaml | kubectl apply -f -

########################################################################
# - set .kube/config
########################################################################
# from https://10.0.0.10/c/c-65zvt/monitoring  # Global > Dashboard: jenkins
# download Kubeconfig File
mkdir -p /home/ubuntu/.kube
# vi /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

echo "" >> /home/ubuntu/.bash_profile
echo "alias ll='ls -al'" >> /home/ubuntu/.bash_profile
echo "alias kk='kubectl --kubeconfig ~/.kube/config'" >> /home/ubuntu/.bash_profile
source /home/ubuntu/.bash_profile





