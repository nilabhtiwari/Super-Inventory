import { create } from 'zustand';
import { getSettings } from '../api/settings';

interface ShopSettings {
  shop_name: string;
  shop_address?: string;
  shop_phone?: string;
  shop_email?: string;
  gstin?: string;
  logo_url?: string;
  upi_id?: string;
  upi_name?: string;
  default_cgst: number;
  default_sgst: number;
  default_igst: number;
  currency_symbol: string;
  receipt_footer?: string;
}

interface SettingsState {
  settings: ShopSettings | null;
  isLoading: boolean;
  fetch: () => Promise<void>;
  setSettings: (s: ShopSettings) => void;
}

const defaultSettings: ShopSettings = {
  shop_name: 'My POS Store',
  default_cgst: 9,
  default_sgst: 9,
  default_igst: 0,
  currency_symbol: '₹',
};

export const useSettingsStore = create<SettingsState>((set) => ({
  settings: defaultSettings,
  isLoading: false,

  fetch: async () => {
    set({ isLoading: true });
    try {
      const { settings } = await getSettings();
      set({ settings, isLoading: false });
    } catch {
      set({ isLoading: false });
    }
  },

  setSettings: (settings) => set({ settings }),
}));
