# ShopSimple Application

A 3-tier e-commerce application demonstrating modern web architecture.

## Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  Frontend   │─────>│     API     │─────>│  PostgreSQL │
│  (React)    │      │  (Express)  │      │             │
└─────────────┘      └──────┬──────┘      └─────────────┘
                            │                      ▲
                            ▼                      │
                     ┌─────────────┐               │
                     │    Redis    │───────────────┘
                     │  (Cache +   │
                     │   Queue)    │
                     └──────┬──────┘
                            │
                            ▼
                     ┌─────────────┐
                     │   Worker    │
                     │  (BullMQ)   │
                     └─────────────┘
```

## Services

| Service  | Tech              | Port | Description                    |
| -------- | ----------------- | ---- | ------------------------------ |
| frontend | React + Vite      | 3000 | Single-page application        |
| api      | Node.js + Express | 4000 | REST API                       |
| worker   | Node.js + BullMQ  | 4001 | Async job processor            |

## Data Stores

- **PostgreSQL** — Products, orders, users
- **Redis** — Session cache, shopping cart, job queue
- **S3** — Product images (AWS, configured via environment)

## Quick Start

```bash
# Start all services
docker compose up --build

# Access the application
open http://localhost:3000

# API health check
curl http://localhost:4000/health
```

## Environment Variables

See `.env.example` in each service directory for required variables.

## Development

```bash
# Run tests
cd api && npm test
cd worker && npm test
cd frontend && npm test

# Lint
cd api && npm run lint
cd frontend && npm run lint
```

## API Endpoints

- `GET /health` — Health check
- `GET /api/products` — List products
- `GET /api/products/:id` — Get product
- `POST /api/cart/:userId/add` — Add to cart
- `GET /api/cart/:userId` — Get cart
- `POST /api/orders` — Create order
- `GET /api/orders` — List orders
