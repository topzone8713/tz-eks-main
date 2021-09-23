#!/usr/bin/env bash

set -x

##################################################################
# k8s node
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

sudo mkdir -p /home/ubuntu/.ssh
sudo chown -Rf ubuntu:ubuntu /home/ubuntu
sudo chmod 700 /home/ubuntu/.ssh
sudo cp /vagrant/shared/authorized_keys /home/ubuntu/.ssh/authorized_keys
sudo chmod 640 /home/ubuntu/.ssh/authorized_keys
sudo chown -Rf ubuntu:ubuntu /var/run/docker.sock
docker ps

########################################################################
# - install kubectl
########################################################################
sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

exit 0
