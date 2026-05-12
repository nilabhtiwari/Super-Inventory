/** Format currency in Indian Rupees */
export const formatCurrency = (amount: number | string, symbol = '₹'): string => {
  const num = parseFloat(String(amount) || '0');
  return `${symbol}${num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

/** Format date to DD/MM/YYYY HH:MM */
export const formatDate = (dateStr: string | Date): string => {
  const d = new Date(dateStr);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

/** Format date to DD MMM YYYY */
export const formatDateShort = (dateStr: string | Date): string => {
  return new Date(dateStr).toLocaleDateString('en-IN', {
    day: '2-digit', month: 'short', year: 'numeric'
  });
};

/** Truncate long text */
export const truncate = (text: string, maxLen = 30): string =>
  text.length > maxLen ? text.slice(0, maxLen) + '…' : text;

/** Capitalize first letter */
export const capitalize = (str: string): string =>
  str ? str.charAt(0).toUpperCase() + str.slice(1) : '';

/** Format stock status */
export const stockStatus = (qty: number, threshold: number): 'ok' | 'low' | 'out' => {
  if (qty === 0) return 'out';
  if (qty <= threshold) return 'low';
  return 'ok';
};

/** Generate UPI deep-link URL */
export const buildUpiUrl = (params: {
  pa: string;   // UPI VPA e.g. merchant@upi
  pn: string;   // Payee name
  am: number;   // Amount
  tn?: string;  // Transaction note
  cu?: string;  // Currency
}): string => {
  const { pa, pn, am, tn = 'POS Payment', cu = 'INR' } = params;
  return `upi://pay?pa=${encodeURIComponent(pa)}&pn=${encodeURIComponent(pn)}&am=${am.toFixed(2)}&tn=${encodeURIComponent(tn)}&cu=${cu}`;
};

/** Role display names */
export const roleLabel: Record<string, string> = {
  admin:   'Admin',
  manager: 'Manager',
  seller:  'Seller',
};

/** Payment method labels */
export const paymentLabel: Record<string, string> = {
  cash:  'Cash',
  upi:   'UPI',
  card:  'Card',
  mixed: 'Mixed',
};
