//# Route53 Zone Records
//resource "aws_route53_record" "main-tzcorp-com" {
//  zone_id = local.tzcorp_zone_id
//  name = "main"
//  type = "CNAME"
//  ttl = "300"
//  records = [aws_alb.main.dns_name]
//}
//
