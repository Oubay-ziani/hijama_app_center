const express = require('express');
const cors = require('cors');

// Import Routers
const authRoutes = require('./modules/auth/auth.routes');
const customerRoutes = require('./modules/customers/customers.routes');
const sessionRoutes = require('./modules/sessions/sessions.routes');
const inventoryRoutes = require('./modules/inventory/inventory.routes');
const appointmentRoutes = require('./modules/appointments/appointments.routes');
const expenseRoutes = require('./modules/expenses/expenses.routes');
const financeRoutes = require('./modules/finance/finance.routes');
const reportRoutes = require('./modules/reports/reports.routes');
const employeeRoutes = require('./modules/employees/employees.routes');
const backupRoutes = require('./modules/backup/backup.routes');

const app = express();

// Configs
app.use(cors());
app.use(express.json());

// Routes registry
app.use('/api/auth', authRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/finance', financeRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/backup', backupRoutes);

// Base route checker
app.get('/health', (req, res) => {
  return res.status(200).json({ success: true, status: 'Hijama Center Pro Backend Running' });
});

// Fallback path handler
app.use((req, res) => {
  return res.status(404).json({ success: false, error: 'Endpoint path not found' });
});

// Global Error boundary handler
app.use((err, req, res, next) => {
  console.error('[SERVER ERROR HANDLER]', err);
  return res.status(500).json({ 
    success: false, 
    error: err.message || 'Internal server error occurred' 
  });
});

module.exports = app;
