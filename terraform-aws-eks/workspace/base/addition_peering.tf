########################################################################
# vpc_peering:
########################################################################
# - devops-utils-public: for jenkins

locals {

//  20.30.0.0/16

  names = [
    "tz-devops-utils",
    "postback-rds-dev",
    "sakube-eks-cluster",
  ]
  resources = [
    "tz-jenkins_${local.cluster_name}",
    "eks-postback-rds-dev_${local.cluster_name}",
    "eks-sakube1_${local.cluster_name}",
  ]
  route_table_name = [
    "devops-utils",
    "postback-rds-dev",
    "sakube-eks-cluster",
  ]
  route_table_id = [
    "rtb-0013e1c0d3f1f91d1",
    "rtb-81adfbe8",
    "rtb-078978c92fe6a2b2e",
    ## add subnet-046819225da82d988, subnet-0d4e106458c6d07fe, subnet-0a5388aa02015b0f2 to Subnet Association !!!!
  ]
  peer_vpc_id = [
    "vpc-0b1a4d147703998a1",
    "vpc-0f94d266",
    "vpc-03dd6ee9deb29ed9d",
  ]
  destination_cidr_block = [
    "20.10.0.0/16",
    "10.0.0.0/16",
    "10.140.0.0/16",
  ]
}

########################################################################
# vpc_peering: eks <-> utils
########################################################################
resource "aws_vpc_peering_connection" "eks2utils" {
  count         = length(local.names)
  peer_vpc_id   = element(local.peer_vpc_id.*, count.index)
  vpc_id        = module.vpc.vpc_id
  auto_accept   = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Name = element(local.resources.*, count.index)
  }
}
resource "aws_route" "eks2utils" {
  count         = length(local.names)
  route_table_id            = module.vpc.private_route_table_ids[0]   # eks
  destination_cidr_block    = element(local.destination_cidr_block.*, count.index)
  vpc_peering_connection_id = element(aws_vpc_peering_connection.eks2utils.*.id, count.index)
}
resource "aws_route" "utils2eks" {
  count         = length(local.names)
  route_table_id            = element(local.route_table_id.*, count.index)
  destination_cidr_block    = local.VPC_CIDR   # eks
  vpc_peering_connection_id = element(aws_vpc_peering_connection.eks2utils.*.id, count.index)
}

