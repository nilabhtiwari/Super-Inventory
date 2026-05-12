const { query, queryOne } = require('../config/db');

const findByEmail = (email) =>
  queryOne('SELECT * FROM sellers WHERE email = ?', [email]);

const findById = (id) =>
  queryOne('SELECT id, uuid, name, email, phone, role, is_active, avatar_url, last_login, created_at FROM sellers WHERE id = ?', [id]);

const getAll = (includeInactive = false) =>
  query(
    `SELECT id, uuid, name, email, phone, role, is_active, last_login, created_at FROM sellers ${includeInactive ? '' : 'WHERE is_active = 1'} ORDER BY name`,
    []
  );

const create = async (data) => {
  const { uuid, name, email, phone, password_hash, role } = data;
  const result = await query(
    'INSERT INTO sellers (uuid, name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?, ?)',
    [uuid, name, email, phone || null, password_hash, role || 'seller']
  );
  return result.insertId;
};

const updateLastLogin = (id) =>
  query('UPDATE sellers SET last_login = NOW() WHERE id = ?', [id]);

const updateStatus = (id, is_active) =>
  query('UPDATE sellers SET is_active = ? WHERE id = ?', [is_active ? 1 : 0, id]);

const updateRole = (id, role) =>
  query('UPDATE sellers SET role = ? WHERE id = ?', [role, id]);

const updateProfile = (id, data) => {
  const { name, phone, avatar_url } = data;
  return query(
    'UPDATE sellers SET name = ?, phone = ?, avatar_url = ? WHERE id = ?',
    [name, phone || null, avatar_url || null, id]
  );
};

const updatePassword = (id, password_hash) =>
  query('UPDATE sellers SET password_hash = ? WHERE id = ?', [password_hash, id]);

module.exports = { findByEmail, findById, getAll, create, updateLastLogin, updateStatus, updateRole, updateProfile, updatePassword };
