import 'dotenv/config';
import { createServer } from 'http';
import { Worker } from 'bullmq';
import createRedisClient, { closeRedisConnection } from './redis.js';
import createDbPool, { closeDbPool } from './db.js';
import logger from './logger.js';
import handleOrderEmailJob from './jobs/orderEmail.js';
import handleUpdateInventoryJob from './jobs/updateInventory.js';

// Configuration
const PORT = parseInt(process.env.PORT, 10) || 4001;
const NODE_ENV = process.env.NODE_ENV || 'development';
const QUEUE_NAME = 'order-processing';

// Global state
let worker = null;
let httpServer = null;
let processedCount = 0;
let isShuttingDown = false;

/**
 * Create and configure the BullMQ worker
 */
function createWorker() {
  const connection = createRedisClient();

  worker = new Worker(QUEUE_NAME, async (job) => {
    logger.debug({ jobId: job.id, jobName: job.name }, 'Processing job');

    try {
      let result;

      switch (job.name) {
        case 'send-order-email':
          result = await handleOrderEmailJob(job);
          break;

        case 'update-inventory':
          result = await handleUpdateInventoryJob(job);
          break;

        default:
          logger.warn({ jobName: job.name }, 'Unknown job type');
          throw new Error(`Unknown job type: ${job.name}`);
      }

      processedCount++;
      logger.info(
        { jobId: job.id, jobName: job.name, processedCount },
        'Job completed successfully'
      );

      return result;
    } catch (error) {
      logger.error(
        { err: error, jobId: job.id, jobName: job.name },
        'Job failed'
      );
      throw error;
    }
  }, {
    connection,
    concurrency: 5,
    removeOnComplete: {
      count: 100,
      age: 24 * 3600
    },
    removeOnFail: {
      count: 50,
      age: 7 * 24 * 3600
    }
  });

  worker.on('completed', (job) => {
    logger.debug({ jobId: job.id, jobName: job.name }, 'Job completed event');
  });

  worker.on('failed', (job, error) => {
    logger.error(
      { jobId: job?.id, jobName: job?.name, err: error },
      'Job failed event'
    );
  });

  worker.on('error', (error) => {
    logger.error({ err: error }, 'Worker error');
  });

  return worker;
}

/**
 * Create HTTP health check server
 */
function createHealthCheckServer() {
  const server = createServer((req, res) => {
    if (req.url === '/health' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        status: 'ok',
        processed: processedCount,
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
      }));
      return;
    }

    if (req.url === '/health/liveness' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'alive' }));
      return;
    }

    if (req.url === '/health/readiness' && req.method === 'GET') {
      // Check if worker is ready (not shutting down)
      const ready = !isShuttingDown;
      res.writeHead(ready ? 200 : 503, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: ready ? 'ready' : 'not ready' }));
      return;
    }

    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  });

  server.listen(PORT, () => {
    logger.info({ port: PORT, env: NODE_ENV }, 'Health check server started');
  });

  return server;
}

/**
 * Graceful shutdown handler
 */
async function shutdown(signal) {
  if (isShuttingDown) {
    logger.warn('Shutdown already in progress');
    return;
  }

  isShuttingDown = true;
  logger.info({ signal }, 'Received shutdown signal, starting graceful shutdown');

  try {
    // Stop accepting new jobs
    if (worker) {
      logger.info('Closing BullMQ worker...');
      await worker.close();
      logger.info('BullMQ worker closed');
    }

    // Close HTTP server
    if (httpServer) {
      logger.info('Closing HTTP server...');
      await new Promise((resolve) => {
        httpServer.close(() => {
          logger.info('HTTP server closed');
          resolve();
        });
      });
    }

    // Close database connection
    logger.info('Closing database connection...');
    await closeDbPool();

    // Close Redis connection
    logger.info('Closing Redis connection...');
    await closeRedisConnection();

    logger.info('Graceful shutdown completed');
    process.exit(0);
  } catch (error) {
    logger.error({ err: error }, 'Error during shutdown');
    process.exit(1);
  }
}

/**
 * Main application entry point
 */
async function main() {
  logger.info({ env: NODE_ENV, queue: QUEUE_NAME }, 'Starting ShopSimple worker');

  try {
    // Initialize database connection
    createDbPool();
    logger.info('Database connection pool initialized');

    // Create worker
    createWorker();
    logger.info({ queue: QUEUE_NAME }, 'BullMQ worker initialized');

    // Create health check server
    httpServer = createHealthCheckServer();

    // Register shutdown handlers
    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

    // Handle uncaught errors
    process.on('uncaughtException', (error) => {
      logger.fatal({ err: error }, 'Uncaught exception');
      shutdown('uncaughtException');
    });

    process.on('unhandledRejection', (reason) => {
      logger.fatal({ reason }, 'Unhandled rejection');
      shutdown('unhandledRejection');
    });

    logger.info({ port: PORT }, 'ShopSimple worker is running');
  } catch (error) {
    logger.fatal({ err: error }, 'Failed to start worker');
    process.exit(1);
  }
}

// Start the application
main();
