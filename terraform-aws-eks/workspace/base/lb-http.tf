//# adds an http listener to the load balancer
//# (delete this file if you only want http)
//
//# The port to listen on for http, always use 80
//variable "main_http_port" {
//  default = "80"
//}
//
//resource "aws_alb_listener" "main" {
//  load_balancer_arn = aws_alb.main.id
//  port              = var.main_http_port
//  protocol          = "HTTP"
//
//  default_action {
//    target_group_arn = aws_alb_target_group.main.id
//    type             = "forward"
//  }
//}
//
//resource "aws_security_group_rule" "ingress_lb_main_http" {
//  type              = "ingress"
//  description       = "http"
//  from_port         = var.main_http_port
//  to_port           = var.main_http_port
//  protocol          = "TCP"
//  cidr_blocks       = ["0.0.0.0/0"]
//  security_group_id = aws_security_group.nsg_main_lb.id
//}
