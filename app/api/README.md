# ShopSimple API

A Node.js + Express REST API service for the ShopSimple e-commerce application.

## Features

- RESTful API with Express
- PostgreSQL for product and order data storage
- Redis for cart management (using ioredis)
- BullMQ for asynchronous order processing
- Health check endpoint with service status
- Graceful shutdown handling

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 4000 | Server port |
| DATABASE_URL | postgresql://postgres:postgres@localhost:5432/shopsimple | PostgreSQL connection string |
| REDIS_URL | redis://localhost:6379 | Redis connection string |
| S3_BUCKET | shopsimple-images | S3 bucket for images |
| AWS_REGION | us-east-1 | AWS region |
| NODE_ENV | development | Environment (development/production) |

## API Endpoints

### Health Check
- `GET /health` - Returns service health status

### Products
- `GET /api/products` - List all products
- `GET /api/products/:id` - Get single product

### Cart
- `GET /api/cart/:userId` - Get user's cart
- `POST /api/cart/:userId/add` - Add item to cart
- `DELETE /api/cart/:userId/remove` - Remove item from cart
- `DELETE /api/cart/:userId` - Clear cart

### Orders
- `POST /api/orders` - Create new order
- `GET /api/orders/:userId` - Get user's orders
- `GET /api/orders/:userId/:orderId` - Get single order

## Running Locally

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Start production server
npm start
```

## Running with Docker

```bash
# Build the image
docker build -t shopsimple-api .

# Run the container
docker run -p 4000:4000 --env-file .env shopsimple-api
```

## Running Tests

```bash
npm test
```

## Database Schema

The API expects the following tables in PostgreSQL:

```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  stock INTEGER DEFAULT 0,
  image_url VARCHAR(500),
  category VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(100) NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  shipping_address TEXT,
  payment_method VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id),
  product_id INTEGER REFERENCES products(id),
  quantity INTEGER NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL
);
```

## License

MIT
