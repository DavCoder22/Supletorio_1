# 🧩 Final Project — Distributed Infrastructure for Order Processing

This project implements a **modular and scalable distributed infrastructure** aimed at online order systems, using **event-based communication with RabbitMQ**, full monitoring with **Prometheus and cAdvisor**, and automated deployment on **AWS EC2 using Terraform**. The microservices are orchestrated with **Docker Compose** and served through an **API Gateway implemented with NGINX**. All images are published on Docker Hub.

---

## ✅ Academic Objectives

- Design and implement a **lightweight, modular, and scalable distributed infrastructure**.
- Apply modern architecture practices: **KISS, POLA, YAGNI**.
- Deploy infrastructure with **Infrastructure as Code (IaC)** using **Terraform**.
- Implement an **event-driven architecture (EDA)** with RabbitMQ.
- Integrate monitoring of network, storage, virtualization, and containers with Prometheus and cAdvisor.
- Automate deployment on **AWS EC2**.
- Simulate API Gateway with **NGINX** as a reverse proxy.

---

## 🧱 General Architecture

```plaintext
                     ┌───────────────────┐
                     │     Client        │
                     └────────┬──────────┘
                              │
                          HTTP POST
                              │
                        ┌────▼────┐
                        │ NGINX   │  ← API Gateway (Reverse Proxy)
                        └────┬────┘
           ┌────────────────┴────────────┐
           │        Docker Network       │
           │                             │
┌──────────▼──────────┐     ┌────────────▼───────────┐
│    order-service    │───▶│   subtotal-service      │
└─────────▲───────────┘     └────────────▲───────────┘
          │                              │
          │                              │
          ▼                              ▼
┌──────────────┐                  ┌──────────────┐
│ discount-service │◀────────────│  total-service│
└──────────────┘                  └──────────────┘
                                       │
                                       ▼
                             ┌────────────────────┐
                             │ notification-service│
                             └────────────────────┘
```

---

## 📦 Microservices (modular and with SRP)

| Service                | Function                                                                |
|------------------------|-------------------------------------------------------------------------|
| `order-service`        | Receives orders, validates, and publishes `order_created` event          |
| `subtotal-service`     | Calculates the order subtotal                                            |
| `discount-service`     | Applies discounts according to conditions                                |
| `total-service`        | Adds subtotal + taxes + shipping                                         |
| `notification-service` | Notifies the client with order details                                   |

All microservices are implemented under the **KISS** and **SRP** pattern, with images on Docker Hub and independent configurations.

---

## 🔄 Event-Driven Communication (EDA)

- **RabbitMQ** is used as the messaging middleware.
- Each microservice communicates **asynchronously**.
- Events travel between services without direct coupling.

---

## 📬 Messaging with RabbitMQ

- Official image: `rabbitmq:3-management`
- Dashboard access: `http://<EC2_PUBLIC_IP>:15672`
- User: `guest`, Password: `guest`
- Queues used:
  - `order_created`
  - `subtotal_ready`
  - `discount_ready`
  - `total_ready`

---

## 🌐 API Gateway with NGINX

- Implemented as a **reverse proxy**.
- Centralizes requests to microservices.
- Base image: `nginx:alpine`
- Exposes `order-service` publicly at the `/create-order` endpoint.

---

## 📊 Monitoring and Observability

| Element                | Implemented Solution                |
|------------------------|-------------------------------------|
| Microservices          | Expose `/metrics` for Prometheus    |
| Docker Containers      | Monitored with `cAdvisor`           |
| Storage/Disk           | Exposed by Prometheus + cAdvisor    |
| Network                | Prometheus measures latency         |
| Metrics Visualization  | Access via Prometheus at `http://<EC2_PUBLIC_IP>:9090` |

---

## 🔐 Security and Modularity (POLA + YAGNI)

- NGINX as the only public entry point (Principle of Least Astonishment).
- Only strictly necessary features are implemented: no databases, no unnecessary logic (YAGNI).
- Each container fulfills a single responsibility (SRP + KISS).

---

## ☁️ Deployment on AWS EC2 with Terraform

### Key Files:

- `main.tf` – Creates EC2 instance (Ubuntu 22.04)
- `variables.tf` – Reusable variables
- `provision.sh` – Installs Docker, NGINX, and launches services
- `docker-compose.yml` – Orchestrates all services

### Requirements:

- SSH key in `~/.ssh/id_rsa.pub`
- AWS permissions configured (`aws configure`)
- Terraform installed

### Deployment Steps:

```bash
cd terraform
terraform init
terraform apply
```

Once deployed, access:
- `http://<EC2_PUBLIC_IP>/create-order` (public entry)
- `http://<EC2_PUBLIC_IP>:15672` (RabbitMQ UI)
- `http://<EC2_PUBLIC_IP>:9090` (Prometheus UI)

---

## 🐳 Docker Images Used

| Service                | Docker Hub Image                              |
|------------------------|-----------------------------------------------|
| RabbitMQ               | `rabbitmq:3-management`                       |
| Prometheus             | `prom/prometheus`                             |
| cAdvisor               | `gcr.io/cadvisor/cadvisor`                    |
| NGINX Gateway          | `nginx:alpine`                                |
| order-service          | `davcode22/order-service:latest`       |
| subtotal-service       | `davcode22/subtotal-service:latest`    |
| discount-service       | `davcode22/discount-service:latest`    |
| total-service          | `davcode22/total-service:latest`       |
| notification-service   | `davcode22/notification-service:latest`|

---

## 🧪 System Test

1. Make a `POST` request to `/create-order` with an order JSON:
   ```json
   {
     "order_id": "123",
     "items": [
       { "name": "Mouse", "price": 10, "qty": 2 },
       { "name": "Teclado", "price": 15, "qty": 1 }
     ]
   }
   ```
2. A chain of events is triggered:
   - `order_created` → `subtotal_calculated` → `discount_applied` → `total_calculated`
3. The `notification-service` processes the final total.
4. Observe metrics in Prometheus and logs via `docker logs`.

---

## 📁 Repository Structure

```plaintext
proyecto-pedidos-distribuido/
├── docker-compose.yml
├── prometheus.yml
├── nginx/
│   └── default.conf
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provision.sh
├── order-service/
├── subtotal-service/
├── discount-service/
├── total-service/
└── notification-service/
```

---

## 👨‍💻 Author

**Name**: David Malquin  
**Subject**: Distributed Programming  
**Institution**: Universida Central del Ecuador
**Date**: 04 August 2025  

---

## 📌 Additional Notes

- Kubernetes (EKS) was not used due to educational plan restrictions.
- Kafka was replaced by RabbitMQ.
- Amazon SNS/SQS are integrable but were not used in this version to keep the focus modular and fast.
- Images are available on Docker Hub under the user `davcode22`.

---

## Postman Test Requests

You can use the following sample requests in Postman to test your deployed microservices. Replace `<EC2_PUBLIC_IP>` with the public IP of your EC2 instance.

### Example: Order Service (port 3000)

**Get all orders**
```
GET http://<EC2_PUBLIC_IP>:3000/api/orders
```

**Create a new order**
```
POST http://<EC2_PUBLIC_IP>:3000/api/orders
Body (JSON):
{
  "item": "product_name",
  "quantity": 2
}
```

### Example: User Service (port 80)

**Get all users**
```
GET http://<EC2_PUBLIC_IP>/api/users
```

**Create a new user**
```
POST http://<EC2_PUBLIC_IP>/api/users
Body (JSON):
{
  "name": "John Doe",
  "email": "john@example.com"
}
```

> **Note:** Make sure your `docker-compose.yml` exposes the correct ports and endpoints for each service.