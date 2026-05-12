import { create } from 'zustand';

export interface CartItem {
  product_id: number;
  barcode: string;
  name: string;
  unit: string;
  unit_price: number;
  cgst_rate: number;
  sgst_rate: number;
  igst_rate: number;
  qty: number;
  cgst_amount: number;
  sgst_amount: number;
  igst_amount: number;
  line_total: number;
}

interface CartState {
  items: CartItem[];
  subtotal: number;
  cgstTotal: number;
  sgstTotal: number;
  igstTotal: number;
  taxTotal: number;
  discountAmount: number;
  grandTotal: number;
  addItem: (product: any) => void;
  updateQty: (product_id: number, qty: number) => void;
  removeItem: (product_id: number) => void;
  setDiscount: (amount: number) => void;
  clearCart: () => void;
}

const calcItem = (p: any, qty: number): CartItem => {
  const useIgst = parseFloat(p.igst_rate) > 0;
  const base = parseFloat(p.selling_price);
  const cgstAmt = useIgst ? 0 : parseFloat(((base * parseFloat(p.cgst_rate)) / 100 * qty).toFixed(2));
  const sgstAmt = useIgst ? 0 : parseFloat(((base * parseFloat(p.sgst_rate)) / 100 * qty).toFixed(2));
  const igstAmt = useIgst ? parseFloat(((base * parseFloat(p.igst_rate)) / 100 * qty).toFixed(2)) : 0;
  const lineTotal = parseFloat((base * qty + cgstAmt + sgstAmt + igstAmt).toFixed(2));
  return {
    product_id: p.id,
    barcode: p.barcode,
    name: p.name,
    unit: p.unit || 'pcs',
    unit_price: base,
    cgst_rate: parseFloat(p.cgst_rate),
    sgst_rate: parseFloat(p.sgst_rate),
    igst_rate: parseFloat(p.igst_rate),
    qty,
    cgst_amount: cgstAmt,
    sgst_amount: sgstAmt,
    igst_amount: igstAmt,
    line_total: lineTotal,
  };
};

const recalcTotals = (items: CartItem[], discount: number) => {
  const subtotal  = parseFloat(items.reduce((s, i) => s + i.unit_price * i.qty, 0).toFixed(2));
  const cgstTotal = parseFloat(items.reduce((s, i) => s + i.cgst_amount, 0).toFixed(2));
  const sgstTotal = parseFloat(items.reduce((s, i) => s + i.sgst_amount, 0).toFixed(2));
  const igstTotal = parseFloat(items.reduce((s, i) => s + i.igst_amount, 0).toFixed(2));
  const taxTotal  = parseFloat((cgstTotal + sgstTotal + igstTotal).toFixed(2));
  const grandTotal = parseFloat((subtotal + taxTotal - discount).toFixed(2));
  return { subtotal, cgstTotal, sgstTotal, igstTotal, taxTotal, grandTotal };
};

export const useCartStore = create<CartState>((set, get) => ({
  items: [],
  subtotal: 0,
  cgstTotal: 0,
  sgstTotal: 0,
  igstTotal: 0,
  taxTotal: 0,
  discountAmount: 0,
  grandTotal: 0,

  addItem: (product) => {
    const { items, discountAmount } = get();
    const existing = items.find(i => i.product_id === product.id);
    let newItems: CartItem[];
    if (existing) {
      newItems = items.map(i =>
        i.product_id === product.id ? calcItem(product, i.qty + 1) : i
      );
    } else {
      newItems = [...items, calcItem(product, 1)];
    }
    set({ items: newItems, ...recalcTotals(newItems, discountAmount) });
  },

  updateQty: (product_id, qty) => {
    const { items, discountAmount } = get();
    if (qty <= 0) {
      const newItems = items.filter(i => i.product_id !== product_id);
      set({ items: newItems, ...recalcTotals(newItems, discountAmount) });
      return;
    }
    const newItems = items.map(i => {
      if (i.product_id !== product_id) return i;
      return calcItem({ id: i.product_id, selling_price: i.unit_price, cgst_rate: i.cgst_rate, sgst_rate: i.sgst_rate, igst_rate: i.igst_rate, barcode: i.barcode, name: i.name, unit: i.unit }, qty);
    });
    set({ items: newItems, ...recalcTotals(newItems, discountAmount) });
  },

  removeItem: (product_id) => {
    const { items, discountAmount } = get();
    const newItems = items.filter(i => i.product_id !== product_id);
    set({ items: newItems, ...recalcTotals(newItems, discountAmount) });
  },

  setDiscount: (amount) => {
    const { items } = get();
    set({ discountAmount: amount, ...recalcTotals(items, amount) });
  },

  clearCart: () => set({
    items: [], subtotal: 0, cgstTotal: 0, sgstTotal: 0,
    igstTotal: 0, taxTotal: 0, discountAmount: 0, grandTotal: 0
  }),
}));
