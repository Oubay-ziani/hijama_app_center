const express = require('express');
const employeesController = require('./employees.controller');
const authMiddleware = require('../../middleware/auth');
const roleMiddleware = require('../../middleware/role');

const router = express.Router();

router.use(authMiddleware);
router.use(roleMiddleware('ADMIN')); // RESTRICT ALL to Admin only

router.get('/', employeesController.getAll);
router.post('/', employeesController.create);
router.delete('/:id', employeesController.delete);

module.exports = router;
