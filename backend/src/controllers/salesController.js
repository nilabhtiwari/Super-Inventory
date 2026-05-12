const { transaction } = require('../config/db');
const productModel = require('../models/productModel');
const saleModel = require('../models/saleModel');
const settingsModel = require('../models/settingsModel');
const { logAction } = require('../models/auditModel');
const { generateInvoiceNo } = require('../utils/invoice');

/**
 * Calculate GST amounts for a line item
 */
const calcLineItem = (product, qty) => {
  const basePrice = parseFloat(product.selling_price);
  const cgstRate  = parseFloat(product.cgst_rate);
  const sgstRate  = parseFloat(product.sgst_rate);
  const igstRate  = parseFloat(product.igst_rate);

  // If IGST is set, use IGST only (inter-state); else CGST+SGST (intra-state)
  const useIgst = igstRate > 0;

  let cgstAmt = 0, sgstAmt = 0, igstAmt = 0;
  if (useIgst) {
    igstAmt = parseFloat(((basePrice * igstRate) / 100 * qty).toFixed(2));
  } else {
    cgstAmt = parseFloat(((basePrice * cgstRate) / 100 * qty).toFixed(2));
    sgstAmt = parseFloat(((basePrice * sgstRate) / 100 * qty).toFixed(2));
  }

  const lineTotal = parseFloat((basePrice * qty + cgstAmt + sgstAmt + igstAmt).toFixed(2));

  return {
    product_id:   product.id,
    product_name: product.name,
    barcode:      product.barcode,
    hsn_code:     product.hsn_code || null,
    qty,
    unit_price:   basePrice,
    cgst_rate:    cgstRate,
    sgst_rate:    sgstRate,
    igst_rate:    igstRate,
    cgst_amount:  cgstAmt,
    sgst_amount:  sgstAmt,
    igst_amount:  igstAmt,
    line_total:   lineTotal,
  };
};

const createSale = async (req, res, next) => {
  try {
    const { items, customer_name, customer_phone, payment_method, payment_ref, discount_amount = 0, notes } = req.body;
    const sellerId = req.seller.id;

    // Fetch all products
    const productIds = items.map(i => i.product_id);
    const products = {};
    for (const pid of productIds) {
      const p = await productModel.findById(pid);
      if (!p) return res.status(404).json({ success: false, message: `Product ID ${pid} not found` });
      if (!p.is_active) return res.status(400).json({ success: false, message: `Product "${p.name}" is inactive` });
      products[pid] = p;
    }

    // Check stock
    for (const item of items) {
      const p = products[item.product_id];
      if (p.stock_qty < item.qty) {
        return res.status(400).json({ success: false, message: `Insufficient stock for "${p.name}". Available: ${p.stock_qty}` });
      }
    }

    // Calculate totals
    const lineItems = items.map(item => calcLineItem(products[item.product_id], item.qty));
    const subtotal     = parseFloat(lineItems.reduce((s, i) => s + i.unit_price * i.qty, 0).toFixed(2));
    const cgstTotal    = parseFloat(lineItems.reduce((s, i) => s + i.cgst_amount, 0).toFixed(2));
    const sgstTotal    = parseFloat(lineItems.reduce((s, i) => s + i.sgst_amount, 0).toFixed(2));
    const igstTotal    = parseFloat(lineItems.reduce((s, i) => s + i.igst_amount, 0).toFixed(2));
    const taxTotal     = parseFloat((cgstTotal + sgstTotal + igstTotal).toFixed(2));
    const grandTotal   = parseFloat((subtotal + taxTotal - discount_amount).toFixed(2));
    const invoiceNo    = await generateInvoiceNo();

    const saleId = await transaction(async (conn) => {
      const saleId = await saleModel.createSaleHeader(conn, {
        invoice_no: invoiceNo, seller_id: sellerId,
        customer_name, customer_phone,
        subtotal, cgst_total: cgstTotal, sgst_total: sgstTotal,
        igst_total: igstTotal, tax_total: taxTotal,
        discount_amount, grand_total: grandTotal,
        payment_method, payment_ref, notes
      });

      for (const item of lineItems) {
        await saleModel.createSaleItem(conn, { ...item, sale_id: saleId });
        await productModel.decrementStock(conn, item.product_id, item.qty);
        await saleModel.createStockMovement(conn, {
          product_id: item.product_id, delta: -item.qty,
          reason: 'sale', reference_id: saleId, seller_id: sellerId
        });
      }

      return saleId;
    });

    const sale = await saleModel.getById(saleId);
    const saleItems = await saleModel.getItems(saleId);
    const settings = await settingsModel.getSettings();

    await logAction({ seller_id: sellerId, action: 'SALE_CREATE', entity: 'sale', entity_id: saleId, meta: { invoice_no: invoiceNo, grand_total: grandTotal }, ip_address: req.ip });

    res.status(201).json({ success: true, sale: { ...sale, items: saleItems }, settings });
  } catch (err) { next(err); }
};

const getSales = async (req, res, next) => {
  try {
    const { from, to, limit = 20, page = 1 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const sellerId = req.seller.role === 'seller' ? req.seller.id : null;

    const [sales, countRow] = await Promise.all([
      saleModel.getAll({ sellerId, from, to, limit: parseInt(limit), offset }),
      saleModel.countAll({ sellerId, from, to })
    ]);
    const today = new Date().toISOString().slice(0, 10);
    const summary = await saleModel.getDailySummary(today);
    res.json({ success: true, sales, total: countRow.total, page: parseInt(page), limit: parseInt(limit), today_summary: summary });
  } catch (err) { next(err); }
};

const getSaleById = async (req, res, next) => {
  try {
    const sale = await saleModel.getById(parseInt(req.params.id));
    if (!sale) return res.status(404).json({ success: false, message: 'Sale not found' });
    const items = await saleModel.getItems(sale.id);
    const settings = await settingsModel.getSettings();
    res.json({ success: true, sale: { ...sale, items }, settings });
  } catch (err) { next(err); }
};

module.exports = { createSale, getSales, getSaleById };
