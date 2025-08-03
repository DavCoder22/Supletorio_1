#!/bin/bash
# Script para inicializar las colas de RabbitMQ

# Esperar a que RabbitMQ esté listo
until rabbitmqadmin -u "$RABBITMQ_DEFAULT_USER" -p "$RABBITMQ_DEFAULT_PASS" list users; do
  echo "Esperando a que RabbitMQ esté listo..."
  sleep 5
done

# Crear colas
rabbitmqadmin -u "$RABBITMQ_DEFAULT_USER" -p "$RABBITMQ_DEFAULT_PASS" declare queue name=order_created durable=true
rabbitmqadmin -u "$RABBITMQ_DEFAULT_USER" -p "$RABBITMQ_DEFAULT_PASS" declare queue name=subtotal_ready durable=true
rabbitmqadmin -u "$RABBITMQ_DEFAULT_USER" -p "$RABBITMQ_DEFAULT_PASS" declare queue name=discount_ready durable=true
rabbitmqadmin -u "$RABBITMQ_DEFAULT_USER" -p "$RABBITMQ_DEFAULT_PASS" declare queue name=total_ready durable=true

echo "Colas de RabbitMQ inicializadas correctamente"
