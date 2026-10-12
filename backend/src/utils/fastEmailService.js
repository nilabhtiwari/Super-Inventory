const { Resend } = require('resend');
const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');
const logger = require('../config/logger');

/**
 * Super Inventory High-Speed Email Dispatch Service
 * Priority:
 * 1. Resend.com Official API (Fastest, zero-latency HTTP API, production recommended)
 * 2. Gmail / Custom SMTP via Connection Pool (Fallback)
 * 3. Local Sandbox Logging (Ensures dev & verification are never blocked)
 */

let resendClient = null;
if (process.env.RESEND_API_KEY) {
  try {
    resendClient = new Resend(process.env.RESEND_API_KEY);
    logger.info('🚀 Resend.com Email API active');
  } catch (e) {
    logger.warn('⚠️ Resend client initialization failed: ' + e.message);
  }
}

let transporter = null;

function getCredentials() {
  let user = process.env.GMAIL_USER || process.env.SMTP_USER || '';
  let pass = (process.env.GMAIL_APP_PASSWORD || process.env.SMTP_PASSWORD || '').replace(/\s+/g, '');

  if (!user || !pass || user.includes('your_email')) {
    try {
      const configPath = path.join(__dirname, '../../email_config.json');
      if (fs.existsSync(configPath)) {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        if (config.gmail_sender && config.gmail_app_password && !config.gmail_sender.includes('your_email')) {
          user = config.gmail_sender.trim();
          pass = (config.gmail_app_password || '').replace(/\s+/g, '');
        }
      }
    } catch (e) {
      // ignore
    }
  }

  return { user, pass };
}

function getTransporter() {
  const { user, pass } = getCredentials();
  if (!transporter) {
    transporter = nodemailer.createTransport({
      pool: true,
      maxConnections: 5,
      maxMessages: 100,
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT || '587', 10),
      secure: false,
      auth: { user, pass },
      tls: { rejectUnauthorized: false }
    });
  }
  return transporter;
}

/**
 * Dispatches high-speed branded OTP email
 * @param {string} toEmail
 * @param {string} otpCode
 * @param {string} action - 'SIGNUP' | 'FORGOT_PASSWORD' | 'REVERIFY'
 */
async function sendFastOtpEmail(toEmail, otpCode, action = 'SIGNUP') {
  const titles = {
    SIGNUP: 'Store Registration Security Code',
    FORGOT_PASSWORD: 'Password Reset Verification',
    REVERIFY: 'Email Re-Verification Code'
  };

  const descriptions = {
    SIGNUP: 'Thank you for choosing Super Inventory. Use this 6-digit code to verify your email and complete store registration:',
    FORGOT_PASSWORD: 'We received a request to reset your Super Inventory account password. Use this 6-digit verification code:',
    REVERIFY: 'Use this 6-digit verification code to re-verify your Super Inventory email address:'
  };

  const title = titles[action] || 'Security Verification Code';
  const description = descriptions[action] || 'Use this 6-digit code to verify your account:';

  const htmlContent = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>${title}</title>
    </head>
    <body style="margin: 0; padding: 24px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #0b0f19; color: #ffffff;">
      <div style="max-width: 480px; margin: 0 auto; background-color: #151a28; border: 1px solid rgba(255, 255, 255, 0.12); border-radius: 28px; padding: 36px 28px; text-align: center;">
        <div style="display: inline-block; background: linear-gradient(135deg, #9333ea, #db2777); border-radius: 20px; padding: 14px 22px; margin-bottom: 20px;">
          <span style="font-size: 22px; font-weight: 900; letter-spacing: 2px; color: #ffffff;">SUPER INVENTORY</span>
        </div>
        <h1 style="font-size: 20px; font-weight: 800; color: #ffffff; margin: 0 0 10px;">${title}</h1>
        <p style="font-size: 13.5px; color: #94a3b8; line-height: 1.6; margin: 0 0 24px;">${description}</p>
        <div style="background: rgba(0, 0, 0, 0.45); border: 2px dashed rgba(236, 72, 153, 0.4); border-radius: 18px; padding: 20px; margin: 0 0 24px;">
          <div style="font-family: 'Courier New', monospace; font-size: 38px; font-weight: 900; letter-spacing: 10px; color: #f43f5e;">
            ${otpCode}
          </div>
          <div style="font-size: 11px; color: #cbd5e1; font-weight: bold; margin-top: 6px;">
            VALID FOR 5 MINUTES ONLY
          </div>
        </div>
        <div style="background: rgba(255, 255, 255, 0.04); border-radius: 14px; padding: 14px; text-align: left; font-size: 11px; color: #94a3b8;">
          🔒 Never share this code with anyone. Maximum 5 attempts permitted.
        </div>
      </div>
    </body>
    </html>
  `;

  // 1. Try Resend API (production standard)
  if (resendClient || process.env.RESEND_API_KEY) {
    try {
      const client = resendClient || new Resend(process.env.RESEND_API_KEY);
      const fromAddr = process.env.RESEND_FROM_EMAIL || 'Super Inventory <onboarding@resend.dev>';
      const data = await client.emails.send({
        from: fromAddr,
        to: toEmail,
        subject: `Super Inventory - Your OTP is ${otpCode} [Valid 5 Min]`,
        html: htmlContent
      });
      console.log(`\n=============================================================`);
      console.log(`📧 [REAL EMAIL SENT VIA RESEND API]`);
      console.log(`📬 Sent To    : ${toEmail}`);
      console.log(`🔑 OTP Code   : ${otpCode}`);
      console.log(`🚀 Resend ID  : ${data.id || JSON.stringify(data)}`);
      console.log(`=============================================================\n`);
      return data;
    } catch (resendErr) {
      console.warn(`⚠️ Resend dispatch error: ${resendErr.message}. Falling back...`);
    }
  }

  // 2. Try Gmail SMTP if configured
  const { user: senderUser, pass: senderPass } = getCredentials();
  if (senderUser && senderPass && !senderUser.includes('your_email')) {
    const mailer = getTransporter();
    try {
      const info = await mailer.sendMail({
        from: `"Super Inventory" <${senderUser}>`,
        to: toEmail,
        subject: `Super Inventory - Your OTP is ${otpCode} [Valid 5 Min]`,
        html: htmlContent
      });
      console.log(`\n=============================================================`);
      console.log(`📧 [REAL EMAIL SENT VIA GMAIL SMTP]`);
      console.log(`📬 Sent To    : ${toEmail}`);
      console.log(`🔑 OTP Code   : ${otpCode}`);
      console.log(`🚀 Message ID : ${info.messageId}`);
      console.log(`=============================================================\n`);
      return info;
    } catch (sendError) {
      console.error(`\n❌ Failed via Gmail SMTP:`, sendError.message);
    }
  }

  // 3. Fallback Sandbox Mode
  console.log(`\n=============================================================`);
  console.log(`📧 [SUPER INVENTORY DISPATCH] ${title}`);
  console.log(`📬 Recipient : ${toEmail}`);
  console.log(`🔑 Real OTP   : ${otpCode} (Valid 5 Minutes)`);
  console.log(`⏱ Action     : ${action}`);
  console.log(`=============================================================\n`);

  return {
    messageId: `sandbox-${Date.now()}`,
    sandbox: true,
    recipient: toEmail
  };
}

module.exports = { sendFastOtpEmail };
