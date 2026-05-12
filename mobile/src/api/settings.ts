import client from './client';

export const getSettings = () =>
  client.get('/settings').then(r => r.data);

export const updateSettings = (data: Record<string, any>) =>
  client.put('/settings', data).then(r => r.data);

export const getSellers = (params?: Record<string, any>) =>
  client.get('/admin/sellers', { params }).then(r => r.data);

export const createSeller = (data: Record<string, any>) =>
  client.post('/admin/sellers', data).then(r => r.data);

export const updateSellerStatus = (id: number, is_active: boolean) =>
  client.patch(`/admin/sellers/${id}/status`, { is_active }).then(r => r.data);

export const updateSellerRole = (id: number, role: string) =>
  client.patch(`/admin/sellers/${id}/role`, { role }).then(r => r.data);

export const getAuditLogs = (params?: Record<string, any>) =>
  client.get('/admin/audit-logs', { params }).then(r => r.data);
