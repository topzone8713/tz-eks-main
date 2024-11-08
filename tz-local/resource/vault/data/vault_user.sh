#!/usr/bin/env bash

#set -x

source /root/.bashrc
function prop { key="${2}=" file="/root/.aws/${1}" rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); [[ -z "$rslt" ]] && key="${2} = " && rslt=$(grep "${3:-}" "$file" -A 10 | grep "$key" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'); echo "$rslt"; }
#bash /topzone/tz-local/resource/vault/data/vault_user.sh
cd /topzone/tz-local/resource/vault/data

eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
vault_token=$(prop 'project' 'vault')

export VAULT_ADDR=http://vault.default.${eks_project}.${eks_domain}
echo ${VAULT_ADDR}
vault login ${vault_token}

vault secrets enable aws
vault secrets enable consul
vault auth enable kubernetes
vault secrets enable database
vault secrets enable pki
vault secrets enable -version=2 kv
vault secrets enable kv-v2
vault kv enable-versioning secret/
vault secrets enable -path=kv kv
vault secrets enable -path=secret/ kv
vault auth enable userpass

vault kv enable-versioning secret/

userpass_accessor="$(vault auth list | awk '/^userpass/ {print $3}')"
cp userpass.hcl userpass.hcl_bak
sed -i "s/userpass_accessor/${userpass_accessor}/g" userpass.hcl_bak
vault policy write tz-vault-userpass /topzone/tz-local/resource/vault/data/userpass.hcl_bak

PROJECTS=(argocd consul default devops devops-dev monitoring vault)
for item in "${PROJECTS[@]}"; do
  if [[ "${item}" != "NAME" ]]; then
    staging="dev"
    if [[ "${item/*-dev/}" == "" ]]; then
      project=${item/-prod/}
      staging="dev"
    else
      project=${item}-prod
      project_stg=${item}-stg
      staging="prod"
    fi
    echo "=====================staging: ${staging}"
    echo "/topzone/tz-local/resource/vault/data/${project}.hcl"
    if [[ -f /topzone/tz-local/resource/vault/data/${project}.hcl ]]; then
      echo ${item} : ${item/*-dev/}
      echo project: ${project}
      echo role: auth/kubernetes/role/${project}
      echo policy: tz-vault-${project}
      echo svcaccount: ${item}-svcaccount
      vault policy write tz-vault-${project} /topzone/tz-local/resource/vault/data/${project}.hcl
      vault write auth/kubernetes/role/${project} \
              bound_service_account_names=argocd-repo-server,${project}-svcaccount \
              bound_service_account_namespaces=${item} \
              policies=tz-vault-${project} \
              ttl=24h
      if [ "${staging}" == "prod" ]; then
        echo project_stg: ${project_stg}
        echo role_stg: auth/kubernetes/role/${project_stg}
        echo project_stg: tz-vault-${project_stg}
        echo svcaccount_stg: ${project_stg}-svcaccount
        echo vault policy write tz-vault-${project_stg} /topzone/tz-local/resource/vault/data/${project_stg}.hcl
        vault policy write tz-vault-${project_stg} /topzone/tz-local/resource/vault/data/${project_stg}.hcl
        vault write auth/kubernetes/role/${project_stg} \
                bound_service_account_names=argocd-repo-server,${project_stg}-svcaccount \
                bound_service_account_namespaces=${item} \
                policies=tz-vault-${project_stg} \
                ttl=24h
      fi
    fi
  fi
done

# set a secret engine
vault secrets list
vault secrets list -detailed

exit 0
