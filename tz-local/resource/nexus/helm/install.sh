#!/usr/bin/env bash

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_domain=$(prop 'project' 'domain')
eks_project=$(prop 'project' 'project')

#cd /vagrant/tz-local/resource/nexus
helm repo add oteemocharts https://oteemo.github.io/charts
helm search repo oteemocharts/sonatype-nexus
helm repo update
helm install tz oteemocharts/sonatype-nexus -f /vagrant/tz-local/resource/nexus/helm/values.yaml -n sonatype-nexus
#helm install tz oteemocharts/sonatype-nexus -f values.yaml -n sonatype-nexus
#helm delete tz -n sonatype-nexus

helm list --all-namespaces -a
#helm upgrade tz oteemocharts/sonatype-nexus -f /vagrant/tz-local/resource/nexus/helm/values.yaml -n sonatype-nexus --wait

# after delete service and create with fixed service.yaml
k delete -f /vagrant/tz-local/resource/nexus/helm/service.yaml
k apply -f /vagrant/tz-local/resource/nexus/helm/service.yaml
#k delete -f service.yaml
#k apply -f service.yaml

#k patch tz-deployment.apps/sonatype-nexus -n sonatype-nexus \
# --type json -p='[{"op": "replace", "path": "/spec/template/spec/containers/1/env/4", "value": {"name": "NEXUS_DOCKER_HOST" } }]'
#
#k patch tz-deployment.apps/sonatype-nexus -n sonatype-nexus \
# --type json -p='[{"op": "replace", "path": "/spec/template/spec/containers/1/env/4", "value": {"name": "NEXUS_DOCKER_HOST", "value": "docker.'${eks_project}'.'${eks_domain}'" } }]'
#
k patch tz-deployment.apps/sonatype-nexus -n sonatype-nexus \
 --type json -p='[{"op": "replace", "path": "/spec/template/spec/containers/1/env/5", "value": {"name": "NEXUS_HTTP_HOST" } }]'

k patch tz-deployment.apps/sonatype-nexus -n sonatype-nexus \
 --type json -p='[{"op": "replace", "path": "/spec/template/spec/containers/1/env/5", "value": {"name": "NEXUS_HTTP_HOST", "value": "*" } }]'

k delete service/sonatype-nexus -n sonatype-nexus

k expose tz-deployment.apps/sonatype-nexus -n sonatype-nexus --type="LoadBalancer" --port=8080 --targetPort=8081

k expose tz-deployment.apps/sonatype-nexus -n sonatype-nexus --name=sonatype-nexus-docker --type="LoadBalancer" --port=5003

k patch tz-deployment.apps/sonatype-nexus -n sonatype-nexus \
 --type json -p='[{"op": "replace", "path": "/spec/template/spec/containers/1/env/8", "value": {"name": "UPSTREAM_HTTP_PORT", "value": "8080" } }]'

 cho '
##[ Nexus ]##########################################################
- url: http://dooheehong323:30661/
- admin / admin123

http://192.168.1.10:8081/#admin/repository/blobstores

Create blob store
  docker-hosted
  docker-hub

http://192.168.1.10:8081/#admin/repository/repositories
  Repositories > Select Recipe > Create repository: docker (hosted)
  name: docker-hosted
  http: 5003
  Enable Docker V1 API: checked
  Blob store: docker-hosted

Repositories > Select Recipe > Create repository: docker (proxy)
  name: docker-hub
  Enable Docker V1 API: checked
  Remote storage: https://registry-1.docker.io
  select Use Docker Hub
  Blob store: docker-hub

http://192.168.1.10:8081/#admin/security/realms
  add "Docker Bearer Token Realm" Active

docker login dooheehong323_docker.com
docker pull busybox
RMI=`docker images -a | grep busybox | awk '{print $3}'`
docker tag $RMI dooheehong323_docker.com/busybox:v20201225
docker push dooheehong323_docker.com/busybox:v20201225

http://192.168.1.10:8081/#browse/browse:docker-hosted

#######################################################################
' >> /vagrant/info
cat /vagrant/info
