const router = require('express').Router();
const ctrl = require('../controllers/salesController');
const { authenticate } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

router.use(authenticate);

router.post('/', validate(schemas.createSale), ctrl.createSale);
router.get('/', ctrl.getSales);
router.get('/:id', ctrl.getSaleById);

module.exports = router;
