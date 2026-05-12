const router = require('express').Router();
const ctrl = require('../controllers/adminController');
const { authenticate, requireRole } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

router.use(authenticate, requireRole('admin'));

router.get('/sellers', ctrl.getSellers);
router.post('/sellers', validate(schemas.createSeller), ctrl.createSeller);
router.patch('/sellers/:id/status', ctrl.updateSellerStatus);
router.patch('/sellers/:id/role', ctrl.updateSellerRole);
router.get('/audit-logs', ctrl.getAuditLogsHandler);

module.exports = router;
