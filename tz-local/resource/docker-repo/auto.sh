#!/usr/bin/env bash

# https://github.com/alexellis/registry-creds

kubectl apply -f https://raw.githubusercontent.com/alexellis/registry-creds/master/manifest.yaml

export DOCKER_USERNAME=doohee323
export PW=xxxxx
export EMAIL=doohee323@gmail.com

kubectl create secret docker-registry registry-creds-secret \
  --namespace kube-system \
  --docker-username=$DOCKER_USERNAME \
  --docker-password=$PW \
  --docker-email=$EMAIL

kubectl apply -f clusterPullSecret.yaml

kubectl annotate ns datateam-dev alexellis.io/registry-creds.ignore=1
#kubectl annotate ns datateam-dev alexellis.io/registry-creds.ignore=0 --overwrite