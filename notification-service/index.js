const amqp = require('amqplib');
const express = require('express');
const client = require('prom-client');

const TOTAL_READY_QUEUE = 'total_ready';

const app = express();
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Procesa mensajes de RabbitMQ
async function start() {
  try {
    const conn = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://rabbitmq');
    const ch = await conn.createChannel();
    await ch.assertQueue(TOTAL_READY_QUEUE, { durable: true });

    ch.consume(TOTAL_READY_QUEUE, async (msg) => {
      if (msg !== null) {
        try {
          const data = JSON.parse(msg.content.toString());
          // Simula el envío de notificación (puedes reemplazar por email, SMS, etc.)
          console.log(
            `Notification sent for order ${data.order_id}: Total = $${data.total}`
          );
          ch.ack(msg);
        } catch (e) {
          console.error('Error processing message:', e);
          ch.nack(msg, false, false);
        }
      }
    });
  } catch (err) {
    console.error('RabbitMQ connection error:', err);
    process.exit(1);
  }
}

// /metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`notification-service listening on port ${PORT}`);
  start().catch(err => {
    console.error('RabbitMQ connection error:', err);
    process.exit(1);
  });
});

process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
});
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
});
