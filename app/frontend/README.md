# ShopSimple Frontend

A React + Vite frontend for the ShopSimple e-commerce application.

## Features

- Product listing and detail views
- Shopping cart functionality
- API health monitoring
- Responsive design
- Docker deployment support

## Tech Stack

- React 18
- Vite 5
- React Router DOM
- Axios
- Vitest (testing)

## Getting Started

### Prerequisites

- Node.js 18+
- npm

### Installation

```bash
npm install
```

### Development

```bash
npm run dev
```

The app will be available at http://localhost:3000

### Build

```bash
npm run build
```

### Testing

```bash
npm test
```

### Linting

```bash
npm run lint
```

## Docker Deployment

### Build the Docker image

```bash
docker build -t shopsimple-frontend .
```

### Run the container

```bash
docker run -p 8080:80 shopsimple-frontend
```

The frontend will be available at http://localhost:8080

### Docker Compose

Use the provided `docker-compose.yml` to run with the backend:

```bash
docker-compose up
```

## API Endpoints

The frontend expects these backend endpoints:

- `GET /api/products` - List all products
- `GET /api/products/:id` - Get single product
- `GET /api/cart` - Get cart items
- `GET /api/health` - Health check

## Project Structure

```
src/
├── api/
│   └── client.js       # Axios client configuration
├── components/
│   ├── Header.jsx      # Navigation header
│   └── ProductCard.jsx # Product card component
├── pages/
│   ├── Home.jsx        # Landing page
│   ├── Products.jsx    # Product listing
│   ├── ProductDetail.jsx # Product details
│   ├── Cart.jsx        # Shopping cart
│   └── Health.jsx      # API health status
├── __tests__/
│   ├── App.test.jsx    # App component tests
│   └── setup.js        # Test setup
├── App.jsx             # Main app component
├── main.jsx            # Entry point
└── index.css           # Global styles
```

## License

MIT
