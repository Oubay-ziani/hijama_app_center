const backupService = require('./backup.service');

class BackupController {
  async export(req, res) {
    try {
      const backup = await backupService.exportDb();
      return res.status(200).json({ success: true, ...backup });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  async import(req, res) {
    try {
      const { backupData } = req.body;
      if (!backupData) {
        return res.status(400).json({ success: false, error: 'Backup data payload is required' });
      }

      await backupService.importDb(backupData);
      return res.status(200).json({ success: true, message: 'Database restored successfully from backup snapshot' });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }
}

module.exports = new BackupController();
