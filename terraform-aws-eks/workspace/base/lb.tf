//# note that this creates the alb, target group, and access logs
//# the listeners are defined in lb-http.tf and lb-https.tf
//# delete either of these if your app doesn't need them
//# but you need at least one
//
//# Whether the application is available on the public internet,
//# also will determine which subnets will be used (public or private)
//variable "internal" {
//  default = false
//}
//
//# The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
//variable "main_deregistration_delay" {
//  default = "30"
//}
//
//# The path to the health check for the load balancer to know if the container(s) are ready
//variable "main_health_check" {
//  default = "/"
//}
//
//# How often to check the liveliness of the container
//variable "main_health_check_interval" {
//  default = "30"
//}
//
//# How long to wait for the response on the health check path
//variable "main_health_check_timeout" {
//  default = "10"
//}
//
//# What HTTP response code to listen for
//variable "main_health_check_matcher" {
//  default = "200,404"
//}
//
//resource "aws_alb" "main" {
//  name = "${local.cluster_name}-${local.environment}"
//
//  # launch lbs in public or private subnets based on "internal" variable
//  internal = var.internal
//  // subnets = split(
//  //   ",",
//  //   var.internal == true ? var.private_subnets : var.public_subnets,
//  // )
//  subnets = module.vpc.public_subnets
//  security_groups = [aws_security_group.nsg_main_lb.id]
//  tags            = local.tags
//
//}
//
//resource "aws_alb_target_group" "main" {
//  name                 = "${local.cluster_name}-${local.environment}"
//  port                 = var.lb_main_port
//  protocol             = var.lb_main_protocol
//  vpc_id               = module.vpc.vpc_id
//  target_type          = "ip"
//  deregistration_delay = var.main_deregistration_delay
//
//  health_check {
//    path                = var.main_health_check
//    matcher             = var.main_health_check_matcher
//    interval            = var.main_health_check_interval
//    timeout             = var.main_health_check_timeout
//    healthy_threshold   = 3
//    unhealthy_threshold = 5
//  }
//
//  tags = local.tags
//}
//
//data "aws_elb_service_account" "main" {
//}
//
//# The load balancer DNS name
//output "lb_dns" {
//  value = aws_alb.main.dns_name
//}
//
//# AWS Route53 Zone Records
