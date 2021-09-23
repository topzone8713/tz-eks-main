#!/usr/bin/env bash

#set -x
shopt -s expand_aliases
alias k='kubectl --kubeconfig ~/.kube/config'

cd /vagrant/tz-local/resource/jenkins/helm
helm repo add jenkins https://charts.jenkins.io
helm search repo jenkins

helm list --all-namespaces -a
k delete namespace jenkins
k create namespace jenkins
k apply -f jenkins.yaml

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
aws_access_key_id=$(prop 'credentials' 'aws_access_key_id')
aws_secret_access_key=$(prop 'credentials' 'aws_secret_access_key')
cp -Rf values.yaml values.yaml_bak
sed -i "s/jenkins_aws_access_key/${aws_access_key_id}/g" values.yaml_bak
sed -i "s/jenkins_aws_secret_key/${aws_secret_access_key}/g" values.yaml_bak

aws_region=$(prop 'config' 'region')
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')

sed -i "s/aws_region/${aws_region}/g" values.yaml_bak
sed -i "s/eks_project/${eks_project}/g" values.yaml_bak

helm delete jenkins -n jenkins
helm install jenkins jenkins/jenkins  -f values.yaml_bak -n jenkins
#k patch svc jenkins --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":31000}]' -n jenkins
#k patch svc jenkins -p '{"spec": {"ports": [{"port": 8080,"targetPort": 8080, "name": "http"}], "type": "ClusterIP"}}' -n jenkins --force

cp -Rf jenkins-ingress.yaml jenkins-ingress.yaml_bak
sed -i "s/eks_project/${eks_project}/g" jenkins-ingress.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" jenkins-ingress.yaml_bak
k apply -f jenkins-ingress.yaml_bak -n jenkins

# install plugins
kubectl -n jenkins exec -it pod/jenkins-0 -- sh
wget https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.9.0/jenkins-plugin-manager-2.9.0.jar
kubectl -n jenkins cp jenkins-plugin-manager-2.9.0.jar jenkins-0:/var/jenkins_home
kubectl -n jenkins cp /vagrant/tz-local/resource/jenkins/jobs/devops-crawler jenkins-0:/var/jenkins_home/jobs/devops-crawler
kubectl -n jenkins cp /vagrant/tz-local/resource/jenkins/jobs/devops-crawler/install_plugins.sh jenkins-0:/var/jenkins_home/jobs/devops-crawler/install_plugins.sh
kubectl -n jenkins exec -it pod/jenkins-0 -- sh /var/jenkins_home/jobs/devops-crawler/install_plugins.sh
rm -Rf jenkins-plugin-manager-2.9.0.jar

# restart
kubectl -n jenkins delete pod/jenkins-0

echo "waiting for starting a jenkins server!"
sleep 60

k apply -f jenkins-ingress.yaml_bak -n jenkins

aws ecr create-repository \
    --repository-name devops-jenkins-${eks_project} \
    --image-tag-mutability IMMUTABLE

aws s3api create-bucket --bucket jenkins-${eks_project} --region ${aws_region} --create-bucket-configuration LocationConstraint=${aws_region}

echo "
##[ Jenkins ]##########################################################
#  - URL: http://jenkins.default.${eks_project}.${eks_domain}
#
#  - ID: admin
#  - Password:
#    kubectl -n jenkins exec -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/chart-admin-password && echo
#######################################################################
" >> /vagrant/info
cat /vagrant/info

exit 0

#kubectl -n jenkins cp jenkins-0:/var/jenkins_home/jobs/devops-crawler/config.xml /vagrant/tz-local/resource/jenkins/jobs/config.xml

