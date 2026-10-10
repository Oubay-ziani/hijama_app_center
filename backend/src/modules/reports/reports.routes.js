const express = require('express');
const reportsController = require('./reports.controller');
const authMiddleware = require('../../middleware/auth');
const roleMiddleware = require('../../middleware/role');

const router = express.Router();

router.use(authMiddleware);

// Invoices can be downloaded by everyone
router.get('/sessions/:id/invoice', reportsController.getInvoicePdf);

// General summaries restricted to Admin
router.get('/daily/pdf', roleMiddleware('ADMIN'), reportsController.getDailyPdf);
router.get('/inventory/pdf', roleMiddleware('ADMIN'), reportsController.getInventoryPdf);
router.get('/monthly/excel', roleMiddleware('ADMIN'), reportsController.getMonthlyExcel);

module.exports = router;
