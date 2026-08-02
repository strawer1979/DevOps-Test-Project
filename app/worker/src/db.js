import pg from 'pg';
import logger from './logger.js';

const { Pool } = pg;

const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/shopsimple';

let pool = null;

export function createDbPool() {
  if (pool) {
    return pool;
  }

  pool = new Pool({
    connectionString: DATABASE_URL,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  });

  pool.on('connect', () => {
    logger.info('PostgreSQL client connected to database');
  });

  pool.on('error', (err) => {
    logger.error({ err }, 'PostgreSQL pool error');
  });

  return pool;
}

export async function closeDbPool() {
  if (pool) {
    await pool.end();
    pool = null;
    logger.info('PostgreSQL pool closed gracefully');
  }
}

export async function query(text, params) {
  const client = await pool.connect();
  try {
    const result = await client.query(text, params);
    return result;
  } finally {
    client.release();
  }
}

export default createDbPool;
