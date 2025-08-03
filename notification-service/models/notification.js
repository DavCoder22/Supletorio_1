// Este es un ejemplo de función para guardar notificaciones en Redis usando ioredis
const Redis = require('ioredis');
const redis = new Redis({
  host: process.env.REDIS_HOST || 'redis',
  port: 6379,
  password: process.env.REDIS_PASSWORD || 'Sebasalejandro22'
});

async function saveNotification(orderId, data) {
  await redis.set(`notification:${orderId}`, JSON.stringify(data));
}

module.exports = { saveNotification };
