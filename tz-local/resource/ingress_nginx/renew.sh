#!/usr/bin/env bash

PROJECTS=($(kubectl get namespaces | awk '{print $1}' | tr '\n' ' '))
PROJECTS=(datateam-dev lens- datateam kube-)
for item in "${PROJECTS[@]}"; do
  if [[ "${item}" != "NAME" && "${item}" != cert-* && "${item}" != kube-* && "${item}" != lens-* ]]; then
    echo "=== ${item} =================="
    kubectl cert-manager renew --namespace=${item} --all
  fi
done

exit 0