#!/usr/bin/env bash

#set -x
shopt -s expand_aliases
alias k='kubectl --kubeconfig ~/.kube/config'

cd /vagrant/tz-local/resource/redis

NS=devops

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

#helm uninstall redis-cluster -n ${NS}
helm upgrade --install --reuse-values redis-cluster \
  --set cluster.slaveCount=1 \
  --set auth.enabled=false \
  --set securityContext.enabled=true \
  --set securityContext.fsGroup=2000 \
  --set securityContext.runAsUser=1000 \
  --set volumePermissions.enabled=true \
  --set master.persistence.enabled=true \
  --set slave.persistence.enabled=true \
  --set master.persistence.enabled=true \
  --set master.persistence.path=/data \
  --set master.persistence.size=1Gi \
  --set master.persistence.storageClass=gp2 \
  --set slave.persistence.enabled=true \
  --set slave.persistence.path=/data \
  --set slave.persistence.size=1Gi \
  --set slave.persistence.storageClass=gp2 \
bitnami/redis -n ${NS}

#  --set password=1234qwer \

k patch StatefulSet/redis-cluster-master -p '{"spec": {"template": {"spec": {"nodeSelector": {"team": "devops"}}}}}' -n ${NS}
k patch StatefulSet/redis-cluster-master -p '{"spec": {"template": {"spec": {"nodeSelector": {"environment": "prod"}}}}}' -n ${NS}
k patch StatefulSet/redis-cluster-replicas -p '{"spec": {"template": {"spec": {"nodeSelector": {"team": "devops"}}}}}' -n ${NS}
k patch StatefulSet/redis-cluster-replicas -p '{"spec": {"template": {"spec": {"nodeSelector": {"environment": "prod"}}}}}' -n ${NS}
k patch StatefulSet/redis-cluster-replicas -p '{"spec": {"template": {"spec": {"replicas": 1}}}}' -n ${NS}
k patch svc redis-cluster-master -n ${NS} -p '{"spec": {"type": "LoadBalancer"}}'

k scale --replicas=1 StatefulSet redis-cluster-replicas -n ${NS}
k scale --replicas=1 StatefulSet redis-cluster-replicas -n ${NS}

#redis-cluster-master.default.svc.cluster.local for read/write operations (port 6379)
#redis-cluster-replicas.default.svc.cluster.local for read-only operations (port 6379)

nc -zv redis-cluster-master.devops.svc.cluster.local 6379

export REDIS_PASSWORD=$(kubectl get secret --namespace ${NS} redis-cluster -o jsonpath="{.data.redis-password}" | base64 --decode)
echo $REDIS_PASSWORD

sleep 240

REDIS_HOST=$(kubectl get svc redis-cluster-master -n ${NS} | tail -n 1 | awk '{print $4}')
echo ${REDIS_HOST}
REDIS_PORT=6379

telnet ${REDIS_HOST} ${REDIS_PORT}

exit 0

NAME: redis-cluster
LAST DEPLOYED: Thu Apr 15 06:03:24 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **
Redis(TM) can be accessed via port 6379 on the following DNS names from within your cluster:

redis-cluster-master.default.svc.cluster.local for read/write operations
redis-cluster-slave.default.svc.cluster.local for read-only operations

To get your password run:

    export REDIS_PASSWORD=$(kubectl get secret --namespace default redis-cluster -o jsonpath="{.data.redis-password}" | base64 --decode)

    => password

To connect to your Redis(TM) server:

1. Run a Redis(TM) pod that you can use as a client:
   kubectl run --namespace default redis-cluster-client --rm --tty -i --restart='Never' \
    --env REDIS_PASSWORD=$REDIS_PASSWORD \
   --image docker.io/bitnami/redis:6.2.1-debian-10-r36 -- bash

2. Connect using the Redis(TM) CLI:
   redis-cli -h redis-cluster-master -a $REDIS_PASSWORD
   redis-cli -h redis-cluster-slave -a $REDIS_PASSWORD

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/redis-cluster-master 6379:6379 &
    redis-cli -h 127.0.0.1 -p 6379 -a $REDIS_PASSWORD



