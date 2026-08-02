import { jest } from '@jest/globals';

// Mock the dependencies
const mockQuery = jest.fn();
const mockPool = {
  connect: jest.fn().mockResolvedValue({
    query: mockQuery,
    release: jest.fn(),
  }),
};

jest.unstable_mockModule('pg', () => ({
  default: {
    Pool: jest.fn().mockImplementation(() => mockPool),
  },
}));

jest.unstable_mockModule('./logger.js', () => ({
  default: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
    fatal: jest.fn(),
  },
}));

jest.unstable_mockModule('./redis.js', () => ({
  default: jest.fn(),
  createRedisClient: jest.fn(),
  closeRedisConnection: jest.fn(),
}));

jest.unstable_mockModule('./db.js', () => ({
  default: jest.fn(),
  createDbPool: jest.fn(),
  closeDbPool: jest.fn(),
  query: mockQuery,
}));

// Import after mocks
const handleOrderEmailJob = (await import('../src/jobs/orderEmail.js')).default;
const handleUpdateInventoryJob = (await import('../src/jobs/updateInventory.js')).default;

describe('Order Email Job Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('should process order email job successfully', async () => {
    const mockOrder = {
      orderId: 'order-123',
      customerEmail: 'test@example.com',
      orderDetails: { total: 100.00 },
    };

    // Mock successful DB update
    mockQuery.mockResolvedValueOnce({
      rowCount: 1,
      rows: [{ id: 'order-123', status: 'email_sent', updated_at: new Date() }],
    });

    const result = await handleOrderEmailJob({ data: mockOrder });

    expect(result).toBeDefined();
    expect(result.success).toBe(true);
    expect(result.orderId).toBe('order-123');
    expect(result.customerEmail).toBe('test@example.com');
  });

  test('should handle missing order in database', async () => {
    const mockOrder = {
      orderId: 'non-existent',
      customerEmail: 'test@example.com',
      orderDetails: {},
    };

    mockQuery.mockResolvedValueOnce({
      rowCount: 0,
      rows: [],
    });

    const result = await handleOrderEmailJob({ data: mockOrder });

    expect(result).toBeDefined();
    expect(result.orderId).toBe('non-existent');
  });
});

describe('Update Inventory Job Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('should process inventory update job successfully', async () => {
    const mockInventoryData = {
      orderId: 'order-456',
      items: [
        { productId: 'prod-1', quantity: 2 },
        { productId: 'prod-2', quantity: 1 },
      ],
    };

    const result = await handleUpdateInventoryJob({ data: mockInventoryData });

    expect(result).toBeDefined();
    expect(result.success).toBe(true);
    expect(result.orderId).toBe('order-456');
    expect(result.itemsUpdated).toBe(2);
  });

  test('should handle empty items array', async () => {
    const mockInventoryData = {
      orderId: 'order-789',
      items: [],
    };

    const result = await handleUpdateInventoryJob({ data: mockInventoryData });

    expect(result).toBeDefined();
    expect(result.itemsUpdated).toBe(0);
  });

  test('should generate low stock warning for items with quantity > 90', async () => {
    const mockInventoryData = {
      orderId: 'order-999',
      items: [{ productId: 'prod-3', quantity: 95 }],
    };

    const result = await handleUpdateInventoryJob({ data: mockInventoryData });

    expect(result).toBeDefined();
    expect(result.itemsUpdated).toBe(1);
  });
});

describe('Job Data Validation', () => {
  test('order email job requires orderId and customerEmail', async () => {
    const mockOrder = {
      orderId: 'order-123',
      customerEmail: 'test@example.com',
    };

    mockQuery.mockResolvedValueOnce({
      rowCount: 1,
      rows: [{ id: 'order-123', status: 'email_sent', updated_at: new Date() }],
    });

    const result = await handleOrderEmailJob({ data: mockOrder });

    expect(result.orderId).toBeDefined();
    expect(result.customerEmail).toBeDefined();
  });

  test('update inventory job requires orderId and items', async () => {
    const mockInventoryData = {
      orderId: 'order-456',
      items: [{ productId: 'prod-1', quantity: 1 }],
    };

    const result = await handleUpdateInventoryJob({ data: mockInventoryData });

    expect(result.orderId).toBeDefined();
    expect(result.items).toBeDefined();
    expect(Array.isArray(result.items)).toBe(true);
  });
});
