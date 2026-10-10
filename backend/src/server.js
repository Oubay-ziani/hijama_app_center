const app = require('./app');
const env = require('./config/env');
const db = require('./config/db');
const cron = require('./services/cron');

const startServer = async () => {
  try {
    // 1. Initialise tables, triggers, and seed admin accounts
    await db.initDb();

    // 2. Initialise scheduled background stock trackers
    cron.startScheduler();

    // 3. Bind HTTP listener
    app.listen(env.PORT, () => {
      console.log(`=========================================`);
      console.log(` HIJAMA CENTER PRO SERVER RUNNING        `);
      console.log(` Port: ${env.PORT}                      `);
      console.log(` Mode: ${env.NODE_ENV}                  `);
      console.log(`=========================================`);
    });
  } catch (err) {
    console.error('Fatal initialization failure. Shutdown: ', err.message);
    process.exit(1);
  }
};

startServer();
