#!/bin/bash

# Actualizar el sistema
apt-get update
apt-get upgrade -y

# Instalar paquetes necesarios
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    jq \
    awscli

# Instalar Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configurar el usuario ubuntu para usar Docker sin sudo
usermod -aG docker ubuntu

# Crear directorio de la aplicación
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Crear archivo .env con las variables de entorno
cat > .env << EOL
# AWS
AWS_ACCESS_KEY_ID=${aws_access_key}
AWS_SECRET_ACCESS_KEY=${aws_secret_key}
AWS_SESSION_TOKEN=${aws_session_token}
AWS_REGION=${region}

# Redis
REDIS_USER=${redis_user}
REDIS_PASSWORD=${redis_password}

# PostgreSQL
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_pass}
POSTGRES_DB=${postgres_db}

# MongoDB
MONGO_INITDB_ROOT_USERNAME=${mongo_user}
MONGO_INITDB_ROOT_PASSWORD=${mongo_pass}

# RabbitMQ
RABBITMQ_DEFAULT_USER=rabbituser
RABBITMQ_DEFAULT_PASS=rabbitpass
EOL

# Clonar el repositorio (si es necesario)
if [ ! -d /home/ubuntu/app/.git ]; then
    git clone https://github.com/DavCoder22/Supletorio_1.git /tmp/app
    cp -r /tmp/app/* /home/ubuntu/app/
    cp /tmp/app/.env.example /home/ubuntu/app/
    rm -rf /tmp/app
fi

# Dar permisos al usuario ubuntu
chown -R ubuntu:ubuntu /home/ubuntu/app

# Iniciar los contenedores
docker-compose -f /home/ubuntu/app/docker-compose.yml up -d

# Configurar el arranque automático
systemctl enable docker
