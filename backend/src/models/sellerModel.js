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
    name: 'Super Inventory Flagship',
    owner_name: 'Merchant Partner',
    email: 'merchant@gmail.com',
    phone: '9876543210',
    password_hash: hash,
    role: 'seller',
    status: 'active',
    is_active: 1,
    created_at: new Date()
  });
})();

class SellerModel {
  static normalize(raw) {
    if (!raw) return null;
    return {
      id: raw.id,
      uuid: raw.uuid || `seller-${raw.id}`,
      name: raw.name || raw.store_name || raw.owner_name || 'Super Inventory Store',
      store_name: raw.store_name || raw.name || 'Super Inventory Store',
      owner_name: raw.owner_name || raw.name || raw.store_name || 'Store Owner',
      email: raw.email,
      phone: raw.phone || null,
      password_hash: raw.password_hash,
      role: raw.role || 'seller',
      status: raw.status || 'active',
      is_active: (raw.status === 'active' || raw.is_active === 1 || raw.is_active === true) ? 1 : 1,
      avatar_url: raw.avatar_url || null,
      created_at: raw.created_at || new Date()
    };
  }

  static async findByEmail(email) {
    if (!email) return null;
    const cleanEmail = email.toLowerCase().trim();

    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('sellers')
          .select('*')
          .eq('email', cleanEmail)
          .maybeSingle();

        if (!error && data) return SellerModel.normalize(data);
      } catch (err) {
        logger.warn('Supabase findByEmail error: ' + err.message);
      }
    }

    if (pool) {
      try {
        const [rows] = await pool.query('SELECT * FROM sellers WHERE email = ? LIMIT 1', [cleanEmail]);
        if (rows && rows.length > 0) return SellerModel.normalize(rows[0]);
      } catch (err) {}
    }

    const mem = memoryStores.get(cleanEmail);
    return mem ? SellerModel.normalize(mem) : null;
  }

  static async findByPhone(phone) {
    if (!phone) return null;
    const cleanPhone = phone.replace(/[^0-9]/g, '').slice(-10);

    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('sellers')
          .select('*')
          .ilike('phone', `%${cleanPhone}%`)
          .maybeSingle();

        if (!error && data) return SellerModel.normalize(data);
      } catch (err) {
        logger.warn('Supabase findByPhone error: ' + err.message);
      }
    }

    if (pool) {
      try {
        const [rows] = await pool.query('SELECT * FROM sellers WHERE phone LIKE ? LIMIT 1', [`%${cleanPhone}%`]);
        if (rows && rows.length > 0) return SellerModel.normalize(rows[0]);
      } catch (err) {}
    }

    for (const seller of memoryStores.values()) {
      const p = (seller.phone || '').replace(/[^0-9]/g, '').slice(-10);
      if (p && p === cleanPhone) return SellerModel.normalize(seller);
    }
    return null;
  }

  static async findByEmailOrPhone(identifier) {
    if (!identifier) return null;
    const cleanId = identifier.trim();
    if (cleanId.includes('@')) {
      return await SellerModel.findByEmail(cleanId);
    }
    return (await SellerModel.findByPhone(cleanId)) || (await SellerModel.findByEmail(cleanId));
  }

  static async updateLastLogin(id) {
    if (supabase && id) {
      try {
        await supabase.from('sellers').update({ updated_at: new Date() }).eq('id', id);
      } catch (e) {}
    }
  }

  static async create(payload) {
    const storeName = payload.storeName || payload.name || 'Super Inventory Store';
    const ownerName = payload.ownerName || storeName;
    const cleanEmail = (payload.email || '').toLowerCase().trim();
    const cleanPhone = payload.phone ? payload.phone.trim() : null;
    const passwordHash = payload.password_hash || (payload.password ? await bcrypt.hash(payload.password, 10) : '');

    // 1. Persist to Supabase PostgreSQL
    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('sellers')
          .insert([
            {
              store_name: storeName,
              owner_name: ownerName,
              email: cleanEmail,
              phone: cleanPhone,
              password_hash: passwordHash,
              role: payload.role || 'seller',
              status: 'active'
            }
          ])
          .select()
          .single();

        if (!error && data) {
          const norm = SellerModel.normalize(data);
          memoryStores.set(cleanEmail, norm);
          return norm.id || data.id;
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
          [storeName, ownerName, cleanEmail, cleanPhone, passwordHash]
        );
        const newSeller = SellerModel.normalize({
          id: result.insertId,
          store_name: storeName,
          owner_name: ownerName,
          email: cleanEmail,
          phone: cleanPhone,
          role: payload.role || 'seller',
          status: 'active'
        });
        memoryStores.set(cleanEmail, newSeller);
        return result.insertId;
      } catch (err) {}
    }

    // 3. In-memory persistence
    const id = memoryStores.size + 1;
    const seller = SellerModel.normalize({
      id,
      store_name: storeName,
      name: storeName,
      owner_name: ownerName,
      email: cleanEmail,
      phone: cleanPhone,
      password_hash: passwordHash,
      role: payload.role || 'seller',
      status: 'active',
      created_at: new Date()
    });
    memoryStores.set(cleanEmail, seller);
    return id;
  }
}

module.exports = SellerModel;
