#!/bin/bash

# Source the .env file if it exists
if [ -f "../.env" ]; then
    export $(grep -v '^#' ../.env | xargs)
fi

# Generate terraform.tfvars
cat > terraform.tfvars <<EOL
# AWS Configuration
aws_region = "${AWS_REGION:-us-east-1}"

# Database Configuration
db_username = "${DB_USERNAME:-dbadmin}"
db_password = "${DB_PASSWORD:-default_db_password}"
db_name     = "${DB_NAME:-orderdb}"

# MongoDB Configuration
mongo_username = "${MONGO_USERNAME:-mongoadmin}"
mongo_password = "${MONGO_PASSWORD:-default_mongo_password}"

# Redis Configuration
redis_user = "${REDIS_USER:-default}"
redis_pass = "${REDIS_PASS:-default_redis_password}"

# Auto Scaling Configuration
desired_capacity = ${DESIRED_CAPACITY:-2}
min_size         = ${MIN_SIZE:-1}
max_size         = ${MAX_SIZE:-4}

# Instance Configuration
instance_type = "${INSTANCE_TYPE:-t3.medium}"
EOL

echo "terraform.tfvars has been generated with environment variables"
