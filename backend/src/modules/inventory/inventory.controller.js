const inventoryService = require('./inventory.service');

class InventoryController {
  async getAll(req, res) {
    try {
      const branchId = req.user.branch_id;
      const items = await inventoryService.getAll(branchId);
      return res.status(200).json({ success: true, data: items });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getById(req, res) {
    try {
      const { id } = req.params;
      const item = await inventoryService.getById(id);
      return res.status(200).json({ success: true, data: item });
    } catch (err) {
      return res.status(404).json({ success: false, error: err.message });
    }
  }

  async create(req, res) {
    try {
      const branchId = req.user.branch_id;
      const item = await inventoryService.create(req.body, branchId);
      return res.status(201).json({ success: true, data: item });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async update(req, res) {
    try {
      const { id } = req.params;
      const item = await inventoryService.update(id, req.body);
      return res.status(200).json({ success: true, data: item });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async addPurchase(req, res) {
    try {
      const branchId = req.user.branch_id;
      const purchase = await inventoryService.addPurchase(req.body, branchId);
      return res.status(201).json({ success: true, data: purchase });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async getPurchases(req, res) {
    try {
      const history = await inventoryService.getPurchaseHistory();
      return res.status(200).json({ success: true, data: history });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getAlerts(req, res) {
    try {
      const branchId = req.user.branch_id;
      const alerts = await inventoryService.getLowStockAlerts(branchId);
      return res.status(200).json({ success: true, data: alerts });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }
}

module.exports = new InventoryController();
