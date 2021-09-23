resource "aws_security_group" "worker_group_devops" {
  name_prefix = "worker_group_devops"
  vpc_id      = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.allowed_management_cidr_blocks
  }
  ##[ allow icmp only for the cidr_blocks ]######################################################
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [
      local.VPC_CIDR,
      local.DEVOPS_UTIL_CIDR,
    ]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # consul
    from_port = 8500
    to_port   = 8500
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # consul
    from_port = 8501
    to_port   = 8501
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "10.20.0.0/16",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # vault
    from_port = 8200
    to_port   = 8200
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # filebeat
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # logstash
    from_port = 5044
    to_port   = 5044
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # influxdb
    from_port = 8086
    to_port   = 8086
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # influxdb
    from_port = 8088
    to_port   = 8088
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # mysql
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
//      "${aws_instance.eks-main-bastion.public_ip}/32",
    ]
  }
//  ingress {   # NFS
//    from_port = 2049
//    to_port   = 2049
//    protocol  = "tcp"
//    cidr_blocks = [
//      "10.0.0.0/8",
//      local.DEVOPS_UTIL_CIDR,
//      "172.16.0.0/16",
//      "192.168.0.0/16",
//    ]
//  }
}

resource "aws_security_group" "worker_group_datateam" {
  name_prefix = "worker_group_datateam"
  vpc_id      = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.allowed_management_cidr_blocks
  }
  ##[ allow icmp only for the cidr_blocks ]######################################################
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [
      local.VPC_CIDR,
      local.DEVOPS_UTIL_CIDR,
    ]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "${local.VCP_BCLASS}.0.0/16",
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # vault
    from_port = 8200
    to_port   = 8200
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "worker_group_flanet" {
  name_prefix = "worker_group_flanet"
  vpc_id      = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.allowed_management_cidr_blocks
  }
  ##[ allow icmp only for the cidr_blocks ]######################################################
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [
      local.VPC_CIDR,
      local.DEVOPS_UTIL_CIDR,
    ]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "${local.VCP_BCLASS}.0.0/16",
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # vault
    from_port = 8200
    to_port   = 8200
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.allowed_management_cidr_blocks
  }
  ##[ allow icmp only for the cidr_blocks ]######################################################
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [
      local.VPC_CIDR,
      local.DEVOPS_UTIL_CIDR,
    ]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # consul
    from_port = 8500
    to_port   = 8500
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
  ingress {   # vault
    from_port = 8200
    to_port   = 8200
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      local.DEVOPS_UTIL_CIDR,
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
}
