const pdfService = require('../../services/pdf');
const excelService = require('../../services/excel');
const financeService = require('../finance/finance.service');
const inventoryService = require('../inventory/inventory.service');
const sessionsService = require('../sessions/sessions.service');
const db = require('../../config/db');

class ReportsService {
  async getDailyReportPdf(stream, branchId) {
    const stats = await financeService.getDashboardStats(branchId);
    const dateStr = new Date().toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
    pdfService.generateDailyReport(stream, stats, dateStr);
  }

  async getInventoryReportPdf(stream, branchId) {
    const items = await inventoryService.getAll(branchId);
    pdfService.generateInventoryReport(stream, items);
  }

  async getSessionInvoicePdf(stream, sessionId) {
    const session = await sessionsService.getById(sessionId);
    pdfService.generateSessionInvoice(stream, session);
  }

  async getMonthlyFinancialExcel(stream) {
    const monthInterval = "1 month";
    
    const sessionsRes = await db.query(
      `SELECT s.*, c.full_name as customer_name, u.name as employee_name
       FROM sessions s
       JOIN customers c ON s.customer_id = c.id
       LEFT JOIN users u ON s.user_id = u.id
       WHERE s.date >= NOW() - INTERVAL '${monthInterval}'
       ORDER BY s.date DESC`
    );

    const expensesRes = await db.query(
      `SELECT * FROM expenses 
       WHERE date >= NOW() - INTERVAL '${monthInterval}'
       ORDER BY date DESC`
    );

    const purchasesRes = await db.query(
      `SELECT p.*, i.name as item_name
       FROM purchases p
       JOIN inventory_items i ON p.inventory_item_id = i.id
       WHERE p.date >= NOW() - INTERVAL '${monthInterval}'
       ORDER BY p.date DESC`
    );

    await excelService.generateMonthlyFinancialExcel(
      stream,
      sessionsRes.rows,
      expensesRes.rows,
      purchasesRes.rows
    );
  }
}

module.exports = new ReportsService();
