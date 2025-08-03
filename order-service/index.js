const express = require('express');
const amqp = require('amqplib');
const client = require('prom-client');

const app = express();
app.use(express.json());

const ORDER_CREATED_QUEUE = 'order_created';

// Prometheus metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// POST /create-order
app.post('/create-order', async (req, res) => {
  const order = req.body;
  if (!order || !order.order_id || !order.items) {
    return res.status(400).json({ error: 'Invalid order format' });
  }
  try {
    const conn = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://rabbitmq');
    const ch = await conn.createChannel();
    await ch.assertQueue(ORDER_CREATED_QUEUE, { durable: true });
    ch.sendToQueue(ORDER_CREATED_QUEUE, Buffer.from(JSON.stringify(order)), { persistent: true });
    await ch.close();
    await conn.close();
    res.status(201).json({ status: 'Order created', order_id: order.order_id });
  } catch (err) {
    res.status(500).json({ error: 'Failed to publish order' });
  }
});

// /metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`order-service listening on port ${PORT}`);
});
