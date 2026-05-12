import client from './client';

export const login = (email: string, password: string) =>
  client.post('/auth/login', { email, password }).then(r => r.data);

export const getMe = () =>
  client.get('/auth/me').then(r => r.data);

export const logout = () =>
  client.post('/auth/logout').then(r => r.data);

export const changePassword = (current_password: string, new_password: string) =>
  client.post('/auth/change-password', { current_password, new_password }).then(r => r.data);
