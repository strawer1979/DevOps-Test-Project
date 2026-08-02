import { Router } from 'express';
import { query } from '../db.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';

const router = Router();

const PRODUCT_COLUMNS = 'id, name, description, price, stock, image_url, category, created_at, updated_at';

// GET /api/products - List all products
router.get('/', asyncHandler(async (req, res) => {
  const { category, limit = 50, offset = 0 } = req.query;

  let text = `SELECT ${PRODUCT_COLUMNS} FROM products`;
  const params = [];

  if (category) {
    params.push(category);
    text += ` WHERE category = $${params.length}`;
  }

  text += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
  params.push(Number(limit), Number(offset));

  const result = await query(text, params);

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

// GET /api/products/:id - Get single product
router.get('/:id', asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await query(
    `SELECT ${PRODUCT_COLUMNS} FROM products WHERE id = $1`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new AppError('Product not found', 404);
  }

  res.json({
    status: 'success',
    data: result.rows[0],
  });
}));

export default router;
