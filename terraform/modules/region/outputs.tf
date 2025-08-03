output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.docker_alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.docker_tg.arn
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "ID of the security group for instances"
  value       = aws_security_group.web_sg.id
}

output "region" {
  description = "The AWS region"
  value       = var.region
}

output "ebs_volume_id" {
  description = "ID of the EBS volume for application data"
  value       = aws_ebs_volume.app_data.id
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.docker_lt.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.docker_asg.name
}
