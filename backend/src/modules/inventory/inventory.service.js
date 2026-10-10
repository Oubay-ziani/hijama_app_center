const db = require('../../config/db');

class InventoryService {
  async getAll(branchId = null) {
    let queryText = 'SELECT * FROM inventory_items';
    const params = [];
    if (branchId) {
      params.push(branchId);
      queryText += ' WHERE branch_id = $1';
    }
    queryText += ' ORDER BY name ASC';
    const res = await db.query(queryText, params);
    
    // Add dynamic warnings to items
    return res.rows.map(item => {
      const status = this.checkStockStatus(item.quantity, item.min_threshold);
      return { ...item, status };
    });
  }

  async getById(id) {
    const res = await db.query('SELECT * FROM inventory_items WHERE id = $1', [id]);
    if (res.rowCount === 0) {
      throw new Error('Inventory item not found');
    }
    const item = res.rows[0];
    const status = this.checkStockStatus(item.quantity, item.min_threshold);
    return { ...item, status };
  }

  async create(data, branchId) {
    const { name, quantity, purchasePrice, supplier, minThreshold } = data;
    if (!name || purchasePrice === undefined) {
      throw new Error('Name and purchase price are required');
    }

    const res = await db.query(
      `INSERT INTO inventory_items (name, quantity, purchase_price, supplier, min_threshold, branch_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        name,
        parseInt(quantity) || 0,
        parseFloat(purchasePrice),
        supplier || '',
        parseInt(minThreshold) || 10,
        branchId
      ]
    );

    return res.rows[0];
  }

  async update(id, data) {
    const { name, quantity, purchasePrice, supplier, minThreshold } = data;
    const res = await db.query(
      `UPDATE inventory_items
       SET name = $1, quantity = $2, purchase_price = $3, supplier = $4, min_threshold = $5
       WHERE id = $6
       RETURNING *`,
      [
        name,
        parseInt(quantity) || 0,
        parseFloat(purchasePrice),
        supplier || '',
        parseInt(minThreshold) || 10,
        id
      ]
    );

    if (res.rowCount === 0) {
      throw new Error('Inventory item not found');
    }

    return res.rows[0];
  }

  // Restock purchase logger
  async addPurchase(data, branchId) {
    const { itemId, quantity, totalCost, supplier, invoiceNumber } = data;
    if (!itemId || !quantity || !totalCost || !supplier) {
      throw new Error('Item ID, quantity, total cost, supplier, and invoice are required');
    }

    const qty = parseInt(quantity);
    const cost = parseFloat(totalCost);

    const { client, query, release } = await db.getClient();
    try {
      await query('BEGIN');

      // Verify item exists
      const itemRes = await query('SELECT * FROM inventory_items WHERE id = $1', [itemId]);
      if (itemRes.rowCount === 0) {
        throw new Error('Inventory item not found');
      }

      // Record purchase
      const purchaseRes = await query(
        `INSERT INTO purchases (inventory_item_id, quantity, total_cost, supplier, invoice_number)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [itemId, qty, cost, supplier, invoiceNumber || '']
      );

      // Increment stock
      await query(
        `UPDATE inventory_items 
         SET quantity = quantity + $1, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [qty, itemId]
      );

      await query('COMMIT');
      return purchaseRes.rows[0];
    } catch (err) {
      await query('ROLLBACK');
      throw err;
    } finally {
      release();
    }
  }

  async getPurchaseHistory() {
    const res = await db.query(
      `SELECT p.*, i.name as item_name 
       FROM purchases p 
       JOIN inventory_items i ON p.inventory_item_id = i.id 
       ORDER BY p.date DESC`
    );
    return res.rows;
  }

  // Stock status checks: 10% (Warning) and 5% (Critical) stock alerts relative to optimal baseline
  // If min_threshold represents 10%, standard optimal capacity is 10 times min_threshold.
  // Therefore:
  // - 10% capacity = min_threshold
  // - 5% capacity = min_threshold * 0.5
  checkStockStatus(qty, minThreshold) {
    if (qty <= minThreshold * 0.5) {
      return 'CRITICAL';
    }
    if (qty <= minThreshold) {
      return 'WARNING';
    }
    return 'NORMAL';
  }

  // Get list of low stock items to trigger notifications
  async getLowStockAlerts(branchId = null) {
    const items = await this.getAll(branchId);
    return items.filter(item => item.status !== 'NORMAL').map(item => {
      if (item.status === 'CRITICAL') {
        return {
          id: item.id,
          name: item.name,
          quantity: item.quantity,
          status: 'CRITICAL',
          message: `Critical stock alert: ${item.name} quantity (${item.quantity}) is extremely low. Buy supplies immediately.`
        };
      } else {
        return {
          id: item.id,
          name: item.name,
          quantity: item.quantity,
          status: 'WARNING',
          message: `Warning: ${item.name} quantity (${item.quantity}) is running low.`
        };
      }
    });
  }
}

module.exports = new InventoryService();
