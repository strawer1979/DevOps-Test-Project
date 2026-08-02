import pino from 'pino';

const config = {
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV !== 'production' ? {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname'
    }
  } : undefined
};

const logger = pino({
  ...config,
  formatters: {
    level: (label) => {
      return { level: label };
    }
  }
});

export default logger;
