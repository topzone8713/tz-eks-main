#!/usr/bin/env bash

#set -x
source /root/.bashrc
function prop { key="${2}=" file="/root/.aws/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }
#bash /topzone/tz-local/resource/vault/vault-injection/update.sh
cd /topzone/tz-local/resource/vault/vault-injection

eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
VAULT_TOKEN=$(prop 'project' 'vault')
AWS_REGION=$(prop 'config' 'region')

export VAULT_ADDR="http://vault.default.${eks_project}.${eks_domain}"
vault login ${VAULT_TOKEN}

vault list auth/kubernetes/role

#bash /topzone/tz-local/resource/vault/vault-injection/cert.sh default
kubectl get csr -o name | xargs kubectl certificate approve

PROJECTS=(argocd consul default devops devops-dev monitoring vault)
for item in "${PROJECTS[@]}"; do
  echo "====================="
  echo ${item}
  accounts="default"
  namespaces="default"
  staging="dev"
  if [[ "${item/*-dev/}" == "" ]]; then
    project=${item/-prod/}
    accounts=${accounts},${item}-svcaccount
    namespaces=${namespaces},${item}  # devops-dev
    echo "===================dev==${project} / ${namespaces}"
  else
    project=${item}-prod
    project_stg=${item}-stg
    accounts=${accounts},${item}-dev-svcaccount,${item}-stg-svcaccount,${item}-svcaccount # devops-dev devops-prod
    namespaces=${namespaces},${item/-prod/}-dev,${item/-prod/}  # devops-dev devops
    staging="prod"
  fi
  echo "===================${staging}==${project} / ${namespaces}"
#  for value in "${accounts[@]}"; do
#     echo $value
#  done
#  for value in "${namespaces[@]}"; do
#     echo $value
#  done
  if [[ -f /topzone/tz-local/resource/vault/data/${project}.hcl ]]; then
    echo ${item} : ${item/*-dev/}
    echo project: ${project}
    vault write auth/kubernetes/role/${project} \
            bound_service_account_names=${accounts} \
            bound_service_account_namespaces=${namespaces} \
            policies=tz-vault-${project} \
            ttl=24h
    vault policy write tz-vault-${project} /topzone/tz-local/resource/vault/data/${project}.hcl
    vault kv put secret/${project}/dbinfo name='localhost' passwod=1111 ttl='30s'
    vault kv put secret/${project}/foo name='localhost' passwod=1111 ttl='30s'
    vault read auth/kubernetes/role/${project}
    if [ "${staging}" == "prod" ]; then
      vault write auth/kubernetes/role/${project_stg} \
              bound_service_account_names=${accounts} \
              bound_service_account_namespaces=${namespaces} \
              policies=tz-vault-${project_stg} \
              ttl=24h
      vault policy write tz-vault-${project_stg} /topzone/tz-local/resource/vault/data/${project_stg}.hcl
      vault kv put secret/${project_stg}/dbinfo name='localhost' passwod=1111 ttl='30s'
      vault kv put secret/${project_stg}/foo name='localhost' passwod=1111 ttl='30s'
      vault read auth/kubernetes/role/${project_stg}
    fi
  fi
done

exit 0
