const router = require('express').Router();
const ctrl = require('../controllers/productsController');
const { authenticate, requireRole } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');
const { barcodeLimiter } = require('../middleware/rateLimiter');

// All product routes require authentication
router.use(authenticate);

// Barcode lookup — fast, used by POS screen
router.get('/barcode/:code', barcodeLimiter, ctrl.getByBarcode);

// Category routes
router.get('/categories', ctrl.getCategories);
router.post('/categories', requireRole('admin', 'manager'), ctrl.createCategory);

// Low stock alert
router.get('/low-stock', requireRole('admin', 'manager'), ctrl.getLowStock);

// Product CRUD
router.get('/', ctrl.getAll);
router.get('/:id', ctrl.getOne);
router.post('/', requireRole('admin', 'manager'), validate(schemas.createProduct), ctrl.create);
router.put('/:id', requireRole('admin', 'manager'), validate(schemas.createProduct), ctrl.update);
router.delete('/:id', requireRole('admin', 'manager'), ctrl.remove);

module.exports = router;
