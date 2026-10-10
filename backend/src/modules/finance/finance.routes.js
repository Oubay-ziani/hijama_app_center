const express = require('express');
const financeController = require('./finance.controller');
const authMiddleware = require('../../middleware/auth');
const roleMiddleware = require('../../middleware/role');

const router = express.Router();

router.use(authMiddleware);
router.use(roleMiddleware('ADMIN')); // RESTRICT ALL to Admin only

router.get('/stats', financeController.getStats);
router.get('/profits', financeController.getProfits);
router.get('/charts', financeController.getCharts);

module.exports = router;
