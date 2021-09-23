#!/usr/bin/env bash

shopt -s expand_aliases

# apply.sh 9
tar cvfz $1.zip $1.csv

kubectl -n devops-dev cp $1.zip devops-dev/bastion:/data
kubectl -n devops-dev exec -it bastion -- tar xvfz /data/$1.zip -C /data/csv
kubectl -n devops-dev exec -it bastion -- rm /var/lib/filebeat/filebeat.lock
kubectl -n devops-dev exec -it bastion -- filebeat run -e -d "*"

#kubectl -n devops-dev exec -it bastion -- sh

