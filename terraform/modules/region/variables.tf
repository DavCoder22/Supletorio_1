variable "region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
  default     = "production"
}

variable "key_name" {
  description = "Name of the key pair to use for EC2 instances"
  type        = string
  default     = "pc1"
}

variable "ami_id" {
  description = "AMI ID to use for EC2 instances"
  type        = string
}

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

variable "database_credentials" {
  description = "Credentials for databases"
  type = object({
    redis_user     = string
    redis_password = string
    postgres_user  = string
    postgres_pass  = string
    postgres_db    = string
    mongo_user     = string
    mongo_pass     = string
  })
  sensitive = true
}
