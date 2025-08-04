# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_subnets[*].id
}

# Internet Gateway Output
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

# Route Table Output
output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public_rt.id
}

# Launch Template Output
output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.app_lt.id
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.app_lt.latest_version
}

# CloudWatch Alarm Outputs
output "high_cpu_alarm_arn" {
  description = "The ARN of the high CPU usage alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.arn
}

output "low_cpu_alarm_arn" {
  description = "The ARN of the low CPU usage alarm"
  value       = aws_cloudwatch_metric_alarm.low_cpu.arn
}
