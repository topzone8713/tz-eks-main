#!/usr/bin/env bash

#https://phoenixnap.com/kb/elasticsearch-helm-chart
#https://www.elastic.co/guide/en/elasticsearch/reference/7.1/configuring-tls-docker.html

#bash /vagrant/tz-local/resource/elk/install.sh
cd /vagrant/tz-local/resource/elk/csv-read

shopt -s expand_aliases

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')
NS=es

kubectl -n devops-dev exec -it bastion -- sh

apt-get update && apt install curl -y
export STACK_VERSION=7.13.2
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${STACK_VERSION}-amd64.deb
dpkg -i filebeat-${STACK_VERSION}-amd64.deb

filebeat modules list
#filebeat modules enable system nginx mysql logstash
#filebeat modules disable system nginx mysql logstash
filebeat setup -e
cd /etc/filebeat/modules.d
filebeat test config -e

#mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml_bak

# apply processor
# make a template
/vagrant/tz-local/resource/elk/csv-read/es.yml

kubectl cp filebeat.yml devops-dev/bastion:/etc/filebeat
kubectl -n devops-dev exec -it bastion -- chown root:root /etc/filebeat/filebeat.yml
kubectl -n devops-dev exec -it bastion -- rm /var/lib/filebeat/filebeat.lock

kubectl -n devops-dev exec -it bastion -- filebeat run -e -d "*"
#filebeat run -e
#rm -Rf /var/lib/filebeat/registry

kubectl cp 9.zip devops-dev/bastion:/data/csv
kubectl -n devops-dev exec -it bastion -- chown -Rf root:root /data/csv

kubectl -n devops-dev cp /vagrant/terraform-aws-eks/resource/9.zip devops-dev/bastion:/data
kubectl -n devops-dev exec -it bastion -- tar xvfz /data/9.zip -C /data/csv


