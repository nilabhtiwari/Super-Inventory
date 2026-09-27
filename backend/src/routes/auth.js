const router = require('express').Router();
const {
  requestOtp,
  verifyOtp,
  register,
  login,
  resetForgotPassword,
  me,
  logout,
  changePassword
} = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { loginLimiter } = require('../middleware/rateLimiter');

// OTP Endpoints (Sign Up, Forgot Password, Re-verification)
router.post('/otp/request', requestOtp);
router.post('/otp/verify', verifyOtp);

// Registration & Login
router.post('/register', register);
router.post('/login', loginLimiter, login);

// Password Management
router.post('/forgot-password/reset', resetForgotPassword);
router.post('/change-password', authenticate, changePassword);

// Session Endpoints
router.get('/me', authenticate, me);
router.post('/logout', authenticate, logout);

module.exports = router;
