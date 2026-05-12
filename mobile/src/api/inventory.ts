import client from './client';

export const getLowStock = () =>
  client.get('/inventory/low-stock').then(r => r.data);

export const adjustStock = (data: { product_id: number; delta: number; reason: string; note?: string }) =>
  client.post('/inventory/adjust', data).then(r => r.data);

export const getMovements = (params?: Record<string, any>) =>
  client.get('/inventory/movements', { params }).then(r => r.data);
