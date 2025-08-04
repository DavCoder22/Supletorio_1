# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "order-processing-vpc"
  }
}

# Create subnets in different AZs for high availability
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = "${var.aws_region}${var.azs[count.index % length(var.azs)]}"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "order-processing-igw"
  }
}

# Create route table for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "public_rta" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Security group for load balancer
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "alb-security-group"
  }
}

# Security group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access from anywhere (restrict in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP access from the load balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow traffic between microservices (3000-3004)
  ingress {
    from_port   = 3000
    to_port     = 3004
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow traffic between microservices"
  }

  # Allow MongoDB access (27017)
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow MongoDB access"
  }

  # Allow PostgreSQL access (5432)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow PostgreSQL access"
  }

  # Allow Redis access (6379)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow Redis access"
  }

  # Allow RabbitMQ access (5672, 15672)
  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow RabbitMQ AMQP access"
  }

  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow RabbitMQ management UI access"
  }

  # Allow RabbitMQ ports
  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # Allow RabbitMQ Management UI
  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict in production
  }

  # Allow Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict in production
  }

  # Allow cAdvisor
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict in production
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# Create a key pair for SSH access
resource "aws_key_pair" "deployer" {
  key_name   = "pc1-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMWq6iS6CYpAUPmLbbT/KVudlkmoPL6t5EFZt9jTiZJSRsqpeOK/euk6lVH3Iskn0pGZTs2Vn3gAnlaUBY/O2aYR2d25ZR3UoZgch74ixdOaHSeHJXEcEn7vQMbchBcFGQ22NZspLeuUYjLldYDK667is/tz4hlIe59z+TUkUg9tLk6ILeZ3Q8KaqGUl/RxT1PPpYa+7uGSjFxF+yxk+ToC0Mv23YAPXc6YAC2dp8G5c1pWSearasZNotxEBvNpe0vvnQpzKNypCL0MDrpwavC6RCbuCv2wcRI21XU7PSKtPKhi0HLneBB5Iua2egmcc18t5AlMSgRy7KVe0EUMRNj"
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "order-processing-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# Target group for the ALB
resource "aws_lb_target_group" "app_tg" {
  name     = "order-processing-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Launch Template for EC2 instances
resource "aws_launch_template" "app_lt" {
  name_prefix   = "order-processing-lt"
  image_id      = "ami-08a6efd148b1f7504"  # Amazon Linux 2 AMI
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name
  user_data = base64encode(<<-EOT
    #!/bin/bash
    # Set environment variables from template with defaults
    db_username='${var.db_username}'
    db_password='${replace(var.db_password, "'", "'\\''")}'
    db_name='${var.db_name}'
    redis_user='${var.redis_user}'
    redis_pass='${replace(var.redis_pass, "'", "'\\''")}'
    mongo_uri='${replace(var.mongo_uri, "'", "'\\''")}'
    
    # Set RabbitMQ defaults if not provided
    export RABBITMQ_DEFAULT_USER='${var.rabbitmq_user}'
    export RABBITMQ_DEFAULT_PASS='${replace(var.rabbitmq_pass, "'", "'\\''")}'
    
    # Set other required environment variables with defaults
    export NODE_ENV=production
    
    # The rest of the script follows...
    ${file("provision.sh")}
  EOT
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "order-processing-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                 = "order-processing-asg"
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = aws_subnet.public_subnets[*].id
  target_group_arns    = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "order-processing-instance"
    propagate_at_launch = true
  }
}

# Crear IP elástica para MongoDB
resource "aws_eip" "mongodb_eip" {
  domain = "vpc"
  tags = {
    Name = "mongodb-eip"
  }
}

# Asociar la IP elástica a la instancia MongoDB
resource "aws_eip_association" "mongodb_eip_assoc" {
  instance_id   = aws_instance.mongodb.id
  allocation_id = aws_eip.mongodb_eip.id
}

# Database instance (MongoDB)
resource "aws_instance" "mongodb" {
  ami                    = "ami-08a6efd148b1f7504"  # Amazon Linux 2 AMI
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  
  # Ensure EIP is created first
  depends_on = [aws_eip.mongodb_eip]
  
  root_block_device {
    volume_size = 50  # 50GB root volume for database
    volume_type = "gp2"
  }

  tags = {
    Name = "mongodb-instance"
  }
  
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              echo "[mongodb-org-6.0]" | sudo tee /etc/yum.repos.d/mongodb-org-6.0.repo
              echo "name=MongoDB Repository" | sudo tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
              echo "baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/" | sudo tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
              echo "gpgcheck=1" | sudo tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
              echo "enabled=1" | sudo tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
              echo "gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc" | sudo tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
              sudo yum install -y mongodb-org
              sudo systemctl start mongod
              sudo systemctl enable mongod
              
              # Create MongoDB user
              mongo admin --eval 'db.createUser({user: "${var.mongo_username}", pwd: "${var.mongo_password}", roles: ["root"]})'
              EOF
}

# Redis instance (ElastiCache would be better for production)
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = aws_subnet.public_subnets[*].id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "order-processing-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.x"
  port                 = 6379
  security_group_ids   = [aws_security_group.ec2_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name

  tags = {
    Name = "redis-cache"
  }
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}
