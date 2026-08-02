import { Queue, Worker } from 'bullmq';
import redis from './redis.js';

const connection = {
  connection: redis,
};

export const orderQueue = new Queue('order-processing', connection);

export const orderWorker = new Worker('order-processing', async (job) => {
  console.log(`Processing order job ${job.id}:`, job.data);

  // Simulate order processing (in real app, this would handle payment, inventory, etc.)
  await new Promise((resolve) => setTimeout(resolve, 1000));

  return {
    status: 'processed',
    orderId: job.data.orderId,
    processedAt: new Date().toISOString(),
  };
}, {
  connection,
  concurrency: 5,
});

orderWorker.on('completed', (job) => {
  console.log(`Order job ${job.id} completed`);
});

orderWorker.on('failed', (job, err) => {
  console.error(`Order job ${job.id} failed:`, err.message);
});

export const addOrderJob = async (orderData) => {
  const job = await orderQueue.add('process-order', orderData, {
    priority: 1,
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 1000,
    },
  });
  return job;
};

export const closeQueue = async () => {
  await orderWorker.close();
  await orderQueue.close();
};

export default orderQueue;
