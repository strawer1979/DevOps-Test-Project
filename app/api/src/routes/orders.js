import { Router } from 'express';
import { query, getClient } from '../db.js';
import redis from '../redis.js';
import { addOrderJob } from '../queue.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';

const router = Router();

const getCartKey = (userId) => `cart:${userId}`;

// POST /api/orders - Create order
router.post('/', asyncHandler(async (req, res) => {
  const { userId, items, shippingAddress, paymentMethod } = req.body;

  if (!userId) {
    throw new AppError('User ID is required', 400);
  }

  if (!items || !Array.isArray(items) || items.length === 0) {
    // If no items provided, get from cart
    const cartKey = getCartKey(userId);
    const cartData = await redis.hgetall(cartKey);

    if (!cartData || Object.keys(cartData).length === 0) {
      throw new AppError('Cart is empty', 400);
    }

    // Get product details and validate
    const orderItems = [];
    let totalAmount = 0;

    for (const [productId, quantity] of Object.entries(cartData)) {
      const result = await query(
        'SELECT id, name, price, stock FROM products WHERE id = $1 FOR UPDATE',
        [productId]
      );

      if (result.rows.length === 0) {
        throw new AppError(`Product ${productId} not found`, 404);
      }

      const product = result.rows[0];
      const qty = Number(quantity);

      if (product.stock < qty) {
        throw new AppError(`Insufficient stock for ${product.name}`, 400);
      }

      orderItems.push({
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: qty,
        subtotal: product.price * qty,
      });

      totalAmount += product.price * qty;
    }

    // Create order in database using transaction
    const client = await getClient();

    try {
      await client.query('BEGIN');

      // Create order
      const orderResult = await client.query(
        `INSERT INTO orders (user_id, total_amount, status, shipping_address, payment_method, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         RETURNING id, user_id, total_amount, status, created_at`,
        [userId, totalAmount, 'pending', shippingAddress || null, paymentMethod || null]
      );

      const order = orderResult.rows[0];

      // Add order items
      for (const item of orderItems) {
        await client.query(
          `INSERT INTO order_items (order_id, product_id, quantity, price, subtotal)
           VALUES ($1, $2, $3, $4, $5)`,
          [order.id, item.productId, item.quantity, item.price, item.subtotal]
        );

        // Update stock
        await client.query(
          'UPDATE products SET stock = stock - $1 WHERE id = $2',
          [item.quantity, item.productId]
        );
      }

      await client.query('COMMIT');

      // Clear cart
      await redis.del(cartKey);

      // Add job to BullMQ queue
      await addOrderJob({
        orderId: order.id,
        userId,
        items: orderItems,
        totalAmount,
      });

      res.status(201).json({
        status: 'success',
        message: 'Order created successfully',
        data: {
          orderId: order.id,
          userId: order.user_id,
          totalAmount: order.total_amount,
          status: order.status,
          createdAt: order.created_at,
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } else {
    // Items provided directly (not from cart)
    if (!shippingAddress) {
      throw new AppError('Shipping address is required', 400);
    }

    const orderItems = [];
    let totalAmount = 0;

    const client = await getClient();

    try {
      await client.query('BEGIN');

      for (const item of items) {
        const { productId, quantity = 1 } = item;

        const result = await client.query(
          'SELECT id, name, price, stock FROM products WHERE id = $1 FOR UPDATE',
          [productId]
        );

        if (result.rows.length === 0) {
          throw new AppError(`Product ${productId} not found`, 404);
        }

        const product = result.rows[0];

        if (product.stock < quantity) {
          throw new AppError(`Insufficient stock for ${product.name}`, 400);
        }

        orderItems.push({
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity,
          subtotal: product.price * quantity,
        });

        totalAmount += product.price * quantity;

        // Update stock
        await client.query(
          'UPDATE products SET stock = stock - $1 WHERE id = $2',
          [quantity, productId]
        );
      }

      // Create order
      const orderResult = await client.query(
        `INSERT INTO orders (user_id, total_amount, status, shipping_address, payment_method, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         RETURNING id, user_id, total_amount, status, created_at`,
        [userId, totalAmount, 'pending', shippingAddress, paymentMethod || null]
      );

      const order = orderResult.rows[0];

      // Add order items
      for (const item of orderItems) {
        await client.query(
          `INSERT INTO order_items (order_id, product_id, quantity, price, subtotal)
           VALUES ($1, $2, $3, $4, $5)`,
          [order.id, item.productId, item.quantity, item.price, item.subtotal]
        );
      }

      await client.query('COMMIT');

      // Add job to BullMQ queue
      await addOrderJob({
        orderId: order.id,
        userId,
        items: orderItems,
        totalAmount,
      });

      res.status(201).json({
        status: 'success',
        message: 'Order created successfully',
        data: {
          orderId: order.id,
          userId: order.user_id,
          totalAmount: order.total_amount,
          status: order.status,
          createdAt: order.created_at,
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}));

// GET /api/orders/:userId - Get user orders
router.get('/:userId', asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { limit = 20, offset = 0 } = req.query;

  const result = await query(
    `SELECT id, user_id, total_amount, status, shipping_address, payment_method, created_at
     FROM orders
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, Number(limit), Number(offset)]
  );

  res.json({
    status: 'success',
    data: result.rows,
    pagination: {
      limit: Number(limit),
      offset: Number(offset),
      count: result.rows.length,
    },
  });
}));

// GET /api/orders/:userId/:orderId - Get single order
router.get('/:userId/:orderId', asyncHandler(async (req, res) => {
  const { userId, orderId } = req.params;

  const orderResult = await query(
    `SELECT id, user_id, total_amount, status, shipping_address, payment_method, created_at
     FROM orders
     WHERE id = $1 AND user_id = $2`,
    [orderId, userId]
  );

  if (orderResult.rows.length === 0) {
    throw new AppError('Order not found', 404);
  }

  const itemsResult = await query(
    `SELECT oi.product_id, p.name, oi.quantity, oi.price, oi.subtotal
     FROM order_items oi
     JOIN products p ON oi.product_id = p.id
     WHERE oi.order_id = $1`,
    [orderId]
  );

  res.json({
    status: 'success',
    data: {
      ...orderResult.rows[0],
      items: itemsResult.rows,
    },
  });
}));

export default router;
