const cron = require('node-cron');
const inventoryService = require('../modules/inventory/inventory.service');

// Start cron tasks
const startScheduler = () => {
  console.log('[CRON SERVICE] Initializing scheduled stock checkers...');

  // Run stock inventory checks daily at 9:00 AM
  cron.schedule('0 9 * * *', async () => {
    try {
      console.log('[CRON CHECK] Running automated daily supply stock checker...');
      const alerts = await inventoryService.getLowStockAlerts();
      
      if (alerts.length > 0) {
        console.log(`[CRON ALERT SYSTEM] Low stock detected on ${alerts.length} item(s):`);
        alerts.forEach(alert => {
          if (alert.status === 'CRITICAL') {
            console.error(`[PUSH ALERT - CRITICAL] ${alert.message}`);
          } else {
            console.warn(`[PUSH ALERT - WARNING] ${alert.message}`);
          }
        });
      } else {
        console.log('[CRON CHECK] All inventory levels within optimal thresholds.');
      }
    } catch (err) {
      console.error('[CRON CHECK ERROR] Scheduled checker failed: ', err.message);
    }
  });
};

module.exports = { startScheduler };
