const appointmentsService = require('./appointments.service');

class AppointmentsController {
  async getAll(req, res) {
    try {
      const { startDate, endDate } = req.query;
      const appointments = await appointmentsService.getAll(startDate, endDate);
      return res.status(200).json({ success: true, data: appointments });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async getById(req, res) {
    try {
      const { id } = req.params;
      const appointment = await appointmentsService.getById(id);
      return res.status(200).json({ success: true, data: appointment });
    } catch (err) {
      return res.status(404).json({ success: false, error: err.message });
    }
  }

  async create(req, res) {
    try {
      const appointment = await appointmentsService.create(req.body);
      return res.status(201).json({ success: true, data: appointment });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async update(req, res) {
    try {
      const { id } = req.params;
      const appointment = await appointmentsService.update(id, req.body);
      return res.status(200).json({ success: true, data: appointment });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async delete(req, res) {
    try {
      const { id } = req.params;
      await appointmentsService.delete(id);
      return res.status(200).json({ success: true, message: 'Appointment cancelled/deleted successfully' });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async getAlerts(req, res) {
    try {
      const alerts = await appointmentsService.getUpcomingAlerts();
      return res.status(200).json({ success: true, data: alerts });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }
}

module.exports = new AppointmentsController();
