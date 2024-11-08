#!/usr/bin/env bash

source /root/.bashrc
function prop { key="${2}=" file="/root/.aws/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }
#bash /topzone/tz-local/resource/monitoring/backup.sh
cd /topzone/tz-local/resource/monitoring

eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')

# curl -X POST -H "Content-Type: application/json" -d '{"name":"admin-key", "role": "Admin"}' https://admin:${admin_password}@grafana.default.${eks_project}.${eks_domain}/api/auth/keys

#set -x
shopt -s expand_aliases

git clone https://github.com/ysde/grafana-backup-tool
cp -Rf grafanaSettings.json grafana-backup-tool/grafana_backup/conf

cd grafana-backup-tool
pip install --user virtualenv
export PATH=$PATH:/home/topzone/.local/bin
virtualenv --python=python3.8 .venv
source .venv/bin/activate
pip install .
pip install grafana-backup

grafana-backup --config grafana_backup/conf/grafanaSettings.json save
#grafana-backup restore _OUTPUT_/202106150409.tar.gz
grafana-backup  --config grafana_backup/conf/grafanaSettings.json restore 202106150439.tar.gz


