#!/usr/bin/env bash

set -x

# https://rancher.com/docs/rancher/v2.x/en/installation/other-installation-methods/single-node-docker/

##################################################################
# rancher server
##################################################################

sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
sudo apt-get update
sudo apt-get install -y docker.io apt-transport-https curl
sudo systemctl start docker
sudo systemctl enable docker

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "group": "root"
}
EOF

sudo service docker restart
sudo systemctl enable docker

sudo groupadd ubuntu
sudo useradd -m ubuntu -g ubuntu -s /bin/bash
echo -e "ubuntu\nubuntu" | passwd ubuntu
sudo mkdir /home/ubuntu
sudo chown ubuntu:ubuntu /home/ubuntu
sudo groupadd docker
sudo usermod -aG docker ubuntu

#add /etc/sudoers
cat <<EOF | sudo tee /etc/sudoers.d/rancher
ubuntu ALL=(ALL) NOPASSWD:ALL
EOF

# config DNS
sudo service systemd-resolved stop
sudo systemctl disable systemd-resolved
sudo rm -Rf /etc/resolv.conf
cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF

########################################################################
# - install kubectl
########################################################################
sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

##################################################################
# - install rancher
##################################################################
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:latest

sleep 120
echo docker ps | grep 'rancher/rancher' | awk '{print $1}' | xargs docker logs -f

echo "##################################################################"
echo " Rancher URL: https://10.0.0.10"
echo "##################################################################"

##################################################################
# - install rke
##################################################################
#sudo service docker restart

wget https://github.com/rancher/rke/releases/download/v1.2.1/rke_linux-amd64
sudo mv rke_linux-amd64 /usr/bin/rke
sudo chmod 755 /usr/bin/rke
rke -v

##################################################################
# - rke config (with ubuntu account)
##################################################################
sudo mkdir -p /home/ubuntu/.ssh
sudo chown -Rf ubuntu:ubuntu /home/ubuntu
su - ubuntu
cd /home/ubuntu/.ssh
ssh-keygen -t rsa -C ubuntu -P "" -f /home/ubuntu/.ssh/id_rsa -q

sudo cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys

cat <<EOF > /home/ubuntu/.ssh/config
Host 192.168.*
  StrictHostKeyChecking   no
  LogLevel                ERROR
  UserKnownHostsFile      /dev/null
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_rsa
EOF

sudo chown -Rf ubuntu:ubuntu /home/ubuntu
sudo chmod 640 /home/ubuntu/.ssh/authorized_keys
sudo chmod 600 /home/ubuntu/.ssh/id_rsa
eval `ssh-agent`
ssh-add id_rsa

sudo mkdir /vagrant/shared
sudo cp /home/ubuntu/.ssh/id_rsa.pub /vagrant/shared/authorized_keys
#sudo chmod 700 /home/ubuntu/.ssh
#sudo chmod 640 /home/ubuntu/.ssh/authorized_keys

echo "########################################################################"
echo "Need to run and follow two shells!!!"
echo
bash "/vagrant/tz-local/resource/rancher/create_k8s_cluster.sh"
echo "bash /vagrant/tz-local/resource/rancher/import_k8s_cluster.sh"
echo "bash /vagrant/tz-local/resource/rancher/jenkins.sh"
echo "########################################################################"
