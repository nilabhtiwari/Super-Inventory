const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');
const logger = require('../config/logger');

/**
 * Super Inventory High-Speed Email Dispatch Service
 * - Pre-Warmed Connection Pool (Sub-Second Response)
 * - Branded HTML Templates for Sign Up, Forgot Password, and Re-Verification
 * - Zero Handshake Overhead
 */

let transporter = null;

function getCredentials() {
  let user = process.env.GMAIL_USER || process.env.SMTP_USER || '';
  let pass = (process.env.GMAIL_APP_PASSWORD || process.env.SMTP_PASSWORD || '').replace(/\s+/g, '');

  // If not in .env, check backend/email_config.json
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
    // Connection pooling keeps TCP/TLS connection warm in memory
    transporter = nodemailer.createTransport({
      pool: true,
      maxConnections: 5,
      maxMessages: 100,
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT || '587', 10),
      secure: false, // TLS
      auth: {
        user,
        pass
      },
      tls: {
        rejectUnauthorized: false
      }
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
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${title}</title>
    </head>
    <body style="margin: 0; padding: 24px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0b0f19; color: #ffffff;">
      <div style="max-width: 480px; margin: 0 auto; background-color: #151a28; border: 1px solid rgba(255, 255, 255, 0.12); border-radius: 28px; padding: 36px 28px; text-align: center; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);">
        
        <!-- App Branding -->
        <div style="display: inline-block; background: linear-gradient(135deg, #9333ea, #db2777); border-radius: 20px; padding: 14px 22px; margin-bottom: 20px; box-shadow: 0 10px 25px rgba(219, 39, 119, 0.35);">
          <span style="font-size: 22px; font-weight: 900; letter-spacing: 2px; color: #ffffff;">SUPER INVENTORY</span>
        </div>

        <h1 style="font-size: 20px; font-weight: 800; color: #ffffff; margin: 0 0 10px;">${title}</h1>
        <p style="font-size: 13.5px; color: #94a3b8; line-height: 1.6; margin: 0 0 24px;">${description}</p>

        <!-- 6-Digit OTP Box -->
        <div style="background: rgba(0, 0, 0, 0.45); border: 2px dashed rgba(236, 72, 153, 0.4); border-radius: 18px; padding: 20px; margin: 0 0 24px;">
          <div style="font-family: 'Courier New', Courier, monospace; font-size: 38px; font-weight: 900; letter-spacing: 10px; color: #f43f5e;">
            ${otpCode}
          </div>
          <div style="font-size: 11px; color: #cbd5e1; font-weight: bold; margin-top: 6px; letter-spacing: 0.5px;">
            VALID FOR 5 MINUTES ONLY
          </div>
        </div>

        <!-- Security Guidance -->
        <div style="background: rgba(255, 255, 255, 0.04); border-radius: 14px; padding: 14px; margin-bottom: 24px; text-align: left;">
          <div style="font-size: 11.5px; color: #e2e8f0; font-weight: 600; margin-bottom: 4px;">
            🔒 Security Notice:
          </div>
          <ul style="margin: 0; padding-left: 18px; font-size: 11px; color: #94a3b8; line-height: 1.5;">
            <li>Never share this code with anyone, including staff.</li>
            <li>Maximum 5 verification attempts permitted.</li>
            <li>If you did not request this, please secure your account immediately.</li>
          </ul>
        </div>

        <!-- Footer -->
        <div style="border-top: 1px solid rgba(255, 255, 255, 0.08); padding-top: 18px; font-size: 11px; color: #64748b;">
          &copy; ${new Date().getFullYear()} Super Inventory POS. All rights reserved.
        </div>
      </div>
    </body>
    </html>
  `;

  const { user: senderUser, pass: senderPass } = getCredentials();

  // If real credentials are provided, transmit through connection pool
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
      console.error(`\n❌ Failed to dispatch email via Gmail SMTP:`, sendError.message);
      console.log(`🔑 Fallback OTP for ${toEmail}: ${otpCode}\n`);
      throw sendError;
    }
  } else {
    // Sandbox / Dev Mode fallback (Logs real code so developer/tester is never blocked)
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
}

module.exports = { sendFastOtpEmail };
