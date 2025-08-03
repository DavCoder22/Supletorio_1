# AWS Credentials
variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS session token"
  type        = string
  sensitive   = true
  default     = ""
}

# Database Credentials
variable "redis_user" {
  description = "Redis username"
  type        = string
  sensitive   = true
  default     = "redis1"
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
  default     = "Sebasalejandro22"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  sensitive   = true
  default     = "postgres1"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
  default     = "Sebasalejandro22"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "mongo_user" {
  description = "MongoDB username"
  type        = string
  sensitive   = true
  default     = "mongo1"
}

variable "mongo_password" {
  description = "MongoDB password"
  type        = string
  sensitive   = true
  default     = "Sebasalejandro22"
}

# Region Configuration
variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for failover"
  type        = string
  default     = "us-west-2"
}

# Instance Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the key pair to use for EC2 instances"
  type        = string
  default     = "pc1"
}

# AMI IDs (Debes actualizar estos valores según las regiones)
variable "ami_ids" {
  description = "Map of AMI IDs for different regions"
  type        = map(string)
  default = {
    us-east-1 = "ami-08a6efd148b1f7504"  # Actualiza con AMI correcta para us-east-1
    us-west-2 = "ami-0c55b159cbfafe1f0"  # Actualiza con AMI correcta para us-west-2
  }
}

# VPC Configuration
variable "vpc_cidr_blocks" {
  description = "Map of VPC CIDR blocks for different regions"
  type        = map(string)
  default = {
    us-east-1 = "10.0.0.0/16"
    us-west-2 = "10.1.0.0/16"
  }
}
