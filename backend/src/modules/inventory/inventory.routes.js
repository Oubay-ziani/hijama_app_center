const express = require('express');
const inventoryController = require('./inventory.controller');
const authMiddleware = require('../../middleware/auth');
const roleMiddleware = require('../../middleware/role');

const router = express.Router();

router.use(authMiddleware);

router.get('/', inventoryController.getAll);
router.get('/alerts', inventoryController.getAlerts);
router.get('/purchases', roleMiddleware('ADMIN'), inventoryController.getPurchases);
router.get('/:id', inventoryController.getById);

router.post('/', roleMiddleware('ADMIN'), inventoryController.create);
router.put('/:id', roleMiddleware('ADMIN'), inventoryController.update);
router.post('/purchases', roleMiddleware('ADMIN'), inventoryController.addPurchase);

module.exports = router;
