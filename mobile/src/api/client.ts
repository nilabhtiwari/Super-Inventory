import axios from 'axios';
import * as SecureStore from 'expo-secure-store';

// ⚠️ Change this to your machine's LAN IP when testing on a physical device
// e.g. 'http://192.168.1.100:5000/api'
export const API_BASE_URL = 'http://localhost:5000/api';

const client = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
});

// ── Request interceptor: attach JWT ──────────────────────────────────────────
client.interceptors.request.use(async (config) => {
  const token = await SecureStore.getItemAsync('qex_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// ── Response interceptor: normalize errors ───────────────────────────────────
client.interceptors.response.use(
  (res) => res,
  (err) => {
    const message =
      err.response?.data?.message ||
      err.message ||
      'Network error. Check your connection.';
    return Promise.reject(new Error(message));
  }
);

export default client;
