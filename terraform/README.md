# Order Processing System - Terraform Configuration

This directory contains the Terraform configuration for deploying the Order Processing System to AWS.

## Prerequisites

1. **AWS CLI** installed and configured with appropriate credentials
2. **Terraform** (v1.0.0 or later) installed
3. **SSH key pair** in `~/.ssh/id_rsa` (private key) and `~/.ssh/id_rsa.pub` (public key)
4. **Docker** installed (for local development and testing)

## Directory Structure

```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output values
├── provision.sh         # Provisioning script for EC2 instance
└── README.md            # This file
```

## Deployment Steps

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the execution plan

```bash
terraform plan
```

### 3. Apply the configuration

```bash
terraform apply
```

When prompted, confirm the action by typing `yes`.

## Accessing the Application

After successful deployment, you can access the following services:

- **Order Processing API**: `http://<EC2_PUBLIC_IP>/create-order`
- **RabbitMQ Management**: `http://<EC2_PUBLIC_IP>:15672` (username: `guest`, password: `guest`)
- **Prometheus**: `http://<EC2_PUBLIC_IP>:9090`
- **cAdvisor**: `http://<EC2_PUBLIC_IP>:8080`

You can find the public IP address in the Terraform outputs after deployment.

## Testing the Application

Send a POST request to the API endpoint:

```bash
curl -X POST http://<EC2_PUBLIC_IP>/create-order \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "123",
    "items": [
      { "name": "Product 1", "price": 10.99, "qty": 2 },
      { "name": "Product 2", "price": 25.50, "qty": 1 }
    ]
  }'
```

## Monitoring

- **Prometheus** is configured to scrape metrics from all services
- **cAdvisor** provides container resource usage and performance metrics
- **RabbitMQ** management interface provides queue and message statistics

## Cleanup

To destroy all resources created by Terraform:

```bash
terraform destroy
```

## Troubleshooting

### SSH Access

To SSH into the EC2 instance:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>
```

### Viewing Logs

Once connected to the instance, you can view logs for the services:

```bash
# View Docker containers
sudo docker ps

# View logs for a specific service
sudo docker logs <container_name>

# View logs with follow
sudo docker logs -f <container_name>
```

### Common Issues

1. **Port conflicts**: Ensure ports 80, 443, 15672, 9090, and 8080 are open in the security group
2. **Docker permission denied**: Run `sudo usermod -aG docker $USER` and log out/log in
3. **Terraform state issues**: If you encounter state issues, try `terraform refresh`

## Security Notes

- This configuration is for demonstration purposes
- In production, you should:
  - Restrict SSH access to specific IP addresses
  - Use HTTPS with valid certificates
  - Implement proper authentication for all services
  - Store sensitive information in a secure secret manager
  - Use a proper CI/CD pipeline for deployments
