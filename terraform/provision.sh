#!/bin/bash

# Set environment variables from template with defaults
db_username=${db_username:-dbadmin}
db_password=${db_password:-default_db_password}
db_name=${db_name:-orderdb}
redis_user=${redis_user:-default}
redis_pass=${redis_pass:-default_redis_pass}
mongo_uri=${mongo_uri:-mongodb://localhost:27017/}

# Set RabbitMQ defaults if not provided
export RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER:-rabbit}
export RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-rabbitpass}

# Set other required environment variables with defaults
export NODE_ENV=production

# Update the system and install required packages
yum update -y
yum install -y \
    curl \
    wget \
    unzip \
    git \
    nginx \
    jq \
    amazon-cloudwatch-agent

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/order-processing
cd /opt/order-processing

# Create environment file for containers
cat > .env << EOL
# Database Configuration
POSTGRES_USER=${db_username}
POSTGRES_PASSWORD=${db_password}
POSTGRES_DB=${db_name}

# Redis Configuration
REDIS_USER=${redis_user}
REDIS_PASS=${redis_pass}

# MongoDB Configuration
MONGO_URI=${mongo_uri}

# Application Configuration
NODE_ENV=production
PORT=8080

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672

# Service URLs
ORDER_SERVICE_URL=http://order-service:8080
SUBTOTAL_SERVICE_URL=http://subtotal-service:8080
DISCOUNT_SERVICE_URL=http://discount-service:8080
TOTAL_SERVICE_URL=http://total-service:8080
NOTIFICATION_SERVICE_URL=http://notification-service:8080
EOL

# Create docker-compose.yml
cat > docker-compose.yml << 'EOL'
version: '3.8'

services:
  # Message Broker
  rabbitmq:
    image: rabbitmq:3-management
    container_name: rabbitmq
    ports:
      - "5672:5672"  # AMQP
      - "15672:15672"  # Management UI
    environment:
      - RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS}
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "check_running"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network

  # Monitoring
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    depends_on:
      - cadvisor
    restart: unless-stopped
    networks:
      - app-network

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    restart: unless-stopped
    networks:
      - app-network

  # API Gateway
  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/logs:/var/log/nginx
    depends_on:
      - order-service
    restart: unless-stopped
    networks:
      - app-network

  # Order Processing Services
  order-service:
    image: davcode22/order-service:latest
    container_name: order-service
    environment:
      - NODE_ENV=production
      - PORT=8080
      - RABBITMQ_URL=amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@rabbitmq:5672
      - MONGO_URI=${MONGO_URI}
    depends_on:
      rabbitmq:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - app-network

  subtotal-service:
    image: davcode22/subtotal-service:latest
    container_name: subtotal-service
    environment:
      - NODE_ENV=production
      - PORT=8080
      - RABBITMQ_URL=amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@rabbitmq:5672
    depends_on:
      - rabbitmq
    restart: unless-stopped
    networks:
      - app-network

  discount-service:
    image: davcode22/discount-service:latest
    container_name: discount-service
    environment:
      - NODE_ENV=production
      - PORT=8080
      - RABBITMQ_URL=amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@rabbitmq:5672
      - REDIS_URL=redis://${REDIS_USER}:${REDIS_PASS}@redis:6379
    depends_on:
      - rabbitmq
      - redis
    restart: unless-stopped
    networks:
      - app-network

  total-service:
    image: davcode22/total-service:latest
    container_name: total-service
    environment:
      - NODE_ENV=production
      - PORT=8080
      - RABBITMQ_URL=amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@rabbitmq:5672
    depends_on:
      - rabbitmq
    restart: unless-stopped
    networks:
      - app-network

  notification-service:
    image: davcode22/notification-service:latest
    container_name: notification-service
    environment:
      - NODE_ENV=production
      - PORT=8080
      - RABBITMQ_URL=amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@rabbitmq:5672
      - SMTP_HOST=smtp.example.com
      - SMTP_PORT=587
      - SMTP_USER=user@example.com
      - SMTP_PASS=your-smtp-password
    depends_on:
      - rabbitmq
    restart: unless-stopped
    networks:
      - app-network

  # Redis Cache
  redis:
    image: redis:alpine
    container_name: redis
    command: redis-server --requirepass ${REDIS_PASS}
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  prometheus_data:
  redis_data:
EOL

# Create directories for configuration files
mkdir -p /opt/order-processing/nginx/conf.d
mkdir -p /opt/order-processing/nginx/logs
mkdir -p /opt/order-processing/prometheus

# Create Prometheus configuration
cat > prometheus.yml << 'EOL'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - 'alert.rules'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'rabbitmq'
    metrics_path: '/api/metrics'
    static_configs:
      - targets: ['rabbitmq:15672']
    basic_auth:
      username: '${RABBITMQ_DEFAULT_USER}'
      password: '${RABBITMQ_DEFAULT_PASS}'

  - job_name: 'node'
    static_configs:
      - targets: ['order-service:9100', 'subtotal-service:9100', 
                 'discount-service:9100', 'total-service:9100', 
                 'notification-service:9100']

  - job_name: 'application'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['order-service:8080', 'subtotal-service:8080', 
                 'discount-service:8080', 'total-service:8080', 
                 'notification-service:8080']
EOL

# Create Nginx configuration
cat > nginx/conf.d/default.conf << 'EOL'
upstream order_service {
    server order-service:8080;
}

server {
    listen 80;
    server_name _;

    # Health check endpoint
    location /health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 "OK\n";
    }

    # API Gateway routes
    location /api/orders/ {
        proxy_pass http://order-service:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Default route
    location / {
        return 404 '{"status":"error","message":"Not Found"}';
    }
}
EOL

# Set proper permissions
chmod 644 /opt/order-processing/nginx/conf.d/default.conf
chmod 644 /opt/order-processing/prometheus.yml
chmod 755 /opt/order-processing

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent.json << 'EOL'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "metrics": {
        "metrics_collected": {
            "docker": {
                "measurement": [
                    "container_cpu",
                    "container_memory",
                    "container_network"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": true
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOL

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent.json

# Pull all Docker images
echo "Pulling Docker images..."
docker-compose pull

# Start all services
echo "Starting services..."
docker-compose up -d

# Create systemd service for auto-start
cat > /etc/systemd/system/order-processing.service << 'EOL'
[Unit]
Description=Order Processing System
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/order-processing
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOL

# Enable and start the service
systemctl enable order-processing.service
systemctl start order-processing.service

# Print completion message
echo ""
echo "========================================"
echo "  Order Processing System Setup Complete  "
echo "========================================"
echo ""
echo "Services are starting up. This may take a few minutes for all services to be fully operational."
echo ""
echo "Access the following services:"
echo "- Application: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "- RabbitMQ Management: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):15672"
echo "- Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo "- cAdvisor: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "To view logs, run: docker-compose logs -f"
echo ""

# Install and configure CloudWatch Logs agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch Logs configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOL'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/opt/order-processing/nginx/logs/*.log",
                        "log_group_name": "/ec2/order-processing/nginx",
                        "log_stream_name": "{instance_id}",
                        "retention_in_days": 7
                    },
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/ec2/order-processing/system",
                        "log_stream_name": "{instance_id}",
                        "retention_in_days": 7
                    }
                ]
            }
        }
    }
}
EOL

# Start CloudWatch Logs Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Install and configure AWS CLI for better AWS integration
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install SSM Agent for Session Manager access
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install CloudWatch Logs agent for container logs
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch agent configuration for container logs
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat > /opt/aws/amazon-cloudwatch-agent/etc/container-logs.json << 'EOL'
{
    "logs": {
        "logs_collected": {
            "docker": {
                "metrics_collected": {
                    "docker": {
                        "measurement": [
                            "container_cpu",
                            "container_memory",
                            "container_network"
                        ]
                    }
                },
                "log_configuration": {
                    "log_driver": "awslogs",
                    "options": {
                        "awslogs-group": "/ecs/order-processing",
                        "awslogs-region": "${aws_region}",
                        "awslogs-stream-prefix": "ecs"
                    }
                },
                "run_as_root": true
            }
        },
        "log_stream_name": "{instance_id}"
    }
}
EOL

# Start CloudWatch agent for container logs
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/container-logs.json

# Install and configure logrotate for application logs
cat > /etc/logrotate.d/order-processing << 'EOL'
/opt/order-processing/nginx/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 nginx nginx
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
EOL

echo "Provisioning completed successfully!"
echo "All services are being started in the background."
echo "Run 'docker ps' to check the status of the containers."
