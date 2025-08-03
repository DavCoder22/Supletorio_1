const amqp = require('amqplib');
const express = require('express');
const client = require('prom-client');

const ORDER_CREATED_QUEUE = 'order_created';
const SUBTOTAL_READY_QUEUE = 'subtotal_ready';

const app = express();
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Procesa mensajes de RabbitMQ
async function start() {
  try {
    const conn = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://rabbitmq');
    const ch = await conn.createChannel();
    await ch.assertQueue(ORDER_CREATED_QUEUE, { durable: true });
    await ch.assertQueue(SUBTOTAL_READY_QUEUE, { durable: true });

    ch.consume(ORDER_CREATED_QUEUE, async (msg) => {
      if (msg !== null) {
        try {
          const order = JSON.parse(msg.content.toString());
          const subtotal = (order.items || []).reduce(
            (sum, item) => sum + (item.price * item.qty), 0
          );
          const payload = {
            order_id: order.order_id,
            items: order.items,
            subtotal
          };
          ch.sendToQueue(SUBTOTAL_READY_QUEUE, Buffer.from(JSON.stringify(payload)), { persistent: true });
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
  console.log(`subtotal-service listening on port ${PORT}`);
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
