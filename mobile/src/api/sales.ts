import client from './client';

export const createSale = (data: Record<string, any>) =>
  client.post('/sales', data).then(r => r.data);

export const getSales = (params?: Record<string, any>) =>
  client.get('/sales', { params }).then(r => r.data);

export const getSale = (id: number) =>
  client.get(`/sales/${id}`).then(r => r.data);
