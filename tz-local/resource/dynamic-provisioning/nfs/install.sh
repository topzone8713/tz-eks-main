#!/usr/bin/env bash

shopt -s expand_aliases
alias k='kubectl --kubeconfig ~/.kube/config'

# install NFS in k8s
#https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/deploy/example/nfs-provisioner/README.md

# 1. Create a NFS provisioner
k create -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/example/nfs-provisioner/nfs-server.yaml

# 2. Install NFS CSI driver master version on a kubernetes cluster
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/install-driver.sh | bash -s master --

k -n kube-system get pod -o wide -l app=csi-nfs-controller
k -n kube-system get pod -o wide -l app=csi-nfs-node

# may need to reboot vagrant reload
k get all --all-namespaces | grep nfs

# 3. Verifying a driver installation
k get csinodes \
-o jsonpath='{range .items[*]} {.metadata.name}{": "} {range .spec.drivers[*]} {.name}{"\n"} {end}{end}'

k create -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/example/nfs-provisioner/nginx-pod.yaml
k exec nginx-nfs-example -- bash -c "findmnt /var/www -o TARGET,SOURCE,FSTYPE"

k delete -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/example/nfs-provisioner/nginx-pod.yaml

cd /vagrant/tz-local/resource/dynamic-provisioning/nfs
###############################################################
# !!! Storage Class Usage (Dynamic Provisioning)
###############################################################
k apply -f dynamic-provisioning-nfs.yaml
k apply -f dynamic-provisioning-nfs-test.yaml
k get pv,pvc
k delete -f dynamic-provisioning-nfs-test.yaml

###############################################################
# !!! PV/PVC Usage (Static Provisioning)
###############################################################
k apply -f static-provisioning-nfs.yaml
k apply -f static-provisioning-nfs-test.yaml
k get pv,pvc
k delete -f static-provisioning-nfs-test.yaml

# Output: mount.nfs: Failed to resolve server nfs-server.default.svc.cluster.local: Name or service not known
# k run -it busybox --image=busybox --restart=Never --rm -- nslookup nfs-server.default.svc.cluster.local

exit 0