import { Router } from 'express';
import redis from '../redis.js';
import { query } from '../db.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';

const router = Router();

const getCartKey = (userId) => `cart:${userId}`;

// GET /api/cart/:userId - Get cart from Redis
router.get('/:userId', asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const cartKey = getCartKey(userId);

  const cartData = await redis.hgetall(cartKey);

  if (!cartData || Object.keys(cartData).length === 0) {
    return res.json({
      status: 'success',
      data: {
        userId,
        items: [],
        total: 0,
      },
    });
  }

  // Get product details for items in cart
  const items = await Promise.all(
    Object.entries(cartData).map(async ([productId, quantity]) => {
      const result = await query(
        'SELECT id, name, price, image_url FROM products WHERE id = $1',
        [productId]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const product = result.rows[0];
      return {
        productId: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.image_url,
        quantity: Number(quantity),
        subtotal: product.price * Number(quantity),
      };
    })
  );

  const validItems = items.filter(Boolean);
  const total = validItems.reduce((sum, item) => sum + item.subtotal, 0);

  res.json({
    status: 'success',
    data: {
      userId,
      items: validItems,
      total,
    },
  });
}));

// POST /api/cart/:userId/add - Add item to cart
router.post('/:userId/add', asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { productId, quantity = 1 } = req.body;

  if (!productId) {
    throw new AppError('Product ID is required', 400);
  }

  // Verify product exists
  const productResult = await query(
    'SELECT id, stock FROM products WHERE id = $1',
    [productId]
  );

  if (productResult.rows.length === 0) {
    throw new AppError('Product not found', 404);
  }

  const availableStock = productResult.rows[0].stock;

  // Check current quantity in cart
  const cartKey = getCartKey(userId);
  const currentQuantity = await redis.hget(cartKey, productId);
  const newQuantity = (Number(currentQuantity) || 0) + Number(quantity);

  if (newQuantity > availableStock) {
    throw new AppError(`Not enough stock. Available: ${availableStock}`, 400);
  }

  // Update cart in Redis
  await redis.hincrby(cartKey, productId, quantity);
  await redis.expire(cartKey, 7 * 24 * 60 * 60); // 7 days TTL

  res.json({
    status: 'success',
    message: 'Item added to cart',
    data: {
      userId,
      productId,
      quantity: newQuantity,
    },
  });
}));

// DELETE /api/cart/:userId/remove - Remove item from cart
router.delete('/:userId/remove', asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { productId } = req.body;

  if (!productId) {
    throw new AppError('Product ID is required', 400);
  }

  const cartKey = getCartKey(userId);
  await redis.hdel(cartKey, productId);

  res.json({
    status: 'success',
    message: 'Item removed from cart',
  });
}));

// DELETE /api/cart/:userId - Clear cart
router.delete('/:userId', asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const cartKey = getCartKey(userId);
  await redis.del(cartKey);

  res.json({
    status: 'success',
    message: 'Cart cleared',
  });
}));

export default router;
