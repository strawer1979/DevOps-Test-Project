// Mock implementations for testing

const mockJobs = new Map();

export const mockQuery = jest.fn();
export const mockJob = {
  data: {},
  id: 'test-job-1',
  name: 'test-job',
  log: jest.fn(),
  updateProgress: jest.fn(),
};

export const mockWorker = {
  on: jest.fn(),
  close: jest.fn(),
};

export const mockRedisClient = {
  on: jest.fn(),
  quit: jest.fn(),
};

export const mockPool = {
  query: mockQuery,
  on: jest.fn(),
  end: jest.fn(),
};

// Logger mock
export const mockLogger = {
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
  fatal: jest.fn(),
};

export default mockJobs;
