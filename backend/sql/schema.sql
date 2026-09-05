-- ============================================================
-- Super Inventory POS — MySQL Database Schema
-- ============================================================
-- Run: mysql -u root -p < schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS super_inventory_pos
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE super_inventory_pos;

-- ============================================================
-- 1. SELLERS (users / staff)
-- ============================================================
CREATE TABLE IF NOT EXISTS sellers (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uuid        CHAR(36)      NOT NULL UNIQUE,
  name        VARCHAR(100)  NOT NULL,
  email       VARCHAR(255)  NOT NULL UNIQUE,
  phone       VARCHAR(20)   DEFAULT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role        ENUM('admin','manager','seller') NOT NULL DEFAULT 'seller',
  is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
  avatar_url  VARCHAR(500)  DEFAULT NULL,
  last_login  DATETIME      DEFAULT NULL,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_sellers_email (email),
  INDEX idx_sellers_role (role)
) ENGINE=InnoDB;

-- ============================================================
-- 2. SHOP SETTINGS (branding, UPI, tax defaults)
-- ============================================================
CREATE TABLE IF NOT EXISTS shop_settings (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  shop_name       VARCHAR(200)  NOT NULL DEFAULT 'My Shop',
  shop_address    TEXT          DEFAULT NULL,
  shop_phone      VARCHAR(20)   DEFAULT NULL,
  shop_email      VARCHAR(255)  DEFAULT NULL,
  gstin           VARCHAR(20)   DEFAULT NULL,
  logo_url        VARCHAR(500)  DEFAULT NULL,
  upi_id          VARCHAR(100)  DEFAULT NULL COMMENT 'UPI VPA for QR payment e.g. shop@upi',
  upi_name        VARCHAR(100)  DEFAULT NULL COMMENT 'Payee name shown in UPI apps',
  default_cgst    DECIMAL(5,2)  NOT NULL DEFAULT 9.00,
  default_sgst    DECIMAL(5,2)  NOT NULL DEFAULT 9.00,
  default_igst    DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  currency_symbol VARCHAR(5)    NOT NULL DEFAULT '₹',
  receipt_footer  TEXT          DEFAULT NULL COMMENT 'Thank you message / terms',
  updated_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Seed one default row
INSERT INTO shop_settings (shop_name) VALUES ('My Shop')
  ON DUPLICATE KEY UPDATE shop_name = shop_name;

-- ============================================================
-- 3. CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL UNIQUE,
  description VARCHAR(500)  DEFAULT NULL,
  is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 4. PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  barcode             VARCHAR(50)   NOT NULL UNIQUE,
  sku                 VARCHAR(50)   DEFAULT NULL,
  name                VARCHAR(200)  NOT NULL,
  description         TEXT          DEFAULT NULL,
  category_id         INT UNSIGNED  DEFAULT NULL,
  hsn_code            VARCHAR(20)   DEFAULT NULL COMMENT 'HSN/SAC code for GST',
  unit                VARCHAR(20)   NOT NULL DEFAULT 'pcs',
  purchase_price      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  selling_price       DECIMAL(12,2) NOT NULL,
  mrp                 DECIMAL(12,2) DEFAULT NULL,
  cgst_rate           DECIMAL(5,2)  NOT NULL DEFAULT 9.00,
  sgst_rate           DECIMAL(5,2)  NOT NULL DEFAULT 9.00,
  igst_rate           DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  stock_qty           INT           NOT NULL DEFAULT 0,
  low_stock_threshold INT           NOT NULL DEFAULT 10,
  image_url           VARCHAR(500)  DEFAULT NULL,
  is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_products_barcode (barcode),
  INDEX idx_products_name (name),
  INDEX idx_products_category (category_id),
  INDEX idx_products_stock (stock_qty, low_stock_threshold),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 5. SALES (header)
-- ============================================================
CREATE TABLE IF NOT EXISTS sales (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_no      VARCHAR(30)   NOT NULL UNIQUE COMMENT 'e.g. INV-20240501-0001',
  seller_id       INT UNSIGNED  NOT NULL,
  customer_name   VARCHAR(100)  DEFAULT NULL,
  customer_phone  VARCHAR(20)   DEFAULT NULL,
  subtotal        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  cgst_total      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  sgst_total      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  igst_total      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  tax_total       DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  grand_total     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  payment_method  ENUM('cash','upi','card','mixed') NOT NULL DEFAULT 'cash',
  payment_ref     VARCHAR(100)  DEFAULT NULL COMMENT 'UPI txn ref / card approval code',
  status          ENUM('completed','refunded','void') NOT NULL DEFAULT 'completed',
  notes           TEXT          DEFAULT NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_sales_seller (seller_id),
  INDEX idx_sales_date (created_at),
  INDEX idx_sales_invoice (invoice_no),
  CONSTRAINT fk_sales_seller FOREIGN KEY (seller_id) REFERENCES sellers(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 6. SALE ITEMS (line items)
-- ============================================================
CREATE TABLE IF NOT EXISTS sale_items (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sale_id       INT UNSIGNED  NOT NULL,
  product_id    INT UNSIGNED  NOT NULL,
  product_name  VARCHAR(200)  NOT NULL COMMENT 'Snapshot at time of sale',
  barcode       VARCHAR(50)   NOT NULL COMMENT 'Snapshot',
  hsn_code      VARCHAR(20)   DEFAULT NULL,
  qty           INT           NOT NULL DEFAULT 1,
  unit_price    DECIMAL(12,2) NOT NULL,
  cgst_rate     DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  sgst_rate     DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  igst_rate     DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  cgst_amount   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  sgst_amount   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  igst_amount   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  line_total    DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT 'qty * unit_price + tax',

  INDEX idx_sale_items_sale (sale_id),
  INDEX idx_sale_items_product (product_id),
  CONSTRAINT fk_saleitems_sale FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  CONSTRAINT fk_saleitems_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 7. STOCK MOVEMENTS (audit trail for inventory)
-- ============================================================
CREATE TABLE IF NOT EXISTS stock_movements (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id    INT UNSIGNED  NOT NULL,
  delta         INT           NOT NULL COMMENT '+ve = stock in, -ve = stock out',
  reason        ENUM('sale','return','adjustment','purchase','initial') NOT NULL,
  reference_id  INT UNSIGNED  DEFAULT NULL COMMENT 'sale_id if reason=sale',
  seller_id     INT UNSIGNED  DEFAULT NULL,
  note          VARCHAR(500)  DEFAULT NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_stockmov_product (product_id),
  INDEX idx_stockmov_date (created_at),
  CONSTRAINT fk_stockmov_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  CONSTRAINT fk_stockmov_seller FOREIGN KEY (seller_id) REFERENCES sellers(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 8. AUDIT LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  seller_id   INT UNSIGNED    DEFAULT NULL,
  action      VARCHAR(50)     NOT NULL COMMENT 'e.g. LOGIN, SALE_CREATE, PRODUCT_UPDATE',
  entity      VARCHAR(50)     DEFAULT NULL COMMENT 'e.g. sale, product, seller',
  entity_id   INT UNSIGNED    DEFAULT NULL,
  meta        JSON            DEFAULT NULL COMMENT 'Extra context',
  ip_address  VARCHAR(45)     DEFAULT NULL,
  user_agent  VARCHAR(500)    DEFAULT NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_audit_seller (seller_id),
  INDEX idx_audit_action (action),
  INDEX idx_audit_date (created_at),
  CONSTRAINT fk_audit_seller FOREIGN KEY (seller_id) REFERENCES sellers(id) ON DELETE SET NULL
) ENGINE=InnoDB;
