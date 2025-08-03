const mongoose = require('mongoose');

const orderHistorySchema = new mongoose.Schema({
  order_id: { type: String, required: true },
  items: { type: Array, required: true },
  subtotal: Number,
  discount: Number,
  total: Number,
  created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('OrderHistory', orderHistorySchema);
