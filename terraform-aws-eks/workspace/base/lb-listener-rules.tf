//resource "aws_lb_listener_rule" "eks-main-dev-main" {
//  listener_arn = aws_alb_listener.main.arn
//  priority = 100
//
//  action {
//    type = "forward"
//    target_group_arn = aws_alb_target_group.main.id
//  }
//
//  condition {
//    host_header {
//      values = var.main_endpoint
//    }
//  }
//}
