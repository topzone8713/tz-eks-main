#!/usr/bin/env bash

#https://github.com/bpineau/katafygio

#bash /vagrant/tz-local/resource/k8s-backup/install.sh
cd /vagrant/tz-local/resource/k8s-backup

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
admin_password=$(prop 'project' 'admin_password')
eks_project=$(prop 'project' 'project')

cd /vagrant/tz-local/resource/k8s-backup

helm repo add katafygio https://bpineau.github.io/katafygio
helm repo update

helm install kube-backups katafygio/katafygio

export KF_GIT_URL="https://devops-tz:${admin_password}@github.com/dooheehong/eks-backup.git"
export KF_LOCAL_DIR=/vagrant/tz-local/resource/backup/_data
export KF_LOG_LEVEL=info
export KF_EXCLUDE_KIND="secret" # pod ep rs clusterrole
export KUBECONFIG=~/.kube/config

wget https://github.com/bpineau/katafygio/releases/download/v0.8.3/katafygio_0.8.3_amd64.deb
sudo dpkg -i katafygio_0.8.3_amd64.deb
rm -Rf katafygio_0.8.3_amd64.deb

echo "
##[ k8s-backup ]##########################################################
# - backup to local dir, tz-eks-backup
#   bash backup_k8s.sh backup local
# - backup to git, https://github.com/dooheehong/tz-eks-backup.git
#   bash backup_k8s.sh backup git
# - restore from local dir, tz-eks-backup
#   bash backup_k8s.sh restore
# - restore from git
#   bash backup_k8s.sh restore git
# - restore from other cluster
#   bash backup_k8s.sh restore local ${eks_project}
#######################################################################
" >> /vagrant/info
cat /vagrant/info

exit 0

kubectl exec -i -t --namespace default \
  $(kubectl get pods --namespace default -l app=katafygio -o jsonpath='{.items[0].metadata.name}') \
  ls /var/lib/katafygio/data

git remote add origin 'https://github.com/dooheehong/tz-eks-backup.git'
git clone 'https://doohee.hong:d465eaa43af65cececde0a63e310c2bd24af375b@github.com/dooheehong/tz-eks-backup.git'
katafygio -g 'https://doohee.hong:d465eaa43af65cececde0a63e310c2bd24af375b@github.com/dooheehong/tz-eks-backup.git' \
  -e /vagrant/tz-local/resource/backup/_data \
  -y configmap:kube-system/leader-elector \
  -l 'name=devops-ad-achievements'

kubectl apply -f /vagrant/tz-local/resource/backup/_data/ --recursive


