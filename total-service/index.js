const amqp = require('amqplib');
const express = require('express');
const client = require('prom-client');

const DISCOUNT_READY_QUEUE = 'discount_ready';
const TOTAL_READY_QUEUE = 'total_ready';

const TAX_RATE = 0.12; // 12% tax
const SHIPPING_COST = 5; // $5 fixed shipping

const app = express();
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Procesa mensajes de RabbitMQ
async function start() {
  const conn = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://rabbitmq');
  const ch = await conn.createChannel();
  await ch.assertQueue(DISCOUNT_READY_QUEUE, { durable: true });
  await ch.assertQueue(TOTAL_READY_QUEUE, { durable: true });

  ch.consume(DISCOUNT_READY_QUEUE, async (msg) => {
    if (msg !== null) {
      try {
        const data = JSON.parse(msg.content.toString());
        const subtotal = data.subtotal || 0;
        const discount = data.discount || 0;
        const taxed = (subtotal - discount) * (1 + TAX_RATE);
        const total = taxed + SHIPPING_COST;
        const payload = {
          order_id: data.order_id,
          items: data.items,
          subtotal,
          discount,
          total: Number(total.toFixed(2))
        };
        ch.sendToQueue(TOTAL_READY_QUEUE, Buffer.from(JSON.stringify(payload)), { persistent: true });
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
  console.log(`total-service listening on port ${PORT}`);
  start().catch(err => {
    console.error('RabbitMQ connection error:', err);
    process.exit(1);
  });
});
