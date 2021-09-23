#!/usr/bin/env bash

########################################################################
# - apply jenkins deployment and service
########################################################################
cp /vagrant/shared/jenkins_deployment.yaml .
cp /vagrant/shared/jenkins_service.yaml .

kubectl --kubeconfig ~/.kube/config apply -f jenkins_deployment.yaml
kubectl --kubeconfig ~/.kube/config apply -f jenkins_service.yaml

########################################################################
# - get jenkins url
########################################################################
# in Workloads
# => http://10.0.0.11:31756/

########################################################################
# - install jenkins plugins
########################################################################
# http://10.0.0.11:31756/pluginManager/available
# install kubernetes

########################################################################
# - make a secret key
########################################################################
https://10.0.0.10/apikeys
Add key >
Access Key (username):  token-w5q54
Secret Key (password):: 42plh4bw97grt7xkj96qrjhd5ckqmjfdz66v77x6tt5jrlmwlw6kvg

########################################################################
# - setting kubernetes plugin
########################################################################
# http://10.0.0.11:31756/configureClouds/
# kubectl cluster-info
# Kubernetes Url: https://10.0.0.10
# Disable https certificate check: check
# Kubernetes Namespace: default
# Credentials: token-w5q54 / 42plh4bw97grt7xkj96qrjhd5ckqmjfdz66v77x6tt5jrlmwlw6kvg
# kubectl describe services/jenkins | grep IP
# IP:                       10.43.234.135
# Jenkins URL: http://10.43.234.135

# Pod Templates: slave1
#     Containers: slave1
#     Docker image: doohee323/jenkins-slave

########################################################################
# - make a job
########################################################################
# job name: slave1
# build > execute shell: echo "i am slave1"; sleep 60




