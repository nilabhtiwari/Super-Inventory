const { supabase } = require('../config/supabase');
const pool = require('../config/db');
const bcrypt = require('bcryptjs');
const logger = require('../config/logger');

// Resilient in-memory fallback store
const memoryStores = new Map();

// Seed initial demo seller
(async () => {
  const hash = await bcrypt.hash('Merchant@1234', 10);
  memoryStores.set('merchant@gmail.com', {
    id: 1,
    store_name: 'Super Inventory Flagship',
    owner_name: 'Merchant Partner',
    email: 'merchant@gmail.com',
    phone: '9876543210',
    password_hash: hash,
    role: 'seller',
    status: 'active',
    created_at: new Date()
  });
})();

class SellerModel {
  static async findByEmail(email) {
    const cleanEmail = email.toLowerCase().trim();

    // 1. Check Supabase PostgreSQL if active
    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('sellers')
          .select('*')
          .eq('email', cleanEmail)
          .maybeSingle();

        if (!error && data) return data;
      } catch (err) {
        logger.warn('Supabase findByEmail error: ' + err.message);
      }
    }

    // 2. Check local MySQL if connected
    if (pool) {
      try {
        const [rows] = await pool.query('SELECT * FROM sellers WHERE email = ? LIMIT 1', [cleanEmail]);
        if (rows && rows.length > 0) return rows[0];
      } catch (err) {
        // Fall through to memory
      }
    }

    // 3. In-memory store
    return memoryStores.get(cleanEmail) || null;
  }

  static async findByPhone(phone) {
    if (!phone) return null;
    const cleanPhone = phone.trim();

    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('sellers')
          .select('*')
          .eq('phone', cleanPhone)
          .maybeSingle();

        if (!error && data) return data;
      } catch (err) {
        logger.warn('Supabase findByPhone error: ' + err.message);
      }
    }

    if (pool) {
      try {
        const [rows] = await pool.query('SELECT * FROM sellers WHERE phone = ? LIMIT 1', [cleanPhone]);
        if (rows && rows.length > 0) return rows[0];
      } catch (err) {
        // Fall through
      }
    }

    for (const seller of memoryStores.values()) {
      if (seller.phone === cleanPhone) return seller;
    }
    return null;
  }

  static async create({ storeName, ownerName, email, phone, password }) {
    const cleanEmail = email.toLowerCase().trim();
    const cleanPhone = phone ? phone.trim() : null;
    const passwordHash = await bcrypt.hash(password, 10);

    // 1. Persist to Supabase PostgreSQL
    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('sellers')
          .insert([
            {
              store_name: storeName,
              owner_name: ownerName || storeName,
              email: cleanEmail,
              phone: cleanPhone,
              password_hash: passwordHash,
              role: 'seller',
              status: 'active'
            }
          ])
          .select()
          .single();

        if (!error && data) {
          memoryStores.set(cleanEmail, data);
          return data;
        }
      } catch (err) {
        logger.warn('Supabase insert seller error: ' + err.message);
      }
    }

    // 2. Persist to local MySQL
    if (pool) {
      try {
        const [result] = await pool.query(
          `INSERT INTO sellers (store_name, owner_name, email, phone, password_hash, role, status)
           VALUES (?, ?, ?, ?, ?, 'seller', 'active')`,
          [storeName, ownerName || storeName, cleanEmail, cleanPhone, passwordHash]
        );
        const newSeller = {
          id: result.insertId,
          store_name: storeName,
          owner_name: ownerName || storeName,
          email: cleanEmail,
          phone: cleanPhone,
          role: 'seller',
          status: 'active',
          created_at: new Date()
        };
        memoryStores.set(cleanEmail, newSeller);
        return newSeller;
      } catch (err) {
        // Fall through
      }
    }

    // 3. In-memory persistence
    const id = memoryStores.size + 1;
    const seller = {
      id,
      store_name: storeName,
      owner_name: ownerName || storeName,
      email: cleanEmail,
      phone: cleanPhone,
      password_hash: passwordHash,
      role: 'seller',
      status: 'active',
      created_at: new Date()
    };
    memoryStores.set(cleanEmail, seller);
    return seller;
  }
}

module.exports = SellerModel;
