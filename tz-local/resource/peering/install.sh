#!/usr/bin/env bash

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')

ssh ubuntu@3.35.238.167
ssh -i /home/ubuntu/.ssh/${eks_project} ubuntu@10.20.1.178

# postback-rds-dev  => pcx-033e3d9f68e040e06
#rtb-0d0b96e2dd09383ba -> vpc-0d36a9000aba0ebbe
#  subnet-08445a4c4905d929f | eks-main-vpc-private-ap-northeast-2a 10.20.1.0/24  rtb-0d0b96e2dd09383ba
#  subnet-0fac7c58ed24c9039 | eks-main-vpc-private-ap-northeast-2c 10.20.3.0/24  rtb-0d0b96e2dd09383ba
#  subnet-02f1720580e09034d | eks-main-vpc-private-ap-northeast-2b 10.20.2.0/24  rtb-0d0b96e2dd09383ba
#rtb-81adfbe8  -> vpc-0f94d266
#  subnet-3e4fc773 10.0.1.0/24
#  subnet-ed560084 10.0.2.0/24

sudo apt-get update
sudo apt install inetutils-traceroute traceroute -y

telnet 10.0.2.198 6379

telnet eks-test-001.etokrl.0001.apn2.cache.amazonaws.com 6379

nc -z -v eks-test-001.etokrl.0001.apn2.cache.amazonaws.com 6379
11211

itsthenetwork/alpine-redis-cli


EKS group
  ec2 1
  ec2 2
  ec2 3
    pod
03dd6ee9deb29ed9d
################################################
#kafka
vpc-03dd6ee9deb29ed9d | SaKube/Vpc  10.140.0.0/16 rtb-078978c92fe6a2b2e
  subnet-0d4e106458c6d07fe  10.140.0.0/20 rtb-0c906f8fb52cf849b | SaKube/Vpc/eks-clusterSubnet1
  subnet-046819225da82d988  10.140.16.0/20  rtb-0c82094d0e96710c5 | SaKube/Vpc/eks-clusterSubnet2
  subnet-0a5388aa02015b0f2  10.140.32.0/20  rtb-005f83c97f17bcb40 | SaKube/Vpc/eks-clusterSubnet3

sg-0bf27c99f11a2f672

nc -z -v b-1.kafka-datateam.7f2zdg.c3.kafka.ap-northeast-2.amazonaws.com 9092
telnet b-1.kafka-datateam.7f2zdg.c3.kafka.ap-northeast-2.amazonaws.com 9092
  => 10.140.31.69
telnet b-2.kafka-datateam.7f2zdg.c3.kafka.ap-northeast-2.amazonaws.com 9092
telnet b-3.kafka-datateam.7f2zdg.c3.kafka.ap-northeast-2.amazonaws.com 9092

nc -zv b-1.kafka-datateam.7f2zdg.c3.kafka.ap-northeast-2.amazonaws.com 9092


aws eks describe-cluster --name ${eks_project} --query cluster.resourcesVpcConfig.clusterSecurityGroupId
"sg-05014d70957060b74"

aws eks describe-cluster --name ${eks_project} --query cluster.resourcesVpcConfig.securityGroupIds
sg-0c0374687b6aebb2d




RDS - OK
  AWS - KAFKA
      - REDIS

#ssh -i "msk_key_pair.pem" ec2-user@ec2-3-34-146-94.ap-northeast-2.compute.amazonaws.com




nslookup postback-dev-instance-1.c01spz81v11d.ap-northeast-2.rds.amazonaws.com
telnet postback-dev-instance-1.c01spz81v11d.ap-northeast-2.rds.amazonaws.com 6379

kubectl run -it busybox --image=busybox:1.28.0 -n ib-dev -- sh
kubectl run -it busybox --image=alpine:3.6 -n monitoring -- sh
kubectl run -it busybox --image=alpine:3.6 -n monitoring --overrides='{ "spec": { "nodeSelector": { "team": "devops", "environment": "prod" } } }' -- sh
apk add curl
telnet 172.20.111.5 8086

#  names = [
#//    "tz-jenkins",
#  ]
#  resources = [
#//    "tz-jenkins_${local.cluster_name}",
#  ]
#  route_table_name = [
#//    "devops-utils-public",
#  ]
#  route_table_id = [
#//    "rtb-xxx",
#  ]
#  peer_vpc_id = [
#//    "vpc-xxx",
#  ]
#  destination_cidr_block = [
#//    "20.10.0.0/16",
#  ]