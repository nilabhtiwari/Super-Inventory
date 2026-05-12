const router = require('express').Router();
const ctrl = require('../controllers/settingsController');
const { authenticate, requireRole } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

router.use(authenticate);

router.get('/', ctrl.getSettings);
router.put('/', requireRole('admin'), validate(schemas.shopSettings), ctrl.updateSettings);

module.exports = router;
