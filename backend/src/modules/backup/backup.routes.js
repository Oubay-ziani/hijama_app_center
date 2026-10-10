const express = require('express');
const backupController = require('./backup.controller');
const authMiddleware = require('../../middleware/auth');
const roleMiddleware = require('../../middleware/role');

const router = express.Router();

router.use(authMiddleware);
router.use(roleMiddleware('ADMIN')); // RESTRICT ALL to Admin only

router.get('/export', backupController.export);
router.post('/import', backupController.import);

module.exports = router;
