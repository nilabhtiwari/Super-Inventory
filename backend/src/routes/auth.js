const router = require('express').Router();
const { login, me, logout, changePassword } = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');
const { loginLimiter } = require('../middleware/rateLimiter');
const { z } = require('zod');

router.post('/login', loginLimiter, validate(schemas.login), login);
router.get('/me', authenticate, me);
router.post('/logout', authenticate, logout);
router.post('/change-password', authenticate, validate(z.object({
  current_password: z.string().min(1),
  new_password: z.string().min(8),
})), changePassword);

module.exports = router;
