const router = require('express').Router();
const ctrl = require('../controllers/inventoryController');
const { authenticate, requireRole } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

router.use(authenticate);

router.get('/low-stock', ctrl.getLowStock);
router.post('/adjust', requireRole('admin', 'manager'), validate(schemas.stockAdjust), ctrl.adjustStock);
router.get('/movements', requireRole('admin', 'manager'), ctrl.getMovements);

module.exports = router;
