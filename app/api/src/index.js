import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

import redis, { checkConnection as checkRedis } from './redis.js';
import pool, { checkConnection as checkPg } from './db.js';
import { orderWorker, closeQueue } from './queue.js';

import productsRouter from './routes/products.js';
import cartRouter from './routes/cart.js';
import ordersRouter from './routes/orders.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', async (req, res) => {
  const healthcheck = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    services: {
      postgres: 'unknown',
      redis: 'unknown',
    },
  };

  try {
    await checkPg();
    healthcheck.services.postgres = 'healthy';
  } catch (error) {
    healthcheck.services.postgres = 'unhealthy';
    healthcheck.status = 'degraded';
  }

  try {
    await checkRedis();
    healthcheck.services.redis = 'healthy';
  } catch (error) {
    healthcheck.services.redis = 'unhealthy';
    healthcheck.status = 'degraded';
  }

  const statusCode = healthcheck.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(healthcheck);
});

// API Routes
app.use('/api/products', productsRouter);
app.use('/api/cart', cartRouter);
app.use('/api/orders', ordersRouter);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Graceful shutdown
const shutdown = async (signal) => {
  console.log(`\n${signal} received. Starting graceful shutdown...`);

  try {
    // Close order worker and queue
    await closeQueue();
    console.log('BullMQ queue closed');

    // Close Redis connection
    await redis.quit();
    console.log('Redis connection closed');

    // Close PostgreSQL pool
    await pool.end();
    console.log('PostgreSQL pool closed');

    console.log('Graceful shutdown completed');
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Start server
const startServer = async () => {
  try {
    // Test PostgreSQL connection
    await checkPg();
    console.log('PostgreSQL connected');

    // Test Redis connection
    await checkRedis();
    console.log('Redis connected');

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

export default app;
