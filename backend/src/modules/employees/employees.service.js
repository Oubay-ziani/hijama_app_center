const db = require('../../config/db');
const bcrypt = require('bcryptjs');

class EmployeesService {
  async getAll(branchId = null) {
    let queryText = `
      SELECT u.id, u.name, u.email, u.role, u.created_at,
             COUNT(s.id) as sessions_served
      FROM users u
      LEFT JOIN sessions s ON u.id = s.user_id
      WHERE u.role = 'EMPLOYEE'
    `;
    const params = [];

    if (branchId) {
      params.push(branchId);
      queryText += ` AND u.branch_id = $${params.length}`;
    }

    queryText += ` GROUP BY u.id ORDER BY u.name ASC`;
    const res = await db.query(queryText, params);
    return res.rows;
  }

  async create(data, branchId) {
    const { name, email, password } = data;
    if (!name || !email || !password) {
      throw new Error('Name, email, and password are required');
    }

    // Check if email already registered
    const emailCheck = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (emailCheck.rowCount > 0) {
      throw new Error('Email is already registered');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const res = await db.query(
      `INSERT INTO users (name, email, password_hash, role, branch_id)
       VALUES ($1, $2, $3, 'EMPLOYEE', $4)
       RETURNING id, name, email, role, branch_id, created_at`,
      [name, email, hashedPassword, branchId]
    );

    return res.rows[0];
  }

  async delete(id) {
    // Restrict deleting admin through this
    const res = await db.query(
      "DELETE FROM users WHERE id = $1 AND role = 'EMPLOYEE' RETURNING id",
      [id]
    );
    if (res.rowCount === 0) {
      throw new Error('Employee user not found or not deletable');
    }
    return true;
  }
}

module.exports = new EmployeesService();
