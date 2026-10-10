const customersService = require('./customers.service');

class CustomersController {
  async getAll(req, res) {
    try {
      const { search } = req.query;
      const branchId = req.user.branch_id;
      const customers = await customersService.getAll(search, branchId);
      return res.status(200).json({ success: true, data: customers });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getUnpaid(req, res) {
    try {
      const branchId = req.user.branch_id;
      const unpaid = await customersService.getUnpaidCustomers(branchId);
      return res.status(200).json({ success: true, data: unpaid });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getById(req, res) {
    try {
      const { id } = req.params;
      const customer = await customersService.getById(id);
      return res.status(200).json({ success: true, data: customer });
    } catch (err) {
      return res.status(404).json({ success: false, error: err.message });
    }
  }

  async create(req, res) {
    try {
      const branchId = req.user.branch_id;
      const customer = await customersService.create(req.body, branchId);
      return res.status(201).json({ success: true, data: customer });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async update(req, res) {
    try {
      const { id } = req.params;
      const customer = await customersService.update(id, req.body);
      return res.status(200).json({ success: true, data: customer });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async delete(req, res) {
    try {
      const { id } = req.params;
      await customersService.delete(id);
      return res.status(200).json({ success: true, message: 'Customer deleted successfully' });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }
}

module.exports = new CustomersController();
