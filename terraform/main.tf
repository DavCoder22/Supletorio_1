provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token     = var.aws_session_token
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  default     = ""
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "my_ip" {
  description = "Tu IP pública para acceso seguro"
  default     = "<TU_IP_PUBLICA>/32"
}

# Usando el par de claves existente 'pc1' en AWS
# No es necesario crear un nuevo par de claves ya que usaremos el existente

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Permite solo SSH y puertos de app desde tu IP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Order Service"
    from_port   = 3000
    to_port     = 3004
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RabbitMQ"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RabbitMQ UI"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Módulo para la región primaria (us-east-1)
module "primary_region" {
  source = "./modules/region"
  
  region    = "us-east-1"
  vpc_cidr  = "10.0.0.0/16"
  key_name  = "pc1"
  ami_id    = "ami-08a6efd148b1f7504"  # AMI para us-east-1
  
  aws_access_key     = var.aws_access_key
  aws_secret_key     = var.aws_secret_key
  aws_session_token  = var.aws_session_token
  
  database_credentials = {
    redis_user     = var.redis_user
    redis_password = var.redis_password
    postgres_user  = var.postgres_user
    postgres_pass  = var.postgres_password
    postgres_db    = var.postgres_db
    mongo_user     = var.mongo_user
    mongo_pass     = var.mongo_password
  }
}

# Módulo para la región secundaria (us-west-2)
module "secondary_region" {
  source = "./modules/region"
  
  region    = "us-west-2"
  vpc_cidr  = "10.1.0.0/16"
  key_name  = "pc1"
  ami_id    = "ami-0c55b159cbfafe1f0"  # AMI para us-west-2 (actualízala según sea necesario)
  
  providers = {
    aws = aws.us_west_2
  }
  
  aws_access_key     = var.aws_access_key
  aws_secret_key     = var.aws_secret_key
  aws_session_token  = var.aws_session_token
  
  database_credentials = {
    redis_user     = var.redis_user
    redis_password = var.redis_password
    postgres_user  = var.postgres_user
    postgres_pass  = var.postgres_password
    postgres_db    = var.postgres_db
    mongo_user     = var.mongo_user
    mongo_pass     = var.mongo_password
  }
}

# Configuración de Route 53 para balanceo de carga entre regiones
resource "aws_route53_zone" "primary" {
  name = "example.com"  # Reemplaza con tu dominio
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "app.example.com"
  type    = "CNAME"
  ttl     = "300"
  
  # Punto de entrada principal a la región primaria
  records = [module.primary_region.alb_dns_name]
  
  # Configuración de failover a la región secundaria
  set_identifier = "primary"
  
  # Health check para el failover
  health_check_id = aws_route53_health_check.primary_region_health_check.id
  
  # Latency-based routing
  latency_routing_policy {
    region = "us-east-1"
  }
}

# Health check para la región primaria
resource "aws_route53_health_check" "primary_region_health_check" {
  fqdn              = module.primary_region.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"
  
  tags = {
    Name = "primary-region-health-check"
  }
}

# Outputs para facilitar la gestión
data "aws_region" "current" {}

output "primary_region_alb_dns" {
  description = "DNS del ALB en la región primaria (us-east-1)"
  value       = module.primary_region.alb_dns_name
}

output "secondary_region_alb_dns" {
  description = "DNS del ALB en la región secundaria (us-west-2)"
  value       = module.secondary_region.alb_dns_name
}

output "current_region" {
  description = "Región actual donde se está ejecutando Terraform"
  value       = data.aws_region.current.name
}
