# AWS Configuration
variable "aws_region" {
  description = "AWS region to launch servers"
  type        = string
  default     = "us-east-1"
}

# Network Configuration
variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["a", "b"]
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "public_key_path" {
  description = "Path to the public key"
  type        = string
  default     = "C:\\Users\\david\\pc1.pem"  # Ruta exacta al archivo de clave
}

variable "ssh_key_path" {
  description = "Path to the private SSH key"
  type        = string
  default     = "C:\\Users\\david\\pc1.pem"  # Ruta exacta al archivo de clave
}

# Auto Scaling Configuration
variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

# Database Configuration
variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  default     = "default_db_password"
  sensitive   = true
}

variable "db_name" {
  description = "Default database name"
  type        = string
  default     = "orderdb"
}

# MongoDB Configuration
variable "mongo_username" {
  description = "MongoDB username"
  type        = string
  default     = "mongoadmin"
  sensitive   = true
}

variable "mongo_password" {
  description = "Password for MongoDB"
  type        = string
  default     = "default_mongo_password"
  sensitive   = true
}

variable "mongo_uri" {
  description = "MongoDB connection string"
  type        = string
  default     = "mongodb://localhost:27017/"
}

# RabbitMQ Configuration
variable "rabbitmq_user" {
  description = "RabbitMQ username"
  type        = string
  default     = "rabbit"
}

variable "rabbitmq_pass" {
  description = "RabbitMQ password"
  type        = string
  default     = "rabbitpass"
  sensitive   = true
}

# Redis Configuration
variable "redis_user" {
  description = "Redis username"
  type        = string
  default     = "default"
  sensitive   = true
}

variable "redis_pass" {
  description = "Redis password"
  type        = string
  default     = "default_redis_password"
  sensitive   = true
}

# Docker Configuration
variable "docker_compose_version" {
  description = "Docker Compose version to install"
  type        = string
  default     = "v2.23.0"
}

# Security Group Configuration
variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH into the EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # WARNING: In production, restrict this to your IP
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring services (Prometheus, cAdvisor)"
  type        = bool
  default     = true
}

# Tags
variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "order-processing-system"
}

# Application Configuration
variable "app_port" {
  description = "Port on which the application will run"
  type        = number
  default     = 8080
}

# Load Balancer Configuration
variable "health_check_path" {
  description = "Path for the load balancer health check"
  type        = string
  default     = "/health"
}

# Auto Scaling Policy Configuration
variable "scale_up_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 70
}

variable "scale_down_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 30
}
