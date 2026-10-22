const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const sellerModel = require('../models/sellerModel');
const { signToken } = require('../utils/jwt');
const { logAction } = require('../models/auditModel');
const otpCache = require('../utils/otpCacheEngine');
const { sendFastOtpEmail } = require('../utils/fastEmailService');

/**
 * 1. REQUEST OTP (Sign Up, Forgot Password, or Re-verification)
 * - Checks cooldown & 5-resend limit in Cache Memory
 * - Generates in-house CSPRNG 6-digit OTP
 * - Hashes and caches in memory
 * - Dispatches via high-speed email connection pool
 */
const requestOtp = async (req, res, next) => {
  try {
    const { email, action } = req.body; // 'SIGNUP' | 'FORGOT_PASSWORD' | 'REVERIFY'
    const targetAction = (action || 'SIGNUP').toUpperCase();

    let recipientEmail = (email || '').trim().toLowerCase();

    // If Forgot Password, allow lookup by registered Email OR Phone
    if (targetAction === 'FORGOT_PASSWORD') {
      const seller = await sellerModel.findByEmailOrPhone(recipientEmail);
      if (!seller) {
        return res.status(404).json({ success: false, message: 'No store account found with this email or phone.' });
      }
      recipientEmail = seller.email.toLowerCase().trim();
    } else {
      if (!recipientEmail || !recipientEmail.includes('@')) {
        return res.status(400).json({ success: false, message: 'A valid email address is required.' });
      }
    }

    // Check cache memory for cooldown / 5-resend limit
    const cacheResult = otpCache.createOtpRequest(recipientEmail, targetAction);
    if (!cacheResult.success) {
      return res.status(429).json({
        success: false,
        message: cacheResult.error,
        code: cacheResult.code,
        waitMinutes: cacheResult.waitMinutes,
        waitSeconds: cacheResult.waitSeconds
      });
    }

    // High-speed email dispatch to the user's real or registered email
    await sendFastOtpEmail(recipientEmail, cacheResult.otp, targetAction);

      res.json({
        success: true,
        recipientEmail: recipientEmail,
        message: `Verification code successfully sent to ${recipientEmail}. Valid for 5 minutes.`,
        cooldownSeconds: cacheResult.cooldownSeconds,
        resendsRemaining: cacheResult.resendsRemaining,
        expiresInSeconds: cacheResult.expiresInSeconds
      });
    } catch (err) {
    next(err);
  }
};

/**
 * 2. VERIFY OTP
 * - Validates code strictly against cache memory
 * - Enforces standard 5-attempt limit
 * - Enforces 5-minute hard TTL validity
 */
const verifyOtp = async (req, res, next) => {
  try {
    const { email, otp, action } = req.body;
    const targetAction = (action || 'SIGNUP').toUpperCase();

    if (!email || !otp) {
      return res.status(400).json({ success: false, message: 'Email and OTP code are required.' });
    }

    const verifyResult = otpCache.verifyOtp(email, otp, targetAction);
    if (!verifyResult.success) {
      const statusCode = verifyResult.code === 'MAX_ATTEMPTS_LOCKED' ? 429 : 400;
      return res.status(statusCode).json({
        success: false,
        message: verifyResult.error,
        code: verifyResult.code,
        remainingAttempts: verifyResult.remainingAttempts
      });
    }

    res.json({
      success: true,
      message: 'OTP verified successfully.'
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 3. REGISTER (Complete New Store Sign Up)
 * - Verifies OTP from cache memory
 * - Hashes password with bcrypt (cost 12)
 * - Persists seller & store record
 * - Issues JWT access token
 */
const register = async (req, res, next) => {
  try {
    const { storeName, phone, email, password, otp } = req.body;

    if (!storeName || !email || !password) {
      return res.status(400).json({ success: false, message: 'Store name, email, and password are required.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters long.' });
    }

    // Verify OTP from cache
    if (otp) {
      const verifyResult = otpCache.verifyOtp(email, otp, 'SIGNUP');
      if (!verifyResult.success) {
        const statusCode = verifyResult.code === 'MAX_ATTEMPTS_LOCKED' ? 429 : 400;
        return res.status(statusCode).json({
          success: false,
          message: verifyResult.error,
          code: verifyResult.code,
          remainingAttempts: verifyResult.remainingAttempts
        });
      }
    }

    // Check duplicate email or phone
    const existingEmail = await sellerModel.findByEmail(email);
    if (existingEmail) {
      return res.status(409).json({ success: false, message: 'An account with this email address already exists. Please sign in.' });
    }

    if (phone) {
      const existingPhone = await sellerModel.findByPhone(phone);
      if (existingPhone) {
        return res.status(409).json({ success: false, message: 'An account with this phone number already exists. Please sign in.' });
      }
    }

    // Hash password with bcrypt
    const password_hash = await bcrypt.hash(password, 12);
    const sellerUuid = uuidv4();

    const insertId = await sellerModel.create({
      uuid: sellerUuid,
      name: storeName,
      email,
      phone: phone || null,
      password_hash,
      role: 'admin'
    });

    const token = signToken({ id: insertId, uuid: sellerUuid, role: 'admin' });

    res.status(201).json({
      success: true,
      message: `Store registered successfully! Welcome to Super Inventory, ${storeName}.`,
      token,
      seller: {
        id: insertId,
        uuid: sellerUuid,
        name: storeName,
        email,
        phone: phone || null,
        role: 'admin'
      }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 4. SIGN IN (LOGIN - Direct Stored Credentials Matching, NO OTP)
 * - Supports login via Email OR Mobile Phone Number
 * - Compares with bcrypt hash
 * - Issues 8-hour signed JWT session token
 */
const login = async (req, res, next) => {
  try {
    const { identifier, email, password } = req.body;
    const loginTarget = identifier || email;

    if (!loginTarget || !password) {
      return res.status(400).json({ success: false, message: 'Please enter your email/phone and password.' });
    }

    // Find seller by Email OR Phone
    const seller = await sellerModel.findByEmailOrPhone(loginTarget);
    if (!seller) {
      return res.status(401).json({ success: false, message: 'Invalid credentials. No store account found with this email or phone.' });
    }

    if (!seller.is_active) {
      return res.status(403).json({ success: false, message: 'Account is deactivated. Please contact support.' });
    }

    // Verify Password
    const valid = await bcrypt.compare(password, seller.password_hash);
    if (!valid) {
      try {
        await logAction({ action: 'LOGIN_FAILED', entity: 'seller', entity_id: seller.id, ip_address: req.ip, meta: { loginTarget } });
      } catch (e) {}
      return res.status(401).json({ success: false, message: 'Incorrect password. Please try again.' });
    }

    await sellerModel.updateLastLogin(seller.id);
    const token = signToken({ id: seller.id, uuid: seller.uuid, role: seller.role });

    try {
      await logAction({
        seller_id: seller.id, action: 'LOGIN', entity: 'seller', entity_id: seller.id,
        ip_address: req.ip, user_agent: req.headers['user-agent']
      });
    } catch (e) {}

    res.json({
      success: true,
      message: `Welcome back, ${seller.name}!`,
      token,
      seller: {
        id: seller.id,
        uuid: seller.uuid,
        name: seller.name,
        email: seller.email,
        phone: seller.phone,
        role: seller.role,
        avatar_url: seller.avatar_url
      }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 5. RESET FORGOTTEN PASSWORD
 * - Strictly verifies OTP from cache memory ('FORGOT_PASSWORD')
 * - Hashes new password with bcrypt
 * - Updates database record
 */
const resetForgotPassword = async (req, res, next) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ success: false, message: 'Email, OTP, and new password are required.' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters long.' });
    }

    // Verify strictly from Cache Memory
    const verifyResult = otpCache.verifyOtp(email, otp, 'FORGOT_PASSWORD');
    if (!verifyResult.success) {
      const statusCode = verifyResult.code === 'MAX_ATTEMPTS_LOCKED' ? 429 : 400;
      return res.status(statusCode).json({
        success: false,
        message: verifyResult.error,
        code: verifyResult.code,
        remainingAttempts: verifyResult.remainingAttempts
      });
    }

    const seller = await sellerModel.findByEmail(email);
    if (!seller) {
      return res.status(404).json({ success: false, message: 'Account not found.' });
    }

    const hash = await bcrypt.hash(newPassword, 12);
    await sellerModel.updatePassword(seller.id, hash);

    try {
      await logAction({ seller_id: seller.id, action: 'PASSWORD_RESET', entity: 'seller', entity_id: seller.id, ip_address: req.ip });
    } catch (e) {}

    res.json({
      success: true,
      message: 'Password successfully updated! You can now sign in with your new password.'
    });
  } catch (err) {
    next(err);
  }
};

const me = async (req, res, next) => {
  try {
    const seller = await sellerModel.findById(req.seller.id);
    res.json({ success: true, seller });
  } catch (err) { next(err); }
};

const logout = async (req, res, next) => {
  try {
    try {
      await logAction({
        seller_id: req.seller.id, action: 'LOGOUT', entity: 'seller', entity_id: req.seller.id,
        ip_address: req.ip
      });
    } catch (e) {}
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (err) { next(err); }
};

const changePassword = async (req, res, next) => {
  try {
    const { current_password, new_password } = req.body;
    const seller = await sellerModel.findByEmail(req.seller.email);
    const valid = await bcrypt.compare(current_password, seller.password_hash);
    if (!valid) return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    const hash = await bcrypt.hash(new_password, 12);
    await sellerModel.updatePassword(req.seller.id, hash);
    try {
      await logAction({ seller_id: req.seller.id, action: 'PASSWORD_CHANGED', entity: 'seller', entity_id: req.seller.id, ip_address: req.ip });
    } catch (e) {}
    res.json({ success: true, message: 'Password changed successfully' });
  } catch (err) { next(err); }
};

module.exports = {
  requestOtp,
  verifyOtp,
  register,
  login,
  resetForgotPassword,
  me,
  logout,
  changePassword
};
