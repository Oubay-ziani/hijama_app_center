const reportsService = require('./reports.service');

class ReportsController {
  async getDailyPdf(req, res) {
    try {
      const branchId = req.user.branch_id;
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename="daily-report.pdf"');
      
      await reportsService.getDailyReportPdf(res, branchId);
    } catch (err) {
      console.error(err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getInventoryPdf(req, res) {
    try {
      const branchId = req.user.branch_id;
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename="inventory-report.pdf"');
      
      await reportsService.getInventoryReportPdf(res, branchId);
    } catch (err) {
      console.error(err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getInvoicePdf(req, res) {
    try {
      const { id } = req.params;
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="invoice-${id}.pdf"`);
      
      await reportsService.getSessionInvoicePdf(res, id);
    } catch (err) {
      console.error(err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getMonthlyExcel(req, res) {
    try {
      res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      );
      res.setHeader('Content-Disposition', 'attachment; filename="monthly-report.xlsx"');
      
      await reportsService.getMonthlyFinancialExcel(res);
    } catch (err) {
      console.error(err);
      return res.status(500).json({ success: false, error: err.message });
    }
  }
}

module.exports = new ReportsController();
