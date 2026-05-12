require('dotenv').config();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '3306'),
  user:     process.env.DB_USER     || 'qexmanage',
  password: process.env.DB_PASSWORD || 'qexmanage_pass',
  database: process.env.DB_NAME     || 'qexmanage_pos',
  waitForConnections: true,
  connectionLimit:    20,
  queueLimit:         0,
  timezone:           '+05:30',
  charset:            'utf8mb4',
});

pool.on('connection', (conn) => {
  conn.query("SET SESSION sql_mode='STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO'");
});

const query = async (sql, params = []) => {
  const [rows] = await pool.execute(sql, params);
  return rows;
};

const queryOne = async (sql, params = []) => {
  const rows = await query(sql, params);
  return rows[0] || null;
};

const transaction = async (callback) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await callback(conn);
    await conn.commit();
    return result;
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
};

const testConnection = async () => {
  try {
    await pool.execute('SELECT 1');
    console.log('✅ MySQL connected successfully');
  } catch (err) {
    console.error('❌ MySQL connection failed:', err.message);
    process.exit(1);
  }
};

module.exports = { pool, query, queryOne, transaction, testConnection };
