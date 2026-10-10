const dotenv = require('dotenv');
const path = require('path');

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../../.env') });

module.exports = {
  PORT: process.env.PORT || 3000,
  DATABASE_URL: process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/hijama',
  JWT_SECRET: process.env.JWT_SECRET || 'supersecretkeyforhijamaclinicpro2026!',
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'anotherrefreshsupersecretkeyforhijamaclinic2026!',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '1d',
  JWT_REFRESH_EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  NODE_ENV: process.env.NODE_ENV || 'development'
};
