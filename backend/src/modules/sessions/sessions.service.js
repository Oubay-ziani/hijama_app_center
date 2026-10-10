const db = require('../../config/db');
const inventoryService = require('../inventory/inventory.service');

class SessionsService {
  async getAll(customerId = null, startDate = null, endDate = null) {
    let queryText = `
      SELECT s.*, c.full_name as customer_name, u.name as employee_name
      FROM sessions s
      JOIN customers c ON s.customer_id = c.id
      LEFT JOIN users u ON s.user_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (customerId) {
      params.push(customerId);
      queryText += ` AND s.customer_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      queryText += ` AND s.date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      queryText += ` AND s.date <= $${params.length}`;
    }

    queryText += ' ORDER BY s.date DESC';
    const res = await db.query(queryText, params);
    return res.rows;
  }

  async getById(id) {
    const sessionRes = await db.query(
      `SELECT s.*, c.full_name as customer_name, c.phone as customer_phone, u.name as employee_name
       FROM sessions s
       JOIN customers c ON s.customer_id = c.id
       LEFT JOIN users u ON s.user_id = u.id
       WHERE s.id = $1`,
      [id]
    );

    if (sessionRes.rowCount === 0) {
      throw new Error('Session record not found');
    }

    const session = sessionRes.rows[0];

    // Fetch consumed materials
    const materialsRes = await db.query(
      `SELECT sm.quantity_used, i.name as item_name, i.purchase_price
       FROM session_materials sm
       JOIN inventory_items i ON sm.inventory_item_id = i.id
       WHERE sm.session_id = $1`,
      [id]
    );

    return {
      ...session,
      materials: materialsRes.rows
    };
  }

  async create(data, userId) {
    const {
      customerId,
      sessionType,
      pricePaid,
      totalCost,
      cupsUsed,
      notes,
      materials // Array of { id, quantityUsed }
    } = data;

    if (!customerId || !sessionType || pricePaid === undefined || totalCost === undefined) {
      throw new Error('Customer ID, session type, total cost, and price paid are required');
    }

    const paid = parseFloat(pricePaid);
    const cost = parseFloat(totalCost);
    const debt = Math.max(0, cost - paid);

    const { client, query, release } = await db.getClient();

    try {
      await query('BEGIN');

      // 1. Insert session
      const sessionRes = await query(
        `INSERT INTO sessions 
         (customer_id, user_id, session_type, price_paid, total_cost, debt_amount, cups_used, notes)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [customerId, userId, sessionType, paid, cost, debt, parseInt(cupsUsed) || 0, notes || '']
      );
      const session = sessionRes.rows[0];

      // 2. Process materials and reduce inventory
      if (materials && Array.isArray(materials)) {
        for (const item of materials) {
          const { id, quantityUsed } = item;
          const qty = parseInt(quantityUsed);
          if (!id || !qty || qty <= 0) continue;

          // Verify current stock availability
          const stockRes = await query(
            'SELECT name, quantity, min_threshold FROM inventory_items WHERE id = $1',
            [id]
          );
          if (stockRes.rowCount === 0) {
            throw new Error(`Inventory item ${id} not found`);
          }

          const stockItem = stockRes.rows[0];
          if (stockItem.quantity < qty) {
            throw new Error(`Insufficient stock for ${stockItem.name}. Current stock: ${stockItem.quantity}, Requested: ${qty}`);
          }

          // Insert session materials log
          await query(
            `INSERT INTO session_materials (session_id, inventory_item_id, quantity_used)
             VALUES ($1, $2, $3)`,
            [session.id, id, qty]
          );

          // Update inventory quantity
          const updatedStock = await query(
            `UPDATE inventory_items 
             SET quantity = quantity - $1, updated_at = CURRENT_TIMESTAMP 
             WHERE id = $2 
             RETURNING quantity`,
            [qty, id]
          );

          // Alert checker log outputs
          const newQty = updatedStock.rows[0].quantity;
          const threshold = stockItem.min_threshold;
          const status = inventoryService.checkStockStatus(newQty, threshold);

          if (status === 'CRITICAL') {
            console.warn(`[STOCK ALERT SYSTEM] CRITICAL: ${stockItem.name} has reached critical level! Remaining: ${newQty}. Buy supplies immediately.`);
          } else if (status === 'WARNING') {
            console.log(`[STOCK ALERT SYSTEM] WARNING: ${stockItem.name} is running low. Remaining: ${newQty}.`);
          }
        }
      }

      // 3. Update Loyalty stats
      const loyaltyRes = await query(
        'SELECT session_count FROM loyalty WHERE customer_id = $1',
        [customerId]
      );

      if (loyaltyRes.rowCount === 0) {
        // Initialize loyalty profile
        await query(
          'INSERT INTO loyalty (customer_id, session_count, discount_pct) VALUES ($1, 1, 0.00)',
          [customerId]
        );
      } else {
        const newCount = loyaltyRes.rows[0].session_count + 1;
        // Discount of 10% unlocked after 5 completed sessions
        const discount = newCount >= 5 ? 10.00 : 0.00;
        await query(
          `UPDATE loyalty 
           SET session_count = $1, discount_pct = $2 
           WHERE customer_id = $3`,
          [newCount, discount, customerId]
        );
      }

      await query('COMMIT');
      return session;
    } catch (err) {
      await query('ROLLBACK');
      throw err;
    } finally {
      release();
    }
  }
}

module.exports = new SessionsService();
