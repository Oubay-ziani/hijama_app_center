const financeService = require('./finance.service');

class FinanceController {
  async getStats(req, res) {
    try {
      const branchId = req.user.branch_id;
      const stats = await financeService.getDashboardStats(branchId);
      return res.status(200).json({ success: true, data: stats });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getProfits(req, res) {
    try {
      const { period } = req.query; // 'daily', 'weekly', 'monthly', 'yearly'
      const breakdown = await financeService.getProfitBreakdown(period || 'monthly');
      return res.status(200).json({ success: true, data: breakdown });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getCharts(req, res) {
    try {
      const charts = await financeService.getChartsData();
      return res.status(200).json({ success: true, data: charts });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }
}

module.exports = new FinanceController();
