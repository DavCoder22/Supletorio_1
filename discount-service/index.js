const amqp = require('amqplib');
const express = require('express');
const client = require('prom-client');

const SUBTOTAL_READY_QUEUE = 'subtotal_ready';
const DISCOUNT_READY_QUEUE = 'discount_ready';

const DISCOUNT_THRESHOLD = 100;
const DISCOUNT_RATE = 0.10; // 10%

const app = express();
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Procesa mensajes de RabbitMQ
async function start() {
  const conn = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://rabbitmq');
  const ch = await conn.createChannel();
  await ch.assertQueue(SUBTOTAL_READY_QUEUE, { durable: true });
  await ch.assertQueue(DISCOUNT_READY_QUEUE, { durable: true });

  ch.consume(SUBTOTAL_READY_QUEUE, async (msg) => {
    if (msg !== null) {
      try {
        const data = JSON.parse(msg.content.toString());
        const subtotal = data.subtotal || 0;
        let discount = 0;
        if (subtotal > DISCOUNT_THRESHOLD) {
          discount = subtotal * DISCOUNT_RATE;
        }
        const payload = {
          order_id: data.order_id,
          items: data.items,
          subtotal,
          discount: Number(discount.toFixed(2))
        };
        ch.sendToQueue(DISCOUNT_READY_QUEUE, Buffer.from(JSON.stringify(payload)), { persistent: true });
        ch.ack(msg);
      } catch (e) {
        ch.nack(msg, false, false);
      }
    }
  });
}

// /metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`discount-service listening on port ${PORT}`);
  start().catch(err => {
    console.error('RabbitMQ connection error:', err);
    process.exit(1);
  });
});
