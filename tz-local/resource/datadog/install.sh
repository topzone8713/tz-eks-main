#!/usr/bin/env bash

# https://docs.datadoghq.com/agent/kubernetes/?tab=helm
#https://github.com/JungYoungseok/K8S_Webinar_202006/blob/master/datadog-agent-all-enabled.yaml

#bash /vagrant/tz-local/resource/datadog/install.sh
cd /vagrant/tz-local/resource/datadog

#set -x
shopt -s expand_aliases

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
basic_password=$(prop 'project' 'basic_password')
datadog_apikey=$(prop 'project' 'datadog_apikey')

helm repo add datadog https://helm.datadoghq.com
helm repo update

#https://github.com/DataDog/helm-charts/blob/main/charts/datadog/values.yaml
cp values.yaml values.yaml_bak
sed -i "s/datadog_apikey/${datadog_apikey}/g" values.yaml_bak
sed -i "s/eks_project/${eks_project}/g" values.yaml_bak
#helm uninstall datadog-${eks_project} -n devops
helm upgrade --debug --install --reuse-values datadog-${eks_project} -f values.yaml_bak datadog/datadog -n devops

