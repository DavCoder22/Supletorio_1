# Configuración del proveedor para la región específica
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
}

# Crear VPC para la región
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "vpc-${var.region}-${var.environment}"
  }
}

# Subredes públicas
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = "${var.region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "subnet-public-${var.region}-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "igw-${var.region}"
  }
}

# Tabla de rutas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "rt-public-${var.region}"
  }
}

# Asociar tabla de rutas con subredes públicas
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group para instancias EC2
resource "aws_security_group" "web_sg" {
  name        = "web-sg-${var.region}"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  # Reglas de entrada
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Reglas de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg-${var.region}"
  }
}

# Security Group para ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.region}"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg-${var.region}"
  }
}

# IAM Role para instancias EC2
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ec2-role-${var.region}"
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-${var.region}"
  role = aws_iam_role.ec2_role.name
}

# Launch Template para el Auto Scaling Group
resource "aws_launch_template" "docker_lt" {
  name_prefix   = "docker-lt-${var.region}-"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 16
      volume_type = "gp2"
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    region              = var.region
    redis_user         = var.database_credentials.redis_user
    redis_password     = var.database_credentials.redis_password
    postgres_user      = var.database_credentials.postgres_user
    postgres_pass      = var.database_credentials.postgres_pass
    postgres_db        = var.database_credentials.postgres_db
    mongo_user         = var.database_credentials.mongo_user
    mongo_pass         = var.database_credentials.mongo_pass
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "docker-host-${var.region}"
    }
  }
}

# Target Group para el ALB
resource "aws_lb_target_group" "docker_tg" {
  name        = "docker-tg-${var.region}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
}

# Application Load Balancer
resource "aws_lb" "docker_alb" {
  name               = "docker-alb-${var.region}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
    Region      = var.region
  }
}

# Listener para el ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.docker_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.docker_tg.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "docker_asg" {
  name_prefix          = "docker-asg-${var.region}-"
  vpc_zone_identifier  = aws_subnet.public[*].id
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.docker_tg.arn]
  
  launch_template {
    id      = aws_launch_template.docker_lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["desired_capacity"]
  }

  tag {
    key                 = "Name"
    value               = "docker-host-${var.region}"
    propagate_at_launch = true
  }
}

# Volumen EBS para datos de la aplicación
resource "aws_ebs_volume" "app_data" {
  availability_zone = "${var.region}a"
  size             = 20
  type             = "gp2"
  encrypted        = true

  tags = {
    Name = "app-data-${var.region}"
  }
}

# Outputs
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
