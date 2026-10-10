const express = require('express');
const expensesController = require('./expenses.controller');
const authMiddleware = require('../../middleware/auth');
const roleMiddleware = require('../../middleware/role');

const router = express.Router();

router.use(authMiddleware);
router.use(roleMiddleware('ADMIN')); // RESTRICT ALL to Admin only

router.get('/', expensesController.getAll);
router.post('/', expensesController.create);
router.delete('/:id', expensesController.delete);

module.exports = router;
