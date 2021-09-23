#!/usr/bin/env bash

#set -x
shopt -s expand_aliases
alias k='kubectl --kubeconfig ~/.kube/config'

cd /home/vagrant

echo "## [ install prometheus ] #############################"
#k delete namespace monitoring
k create namespace monitoring

helm search repo stable | grep prometheus
helm uninstall monitor -n monitoring
helm install monitor stable/prometheus -n monitoring

helm inspect values stable/prometheus

cat <<EOF > volumeF.yaml
alertmanager:
    persistentVolume:
        enabled: false
server:
    persistentVolume:
        enabled: false
pushgateway:
    persistentVolume:
        enabled: false
EOF

helm uninstall monitor -n monitoring
helm install monitor stable/prometheus -n monitoring -f values.yaml

k get svc -n monitoring
k patch svc monitor-prometheus-server --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":32449}]' -n monitoring

master_ip='192.168.1.10'
k get svc -n monitoring | grep monitor-prometheus-server
private_ip=`k get svc -n monitoring | grep monitor-prometheus-server | awk '{print $3}'`
#monitor-prometheus-server          NodePort    10.105.94.92    <none>        80:32449/TCP             15m
echo "curl http://${master_ip}:32449 in master"

echo "## [ install grafana ] #############################"
helm repo add stable https://charts.helm.sh/stable
helm repo update

helm search repo stable | grep grafana
helm uninstall grafana -n monitoring
helm install grafana --wait --timeout 30s stable/prometheus-operator -n monitoring
#helm list -n monitoring
k get svc -n monitoring | grep grafana

k patch svc `k get svc -n monitoring | grep grafana | awk '{print $1}'` --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30912}]' -n monitoring
echo "curl http://${master_ip}:30601 in master"

k get all -n monitoring

echo '
##[ Monitoring ]##########################################################
- Prometheus: http://192.168.1.10:32449
- Grafana: http://192.168.1.10:30912
  admin / prom-operator
  import grafana ID from https://grafana.com/grafana/dashboards into your grafana!
#######################################################################
' >> /vagrant/info
cat /vagrant/info

exit 0
