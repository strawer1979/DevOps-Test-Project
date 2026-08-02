# ShopSimple Worker Service

A BullMQ-based worker service for processing asynchronous jobs in the ShopSimple e-commerce application.

## Overview

This service processes jobs from the `order-processing` queue, handling:
- Order confirmation emails
- Inventory updates

## Requirements

- Node.js >= 20.0.0
- Redis (for BullMQ queue)
- PostgreSQL (for order data)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 4001 | Health check server port |
| DATABASE_URL | postgresql://postgres:postgres@localhost:5432/shopsimple | PostgreSQL connection string |
| REDIS_URL | redis://localhost:6379 | Redis connection string |
| NODE_ENV | development | Environment (development/production) |
| LOG_LEVEL | info | Logging level (debug, info, warn, error) |

## Installation

```bash
npm install
```

## Development

```bash
# Start the worker
npm start

# Run in watch mode
npm run dev

# Run tests
npm test
```

## Docker

```bash
# Build the image
docker build -t shopsimple-worker .

# Run the container
docker run -d \
  --name shopsimple-worker \
  -p 4001:4001 \
  -e DATABASE_URL=postgresql://host:5432/shopsimple \
  -e REDIS_URL=redis://host:6379 \
  shopsimple-worker
```

## Health Check Endpoints

- `GET /health` - Full health status with processed job count
- `GET /health/liveness` - Liveness probe
- `GET /health/readiness` - Readiness probe

## Job Types

### send-order-email
Processes order confirmation emails and updates order status in the database.

**Job Data:**
```json
{
  "orderId": "string",
  "customerEmail": "string",
  "orderDetails": "object"
}
```

### update-inventory
Updates product inventory after order placement.

**Job Data:**
```json
{
  "orderId": "string",
  "items": [
    { "productId": "string", "quantity": "number" }
  ]
}
```

## Graceful Shutdown

The service handles SIGTERM and SIGINT signals for graceful shutdown, ensuring:
- Current jobs complete before exit
- Database connections are properly closed
- Redis connections are properly closed

## License

MIT
