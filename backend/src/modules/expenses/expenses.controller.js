const expensesService = require('./expenses.service');

class ExpensesController {
  async getAll(req, res) {
    try {
      const branchId = req.user.branch_id;
      const expenses = await expensesService.getAll(branchId);
      return res.status(200).json({ success: true, data: expenses });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async create(req, res) {
    try {
      const branchId = req.user.branch_id;
      const expense = await expensesService.create(req.body, branchId);
      return res.status(201).json({ success: true, data: expense });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async delete(req, res) {
    try {
      const { id } = req.params;
      await expensesService.delete(id);
      return res.status(200).json({ success: true, message: 'Expense deleted successfully' });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }
}

module.exports = new ExpensesController();
