import client from './client';

export const getByBarcode = (barcode: string) =>
  client.get(`/products/barcode/${encodeURIComponent(barcode)}`).then(r => r.data);

export const getProducts = (params?: Record<string, any>) =>
  client.get('/products', { params }).then(r => r.data);

export const getProduct = (id: number) =>
  client.get(`/products/${id}`).then(r => r.data);

export const createProduct = (data: Record<string, any>) =>
  client.post('/products', data).then(r => r.data);

export const updateProduct = (id: number, data: Record<string, any>) =>
  client.put(`/products/${id}`, data).then(r => r.data);

export const deleteProduct = (id: number) =>
  client.delete(`/products/${id}`).then(r => r.data);

export const getCategories = () =>
  client.get('/products/categories').then(r => r.data);

export const createCategory = (name: string, description?: string) =>
  client.post('/products/categories', { name, description }).then(r => r.data);

export const getLowStock = () =>
  client.get('/products/low-stock').then(r => r.data);
