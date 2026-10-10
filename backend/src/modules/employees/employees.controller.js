const employeesService = require('./employees.service');

class EmployeesController {
  async getAll(req, res) {
    try {
      const branchId = req.user.branch_id;
      const employees = await employeesService.getAll(branchId);
      return res.status(200).json({ success: true, data: employees });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async create(req, res) {
    try {
      const branchId = req.user.branch_id;
      const employee = await employeesService.create(req.body, branchId);
      return res.status(201).json({ success: true, data: employee });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async delete(req, res) {
    try {
      const { id } = req.params;
      await employeesService.delete(id);
      return res.status(200).json({ success: true, message: 'Employee deleted successfully' });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }
}

module.exports = new EmployeesController();
