output "aws_alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "URL of web-page / DNS name of the Application Load Balancer"
}