import request from 'supertest';
import app from '../src/index.js';

describe('Health Check Endpoint', () => {
  it('should return health status', async () => {
    const response = await request(app)
      .get('/health')
      .expect('Content-Type', /json/);

    expect(response.body).toHaveProperty('status');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body.status).toBeDefined();
    expect(response.body.timestamp).toBeDefined();
  });

  it('should include service status', async () => {
    const response = await request(app)
      .get('/health')
      .expect('Content-Type', /json/);

    expect(response.body).toHaveProperty('services');
    expect(response.body.services).toHaveProperty('postgres');
    expect(response.body.services).toHaveProperty('redis');
  });
});
