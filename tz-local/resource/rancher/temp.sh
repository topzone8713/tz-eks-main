#!/usr/bin/env bash

exit 0

set -x


##################################################################
# rancher server
##################################################################

## 1) open ports
# all ports: https://rancher.com/docs/rancher/v2.x/en/installation/requirements/ports/
# add rancher1 security group
# open tcp 22, 80, 443, 2379, 6443, 10250 inbound
# open udp 8472 inbound

sudo su

## 2) install docker
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -y install docker-ce
sudo systemctl start docker
sudo systemctl enable docker


cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "group": "root"
}
EOF

sudo service docker restart
sudo systemctl enable docker


sudo su

docker ps | grep 'rancher/rancher' | awk '{print $1}' | xargs docker stop
sudo rm -Rf /opt/rancher
docker run -d --restart=unless-stopped \
  -p 9080:80 -p 9443:443 \
  -v /opt/rancher:/var/lib/rancher \
  -e NO_PROXY="localhost,127.0.0.1,0.0.0.0,10.0.0.0/8,192.168.10.0/24,k8s-master" \
  rancher/rancher:latest

useradd centos
echo "centos" | passwd --stdin centos
sudo usermod -aG dockerroot centos

sudo groupadd docker
sudo usermod -aG docker centos

#add /etc/sudoers
cat <<EOF | sudo tee /etc/sudoers.d/rancher
centos ALL=(ALL) NOPASSWD:ALL
EOF

## 3) install rancher
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:latest

docker ps | grep 'rancher/rancher' | awk '{print $1}' | xargs docker logs -f

curl http://54.183.236.40

## 4) install rke

#sudo service docker restart

yum install wget -y
wget https://github.com/rancher/rke/releases/download/v1.2.1/rke_linux-amd64
mv rke_linux-amd64 /usr/bin/rke
chmod 755 /usr/bin/rke
rke -v

## open ports in master
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --add-masquerade --permanent
# only if you want NodePorts exposed on control plane IP as well
firewall-cmd --permanent --add-port=30000-32767/tcp
systemctl restart firewalld








  
docker run -d --restart=unless-stopped \
  -p 9080:80 -p 9443:443 \
  -e HTTP_PROXY="http://192.168.10.1:3128" \
  -e HTTPS_PROXY="http://192.168.10.1:3128" \
  -e NO_PROXY="localhost,127.0.0.1,0.0.0.0,10.0.0.0/8,192.168.10.0/24,example.com" \
  rancher/rancher:latest

docker ps | grep 'rancher/rancher' | awk '{print $1}' | xargs docker logs -f

# https://github.com/rancher/rke/releases/tag/v1.1.7

https://dooheehong323:9443/g/clusters

exit 0


rke up



---------------
ssh root@dooheehong323
su - testuser
testuser@master-1:~$ cd /Volumes/workspace/etc/tz-k8s-vagrant
testuser@master-1:/Volumes/workspace/etc/tz-k8s-vagrant$ vagrant reload

##########################################
# in vagrant host (master-1, rancher host, ~18.155)
##########################################
vagrant up
#vagrant reload

# make key in vagrant host (master-1, rancher host, ~18.155)
ssh-keygen -t rsa -C vagrant -P "" -f ~/.ssh/vagrant -q
chmod 400 ~/.ssh/vagrant
ssh-agent
ssh-add ~/.ssh/vagrant

##########################################
# in k8s host (~63.220, ~20-96)
##########################################
vagrant ssh k8s-master
sudo su
usermod -aG docker vagrant
usermod -aG docker root

sudo vi /etc/hosts
192.168.0.140 dooheehong323

mkdir /root/.ssh
cat <<EOF | sudo tee /root/.ssh/authorized_keys
ssh-rsa aaa
EOF
chmod 600 /root/.ssh/authorized_keys

##########################################
# in vagrant host (master-1, rancher host, ~18.155)
##########################################
# install docker
sudo usermod -aG docker root
sudo swapoff -a

cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "group": "root"
}
EOF

service docker restart

docker network ls
docker network ls | grep br0_rke | awk '{print $1}' | xargs docker network rm
docker network create --driver=bridge --subnet=10.43.0.0/16 br0_rke

# put ssh into k8s host (~63.220, ~20-96)
ssh -i ~/.ssh/vagrant vagrant@dooheehong323
ssh -i ~/.ssh/vagrant vagrant@dooheehong323 "mkdir -p /home/vagrant/.ssh"
scp -i ~/.ssh/vagrant vagrant vagrant@dooheehong323:/home/vagrant.ssh/
scp -i ~/.ssh/vagrant vagrant.pub vagrant@dooheehong323:/home/vagrant.ssh/

ssh -i /root/.ssh/vagrant root@10.0.0.10
scp -i vagrant vagrant root@10.0.0.10:/root/.ssh/vagrant
scp -i vagrant vagrant.pub root@10.0.0.10:/root/.ssh/vagrant.pub 

##########################################
# in k8s host (~63.220, ~20-96)
##########################################
https://kubernetes.io/docs/tasks/tools/install-kubectl/

sudo chmod 600 /root/.ssh/vagrant*
eval `ssh-agent & ssh-add vagrant`
sudo usermod -aG docker root

cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "group": "root"
}
EOF

sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

##########################################
# in vagrant host (master-1, rancher host, ~18.155)
##########################################

cd /Volumes/workspace/etc/tz-k8s-vagrant

# in master
download rke
https://github.com/rancher/rke/releases
https://github.com/rancher/rke/releases/tag/v1.1.7
#yum install wget -y
wget https://github.com/rancher/rke/releases/download/v1.1.7/rke_linux-amd64
wget https://github.com/rancher/rke/releases/download/v1.2.1/rke_linux-amd64


sudo mv rke_linux-amd64 /usr/bin/rke
sudo chmod 755 /usr/bin/rke
rke -v


vi ~/.ssh/id_rsa  # /Users/testuser/.ssh/testuser
chmod 600 ~/.ssh/id_rsa

rke config
[+] Cluster Level SSH Private Key Path [~/.ssh/id_rsa]: /root/.ssh/vagrant
[+] Number of Hosts [1]:          
[+] SSH Address of host (1) [none]: 10.0.0.10
[+] SSH Port of host (1) [22]: 
[+] SSH Private Key Path of host (10.0.0.10) [none]: /root/.ssh/vagrant
[+] SSH User of host (10.0.0.10) [ubuntu]: root
[+] Is host (10.0.0.10) a Control Plane host (y/n)? [y]: 
[+] Is host (10.0.0.10) a Worker host (y/n)? [n]: 
[+] Is host (10.0.0.10) an etcd host (y/n)? [n]: 
[+] Override Hostname of host (10.0.0.10) [none]: 
[+] Internal IP of host (10.0.0.10) [none]: 
[+] Docker socket path on host (10.0.0.10) [/var/run/docker.sock]: 
[+] Network Plugin Type (flannel, calico, weave, canal) [canal]: 
[+] Authentication Strategy [x509]: 
[+] Authorization Mode (rbac, none) [rbac]: 
[+] Kubernetes Docker image [rancher/hyperkube:v1.18.8-rancher1]: 
[+] Cluster domain [cluster.local]: 
[+] Service Cluster IP Range [10.43.0.0/16]: 
[+] Enable PodSecurityPolicy [n]: 
[+] Cluster Network CIDR [10.42.0.0/16]: 
[+] Cluster DNS Service IP [10.43.0.10]: 
[+] Add addon manifest URLs or YAML files [no]: 

vi cluster.yml
  docker_socket: /var/run/docker.sock
  ssh_key: ""
  ssh_key_path: /root/.ssh/vagrant
  ssh_cert: ""
  ssh_cert_path: ""
addon_job_timeout: 30

rke up

sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

kubectl --kubeconfig kube_config_cluster.yml version
kubectl --kubeconfig kube_config_cluster.yml get nodes

https://dooheehong323:9443/c/c-h7hml/edit?provider=import
curl --insecure -sfL https://dooheehong323:9443/v3/import/vd5g98ht6pxg7cdq586qgjcxnwl7fkjdvq5f7wz7wb2tgcljsfwsm5.yaml | kubectl delete --kubeconfig=kube_config_cluster.yml -f -
curl --insecure -sfL https://dooheehong323:9443/v3/import/vd5g98ht6pxg7cdq586qgjcxnwl7fkjdvq5f7wz7wb2tgcljsfwsm5.yaml | kubectl apply --kubeconfig=kube_config_cluster.yml -f -

ln -s /usr/share/zoneinfo/America/Los_Angeles localtime

##########################################
# in k8s host (~63.220, ~20-96)
##########################################
sudo mkdir /home/vagrant/.kube
sudo cp /vagrant/kube_config_cluster.yml /home/vagrant/.kube/config



docker rm -fv  $(docker ps -a -q) 
docker volume rm -f $(docker volume ls)
sudo reboot -h now
sudo su
rm -rf /run/secrets/kubernetes.io
rm -rf /var/lib/etcd
rm -rf /var/lib/kubelet
rm -rf /var/lib/rancher
rm -rf /etc/kubernetes
rm -rf /opt/rke
exit
docker volume rm -f $(docker volume ls)
sudo reboot -h now


