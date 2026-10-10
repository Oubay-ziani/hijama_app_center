const db = require('../../config/db');

class ExpensesService {
  async getAll(branchId = null) {
    let queryText = 'SELECT * FROM expenses';
    const params = [];
    if (branchId) {
      params.push(branchId);
      queryText += ' WHERE branch_id = $1';
    }
    queryText += ' ORDER BY date DESC';
    const res = await db.query(queryText, params);
    return res.rows;
  }

  async create(data, branchId) {
    const { category, amount, description, date } = data;
    if (!category || !amount) {
      throw new Error('Category and amount are required');
    }

    const res = await db.query(
      `INSERT INTO expenses (category, amount, description, date, branch_id)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [
        category,
        parseFloat(amount),
        description || '',
        date ? new Date(date) : new Date(),
        branchId
      ]
    );
    return res.rows[0];
  }

  async delete(id) {
    const res = await db.query('DELETE FROM expenses WHERE id = $1 RETURNING id', [id]);
    if (res.rowCount === 0) {
      throw new Error('Expense record not found');
    }
    return true;
  }
}

module.exports = new ExpensesService();
