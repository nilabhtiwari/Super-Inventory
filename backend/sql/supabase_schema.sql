-- ========================================================
-- Super Inventory - Supabase PostgreSQL Schema
-- Copy & Run in Supabase SQL Editor: https://supabase.com/dashboard/project/_/sql
-- ========================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Sellers & Store Owners
CREATE TABLE IF NOT EXISTS public.sellers (
    id BIGSERIAL PRIMARY KEY,
    store_name VARCHAR(150) NOT NULL,
    owner_name VARCHAR(150),
    email VARCHAR(191) NOT NULL UNIQUE,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'seller',
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Products Catalog
CREATE TABLE IF NOT EXISTS public.products (
    id BIGSERIAL PRIMARY KEY,
    seller_id BIGINT REFERENCES public.sellers(id) ON DELETE CASCADE,
    barcode VARCHAR(100) UNIQUE,
    name VARCHAR(255) NOT NULL,
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    cost_price NUMERIC(10,2) DEFAULT 0.00,
    gst NUMERIC(5,2) DEFAULT 5.00,
    qty INTEGER DEFAULT 0,
    unit VARCHAR(50) DEFAULT 'pcs',
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Invoices / Transactions
CREATE TABLE IF NOT EXISTS public.invoices (
    id BIGSERIAL PRIMARY KEY,
    seller_id BIGINT REFERENCES public.sellers(id) ON DELETE CASCADE,
    invoice_number VARCHAR(100) NOT NULL UNIQUE,
    customer_phone VARCHAR(20),
    subtotal NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    gst_total NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    grand_total NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) DEFAULT 'CASH',
    receipt_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Storage Bucket setup (Run in SQL Editor to create buckets for images & receipts)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;
