#!/usr/bin/env bash

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d "=" -f2 | sed "s/ //g"
}
eks_project=$(prop "project" "project")
GITHUB_ID=$(prop "project" "github_id")
GITHUB_TOKEN=$(prop "project" "github_token")

CMD=$1
SOURCE=$2

if [[ "${CMD}" == "" ]]; then
  CMD="backup"
fi
if [[ "${SOURCE}" == "" ]]; then
  SOURCE="local"
fi

if [[ "$3" != "" ]]; then
  eks_project=$3
fi

if [[ "${CMD}" == "restore" ]]; then
  if [[ "${SOURCE}" == "git" ]]; then
    git remote add origin "https://${GITHUB_ID}:${GITHUB_TOKEN}@github.com/dooheehong/tz-eks-backup.git"
    git clone "https://${GITHUB_ID}:${GITHUB_TOKEN}@github.com/dooheehong/tz-eks-backup.git"
  fi
  if [[ ! -d "tz-eks-backup/_data/${eks_project}" ]]; then
    echo "Not exit: tz-eks-backup/_data/${eks_project}"
    exit 1
  fi
  kubectl apply -f tz-eks-backup/_data/${eks_project} --recursive
  exit 0
fi

if [[ "${SOURCE}" == "git" ]]; then
  if [[ -d "tz-eks-backup/.git" ]]; then
    rm -Rf tz-eks-backup
  fi
  mkdir tz-eks-backup
  cd tz-eks-backup
  git init
  git remote add origin "https://${GITHUB_ID}:${GITHUB_TOKEN}@github.com/dooheehong/tz-eks-backup.git"
  git pull --allow-unrelated-histories "https://${GITHUB_ID}:${GITHUB_TOKEN}@github.com/dooheehong/tz-eks-backup.git"
  git branch -M main
  cd ..
fi

katafygio --no-git --dump-only \
  -e tz-eks-backup/_data/${eks_project}/env \
  -z kube-*,lens-metrics \
  -x secrets,events,nodes,endpoints,apiservice \
  -x rs,pod,pv,storageclass,ValidatingWebhookConfiguration \
  -x TargetGroupBinding,Lease,ControllerRevision,MutatingWebhookConfiguration \
  -x CustomResourceDefinition,PersistentVolumeClaim \
  -x CSINode,CSIDriver,PriorityClass \
  -y configmap:kube-system/leader-elector \
  -l "owner!=helm"

katafygio --no-git --dump-only \
  -e tz-eks-backup/_data/${eks_project}/org \
  -x secrets,events,nodes,endpoints,apiservice \
  -x rs,pod,pv,storageclass,ValidatingWebhookConfiguration \
  -x TargetGroupBinding,Lease,ControllerRevision \
  -y configmap:kube-system/leader-elector \
  -l "org=tz"

if [[ "${SOURCE}" == "local" ]]; then
  tar cvfz tz-eks-backup.zip tz-eks-backup/_data
else
  cd tz-eks-backup
  git add .
  git commit -m '.'
  git push --set-upstream origin main -f
  cd ..
fi



