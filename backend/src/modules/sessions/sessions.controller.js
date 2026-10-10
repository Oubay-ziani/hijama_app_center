const sessionsService = require('./sessions.service');

class SessionsController {
  async getAll(req, res) {
    try {
      const { customerId, startDate, endDate } = req.query;
      const sessions = await sessionsService.getAll(customerId, startDate, endDate);
      return res.status(200).json({ success: true, data: sessions });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getById(req, res) {
    try {
      const { id } = req.params;
      const session = await sessionsService.getById(id);
      return res.status(200).json({ success: true, data: session });
    } catch (err) {
      return res.status(404).json({ success: false, error: err.message });
    }
  }

  async create(req, res) {
    try {
      const userId = req.user.id;
      const session = await sessionsService.create(req.body, userId);
      return res.status(201).json({ success: true, data: session });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }
}

module.exports = new SessionsController();
