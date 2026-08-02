-- ShopSimple Database Initialization Script
-- Run on first startup to create tables and seed data

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(500),
    category VARCHAR(100),
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    shipping_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- Seed data
INSERT INTO products (name, description, price, category, stock_quantity, image_url) VALUES
    ('Wireless Headphones', 'High-quality wireless headphones with noise cancellation', 99.99, 'Electronics', 50, 'https://example.com/images/headphones.jpg'),
    ('Running Shoes', 'Comfortable running shoes for daily training', 79.99, 'Sports', 100, 'https://example.com/images/shoes.jpg'),
    ('Coffee Maker', 'Programmable coffee maker with thermal carafe', 49.99, 'Home', 30, 'https://example.com/images/coffee.jpg'),
    ('Laptop Stand', 'Adjustable aluminum laptop stand', 39.99, 'Electronics', 75, 'https://example.com/images/stand.jpg'),
    ('Water Bottle', 'Insulated stainless steel water bottle', 24.99, 'Sports', 200, 'https://example.com/images/bottle.jpg')
ON CONFLICT DO NOTHING;

INSERT INTO users (email, name) VALUES
    ('john@example.com', 'John Doe'),
    ('jane@example.com', 'Jane Smith')
ON CONFLICT DO NOTHING;
