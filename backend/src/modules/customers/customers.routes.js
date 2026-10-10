const express = require('express');
const customersController = require('./customers.controller');
const authMiddleware = require('../../middleware/auth');
const roleMiddleware = require('../../middleware/role');

const router = express.Router();

router.use(authMiddleware);

router.get('/', customersController.getAll);
router.get('/unpaid', customersController.getUnpaid);
router.get('/:id', customersController.getById);
router.post('/', customersController.create);
router.put('/:id', customersController.update);
router.delete('/:id', roleMiddleware('ADMIN'), customersController.delete);

module.exports = router;
