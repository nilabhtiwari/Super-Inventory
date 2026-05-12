const { z } = require('zod');

/**
 * Zod validation middleware factory
 * Usage: validate(schema) — validates req.body
 */
const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body);
  if (!result.success) {
    const errors = result.error.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    }));
    return res.status(422).json({ success: false, message: 'Validation failed', errors });
  }
  req.body = result.data;
  next();
};

/**
 * Reusable Zod schemas
 */
const schemas = {
  login: z.object({
    email:    z.string().email('Invalid email'),
    password: z.string().min(6, 'Password must be at least 6 characters'),
  }),

  createSeller: z.object({
    name:     z.string().min(2).max(100),
    email:    z.string().email(),
    phone:    z.string().max(20).optional(),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    role:     z.enum(['admin', 'manager', 'seller']).default('seller'),
  }),

  createProduct: z.object({
    barcode:            z.string().min(1).max(50),
    sku:                z.string().max(50).optional(),
    name:               z.string().min(1).max(200),
    description:        z.string().optional(),
    category_id:        z.number().int().positive().optional().nullable(),
    hsn_code:           z.string().max(20).optional(),
    unit:               z.string().max(20).default('pcs'),
    purchase_price:     z.number().min(0).default(0),
    selling_price:      z.number().positive('Selling price must be positive'),
    mrp:                z.number().positive().optional().nullable(),
    cgst_rate:          z.number().min(0).max(100).default(9),
    sgst_rate:          z.number().min(0).max(100).default(9),
    igst_rate:          z.number().min(0).max(100).default(0),
    stock_qty:          z.number().int().min(0).default(0),
    low_stock_threshold:z.number().int().min(0).default(10),
    image_url:          z.string().url().optional().nullable(),
  }),

  createSale: z.object({
    items: z.array(z.object({
      product_id: z.number().int().positive(),
      qty:        z.number().int().positive(),
    })).min(1, 'Cart cannot be empty'),
    customer_name:   z.string().max(100).optional(),
    customer_phone:  z.string().max(20).optional(),
    payment_method:  z.enum(['cash', 'upi', 'card', 'mixed']).default('cash'),
    payment_ref:     z.string().max(100).optional(),
    discount_amount: z.number().min(0).default(0),
    notes:           z.string().optional(),
  }),

  stockAdjust: z.object({
    product_id: z.number().int().positive(),
    delta:      z.number().int(),
    reason:     z.enum(['purchase', 'adjustment', 'return', 'initial']),
    note:       z.string().optional(),
  }),

  shopSettings: z.object({
    shop_name:       z.string().min(1).max(200),
    shop_address:    z.string().optional(),
    shop_phone:      z.string().max(20).optional(),
    shop_email:      z.string().email().optional().or(z.literal('')),
    gstin:           z.string().max(20).optional(),
    upi_id:          z.string().max(100).optional(),
    upi_name:        z.string().max(100).optional(),
    default_cgst:    z.number().min(0).max(100).default(9),
    default_sgst:    z.number().min(0).max(100).default(9),
    default_igst:    z.number().min(0).max(100).default(0),
    receipt_footer:  z.string().optional(),
  }),
};

module.exports = { validate, schemas };
