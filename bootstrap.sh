#!/usr/bin/env bash

set -euo pipefail

# Optional: export docker_user="topzone8713"
# Usage:
#   bash bootstrap.sh           # start or update local tooling container
#   bash bootstrap.sh sh        # open a shell inside the container
#   bash bootstrap.sh remove    # tear down infrastructure and clean state

export MSYS_NO_PATHCONV=1
: "${tz_project:=devops-utils}"

clean_tf_files() {
  rm -rf kubeconfig_* \
         .terraform \
         terraform.tfstate \
         terraform.tfstate.backup \
         .terraform.lock.hcl \
         s3_bucket_id \
         ./config_* \
         ./terraform-aws-eks/workspace/base/lb2.tf \
         ./terraform-aws-eks/workspace/base/.terraform
}

container_id() {
  docker ps | grep "docker-${tz_project}" | awk '{print $1}'
}

open_shell() {
  local id
  id=$(container_id)
  if [[ -z "${id}" ]]; then
    echo "[ERROR] No running container found for docker-${tz_project}." >&2
    exit 1
  fi
  docker exec -it "${id}" bash
}

remove_stack() {
  local id
  id=$(container_id)

  if [[ -z "${id}" ]]; then
    pushd terraform-aws-eks/workspace/base >/dev/null
    clean_tf_files
    popd >/dev/null

    pushd terraform-aws-iam/workspace/base >/dev/null
    clean_tf_files
    popd >/dev/null
    return
  fi

  docker exec -it "${id}" bash /topzone/scripts/eks_remove_all.sh
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] Failed to remove resources." >&2
    exit 1
  fi

  docker exec -it "${id}" bash /topzone/scripts/eks_remove_all.sh cleanTfFiles
}

case "${1:-up}" in
  remove)
    remove_stack
    ;;
  sh)
    open_shell
    ;;
  up)
    bash tz-local/docker/install.sh
    ;;
  *)
    echo "[ERROR] Unknown command: ${1}" >&2
    echo "Usage: bash bootstrap.sh [up|sh|remove]" >&2
    exit 1
    ;;
 esac
