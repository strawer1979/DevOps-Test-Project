import Redis from 'ioredis';

const redisOptions = {
  lazyConnect: true,
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => {
    if (times > 3) {
      console.error('Redis connection failed after 3 retries');
      return null;
    }
    return Math.min(times * 200, 2000);
  },
  reconnectOnError: (err) => {
    console.error('Redis reconnect on error:', err.message);
    return true;
  },
};

const redis = new Redis(process.env.REDIS_URL, redisOptions);

redis.on('connect', () => {
  console.log('Redis connected');
});

redis.on('error', (err) => {
  console.error('Redis error:', err.message);
});

redis.on('ready', () => {
  console.log('Redis ready');
});

export const checkConnection = async () => {
  try {
    const result = await redis.ping();
    return result === 'PONG';
  } catch (error) {
    console.error('Redis ping failed:', error.message);
    throw error;
  }
};

export default redis;
