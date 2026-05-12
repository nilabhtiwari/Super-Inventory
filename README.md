# QEXmanage POS 🛒

A production-ready **Smart POS System** built with **React Native (Expo)**, **Node.js/Express**, and **MySQL**.

---

## Features

| Feature | Details |
|---|---|
| 🔐 Secure login | JWT auth, bcrypt passwords, role-based (admin/manager/seller) |
| 📡 Barcode scanning | Bluetooth HID (keyboard-mode) — zero config, works with all BT scanners |
| 🛒 POS billing cart | Add/edit/remove items, quantity editing, instant totals |
| 🧾 GST invoice | CGST + SGST / IGST per-product, HSN code, full tax breakdown |
| 📱 UPI QR on receipt | Scan to pay via any UPI app — PhonePe, GPay, Paytm etc. |
| 🖨️ Print/Share receipt | PDF via `expo-print`, shareable via WhatsApp/Email |
| 📦 Inventory management | Low-stock alerts, manual adjustment, movement history |
| 🏪 Shop branding | Custom name, address, GSTIN, logo, receipt footer |
| 📊 Sale history | Daily summary, paginated history, tap to view receipt |
| 👥 Staff management | Admin can create/deactivate sellers, assign roles |
| 📋 Audit logs | Every action tracked with seller, IP, timestamp |

---

## Project Structure

```
QEXmanage1/
├── backend/          Node.js + Express REST API
│   ├── sql/          MySQL schema
│   ├── src/
│   │   ├── config/   DB, logger, migrate, seed
│   │   ├── controllers/
│   │   ├── middleware/  auth, validate, rateLimiter, errorHandler
│   │   ├── models/
│   │   ├── routes/
│   │   └── utils/    jwt, invoice generator
│   └── Dockerfile
├── mobile/           React Native (Expo) app
│   └── src/
│       ├── api/      Axios API calls
│       ├── components/  CartItem, TotalPanel, EmptyState, LoadingOverlay
│       ├── navigation/  Stack + Tab navigator
│       ├── screens/  Login, POS, Receipt, History, Products, Inventory, Settings, Audit
│       ├── store/    Zustand: auth, cart, settings
│       ├── theme/    Design tokens (colors, spacing, radius)
│       └── utils/    formatters, UPI URL builder
└── docker-compose.yml
```

---

## Quick Start

### 1. Database (Docker — easiest)

```bash
docker-compose up -d mysql
```
This starts MySQL with the schema auto-applied.

### 2. Backend

```bash
cd backend
cp .env.example .env     # Edit DB credentials if not using Docker
npm install
node src/config/migrate.js   # Run schema (skip if using Docker)
node src/config/seed.js      # Seed admin user + sample products
npm run dev
```

API runs at: `http://localhost:5000`

Default admin login:
- Email: `admin@shop.local`
- Password: `Admin@1234`

### 3. Mobile App

```bash
cd mobile
npm install
```

**⚠️ Set your API URL** — open `src/api/client.ts` and change:
```ts
export const API_BASE_URL = 'http://YOUR_PC_LAN_IP:5000/api';
// e.g. 'http://192.168.1.100:5000/api'
```

```bash
npx expo start
# Scan QR code with Expo Go app on your phone
```

---

## Barcode Scanner Setup

| Mode | How to use |
|---|---|
| **Bluetooth HID** (recommended) | Pair scanner in phone Settings → BT; it becomes a keyboard |
| **2.4GHz USB dongle** | Works with USB-OTG adapter on Android |
| **Camera** | Backup mode available in Expo camera |

The POS screen keeps a `TextInput` auto-focused at all times. When the scanner sends barcode + Enter, `onSubmitEditing` fires and the product is fetched instantly.

---

## UPI QR Payment

In Settings → UPI Payment, enter your UPI ID (e.g., `yourshop@upi`).

Every receipt will display a QR code that encodes:
```
upi://pay?pa=yourshop@upi&pn=Shop+Name&am=299.00&tn=INV-20241201-0001&cu=INR
```

Customer scans → opens their UPI app → amount pre-filled → pay.

---

## GST (India)

- Each product has `cgst_rate`, `sgst_rate`, `igst_rate` fields
- Intra-state: CGST + SGST (e.g., 9% + 9% = 18%)
- Inter-state: IGST only (e.g., 18%)
- Receipt shows full GST breakdown per item + totals
- HSN code stored per product for compliance

---

## API Endpoints

```
POST   /api/auth/login
GET    /api/auth/me
POST   /api/auth/logout

GET    /api/products/barcode/:code     ← POS barcode lookup
GET    /api/products
POST   /api/products
PUT    /api/products/:id
DELETE /api/products/:id
GET    /api/products/categories
GET    /api/products/low-stock

POST   /api/sales                      ← Create sale + deduct stock
GET    /api/sales
GET    /api/sales/:id

GET    /api/inventory/low-stock
POST   /api/inventory/adjust
GET    /api/inventory/movements

GET    /api/settings
PUT    /api/settings

GET    /api/admin/sellers
POST   /api/admin/sellers
GET    /api/admin/audit-logs
```

---

## Tech Stack

| Layer | Tech |
|---|---|
| Mobile | React Native (Expo 51), Zustand, Axios, expo-print, expo-sharing |
| QR Code | react-native-qrcode-svg (UPI payment QR) |
| Backend | Node.js 20, Express 4, MySQL2 |
| Security | JWT, bcryptjs (salt 12), Helmet, CORS, Zod, rate-limit |
| Database | MySQL 8.0 (8 tables, indexed, FK constraints) |
| Dev ops | Docker Compose, Winston logging, Nodemon |

---

## Roles

| Role | Access |
|---|---|
| **Admin** | Everything: settings, staff, audit logs, products, sales |
| **Manager** | Products, inventory, sales history (all sellers) |
| **Seller** | POS billing, own sale history |
