const { createClient } = require('@supabase/supabase-js');
const logger = require('./logger');

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || '';

let supabase = null;

if (supabaseUrl && supabaseKey) {
  try {
    supabase = createClient(supabaseUrl, supabaseKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false
      }
    });
    logger.info(' Connected to Supabase Cloud PostgreSQL & Storage');
  } catch (err) {
    logger.warn('⚠️ Supabase client initialization warning: ' + err.message);
  }
} else {
  logger.info('ℹ️ Supabase credentials not set in .env. Resilient local fallback ready.');
}

module.exports = { supabase };
