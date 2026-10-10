const db = require('../../config/db');

class FinanceService {
  async getDashboardStats(branchId = null) {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    // 1. Total customers served today
    const custRes = await db.query(
      `SELECT COUNT(DISTINCT customer_id) as count 
       FROM sessions 
       WHERE date BETWEEN $1 AND $2`,
      [todayStart, todayEnd]
    );
    const customersToday = parseInt(custRes.rows[0].count || 0);

    // 2. Revenue today
    const revRes = await db.query(
      `SELECT COALESCE(SUM(price_paid), 0) as total 
       FROM sessions 
       WHERE date BETWEEN $1 AND $2`,
      [todayStart, todayEnd]
    );
    const revenueToday = parseFloat(revRes.rows[0].total || 0);

    // 3. Expenses today (overhead)
    const expRes = await db.query(
      `SELECT COALESCE(SUM(amount), 0) as total 
       FROM expenses 
       WHERE date BETWEEN $1 AND $2`,
      [todayStart, todayEnd]
    );
    const expensesToday = parseFloat(expRes.rows[0].total || 0);

    // 4. Consumables cost today
    const consRes = await db.query(
      `SELECT COALESCE(SUM(sm.quantity_used * i.purchase_price), 0) as total
       FROM session_materials sm
       JOIN sessions s ON sm.session_id = s.id
       JOIN inventory_items i ON sm.inventory_item_id = i.id
       WHERE s.date BETWEEN $1 AND $2`,
      [todayStart, todayEnd]
    );
    const consumablesCostToday = parseFloat(consRes.rows[0].total || 0);

    // Profit today = Revenue - Expenses - Consumables Cost
    const profitToday = revenueToday - expensesToday - consumablesCostToday;

    // 5. Total inventory valuation
    const invRes = await db.query(
      `SELECT COALESCE(SUM(quantity * purchase_price), 0) as valuation 
       FROM inventory_items`
    );
    const inventoryValue = parseFloat(invRes.rows[0].valuation || 0);

    // 6. Upcoming appointments today
    const apptRes = await db.query(
      `SELECT COUNT(*) as count 
       FROM appointments 
       WHERE status = 'PENDING' AND scheduled_at >= NOW()`
    );
    const upcomingAppointments = parseInt(apptRes.rows[0].count || 0);

    // 7. Low Stock Alerts count
    const alertRes = await db.query(
      `SELECT COUNT(*) as count 
       FROM inventory_items 
       WHERE quantity <= min_threshold`
    );
    const lowStockAlerts = parseInt(alertRes.rows[0].count || 0);

    return {
      customersToday,
      revenueToday,
      expensesToday,
      profitToday,
      inventoryValue,
      upcomingAppointments,
      lowStockAlerts
    };
  }

  async getProfitBreakdown(period = 'monthly') {
    // Determine start date based on period
    let interval = '1 month';
    if (period === 'daily') interval = '1 day';
    if (period === 'weekly') interval = '7 days';
    if (period === 'yearly') interval = '1 year';

    // Calculate metrics
    const incomeRes = await db.query(
      `SELECT COALESCE(SUM(price_paid), 0) as income 
       FROM sessions 
       WHERE date >= NOW() - INTERVAL '${interval}'`
    );
    const income = parseFloat(incomeRes.rows[0].income || 0);

    const expenseRes = await db.query(
      `SELECT COALESCE(SUM(amount), 0) as overhead 
       FROM expenses 
       WHERE date >= NOW() - INTERVAL '${interval}'`
    );
    const overhead = parseFloat(expenseRes.rows[0].overhead || 0);

    const consRes = await db.query(
      `SELECT COALESCE(SUM(sm.quantity_used * i.purchase_price), 0) as consumables
       FROM session_materials sm
       JOIN sessions s ON sm.session_id = s.id
       JOIN inventory_items i ON sm.inventory_item_id = i.id
       WHERE s.date >= NOW() - INTERVAL '${interval}'`
    );
    const consumables = parseFloat(consRes.rows[0].consumables || 0);

    // Add restock purchases to expenses if requested
    const purchaseRes = await db.query(
      `SELECT COALESCE(SUM(total_cost), 0) as purchases 
       FROM purchases 
       WHERE date >= NOW() - INTERVAL '${interval}'`
    );
    const purchaseCost = parseFloat(purchaseRes.rows[0].purchases || 0);

    const totalExpenses = overhead + purchaseCost;
    const profit = income - totalExpenses - consumables;

    return {
      period,
      income,
      overhead,
      consumables,
      purchaseCost,
      totalExpenses,
      profit
    };
  }

  async getChartsData() {
    // 1. Weekly comparison (last 7 days daily revenue)
    const weeklyRevenue = await db.query(
      `SELECT DATE_TRUNC('day', date) as day, SUM(price_paid) as revenue
       FROM sessions
       WHERE date >= NOW() - INTERVAL '7 days'
       GROUP BY day
       ORDER BY day ASC`
    );

    // 2. Most used services (Top cupping types)
    const popularServices = await db.query(
      `SELECT session_type, COUNT(*) as count
       FROM sessions
       GROUP BY session_type
       ORDER BY count DESC`
    );

    // 3. Monthly profit comparison (last 6 months)
    const monthlyComparison = await db.query(
      `SELECT DATE_TRUNC('month', date) as month, SUM(price_paid) as revenue
       FROM sessions
       WHERE date >= NOW() - INTERVAL '6 months'
       GROUP BY month
       ORDER BY month ASC`
    );

    return {
      weeklyRevenue: weeklyRevenue.rows.map(r => ({
        day: new Date(r.day).toLocaleDateString('en-US', { weekday: 'short' }),
        revenue: parseFloat(r.revenue || 0)
      })),
      popularServices: popularServices.rows,
      monthlyComparison: monthlyComparison.rows.map(m => ({
        month: new Date(m.month).toLocaleDateString('en-US', { month: 'short' }),
        revenue: parseFloat(m.revenue || 0)
      }))
    };
  }
}

module.exports = new FinanceService();
