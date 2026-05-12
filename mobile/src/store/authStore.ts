import { create } from 'zustand';
import * as SecureStore from 'expo-secure-store';
import * as authApi from '../api/auth';

interface Seller {
  id: number;
  uuid: string;
  name: string;
  email: string;
  role: 'admin' | 'manager' | 'seller';
  avatar_url?: string | null;
}

interface AuthState {
  seller: Seller | null;
  token: string | null;
  isLoading: boolean;
  isInitialized: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  initialize: () => Promise<void>;
  updateSeller: (data: Partial<Seller>) => void;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  seller: null,
  token: null,
  isLoading: false,
  isInitialized: false,

  initialize: async () => {
    try {
      const token = await SecureStore.getItemAsync('qex_token');
      if (token) {
        const { seller } = await authApi.getMe();
        set({ seller, token, isInitialized: true });
      } else {
        set({ isInitialized: true });
      }
    } catch {
      await SecureStore.deleteItemAsync('qex_token');
      set({ seller: null, token: null, isInitialized: true });
    }
  },

  login: async (email, password) => {
    set({ isLoading: true });
    try {
      const { token, seller } = await authApi.login(email, password);
      await SecureStore.setItemAsync('qex_token', token);
      set({ token, seller, isLoading: false });
    } catch (err) {
      set({ isLoading: false });
      throw err;
    }
  },

  logout: async () => {
    try { await authApi.logout(); } catch {}
    await SecureStore.deleteItemAsync('qex_token');
    set({ seller: null, token: null });
  },

  updateSeller: (data) => {
    set((state) => ({ seller: state.seller ? { ...state.seller, ...data } : null }));
  },
}));
