const db = require('../../config/db');

class CustomersService {
  async getAll(search = '', branchId = null) {
    let queryText = `
      SELECT c.*, 
             COALESCE(SUM(s.debt_amount), 0) AS total_debt,
             COALESCE(l.session_count, 0) AS session_count,
             COALESCE(l.discount_pct, 0) AS discount_pct
      FROM customers c
      LEFT JOIN sessions s ON c.id = s.customer_id
      LEFT JOIN loyalty l ON c.id = l.customer_id
      WHERE 1=1
    `;
    const params = [];

    if (branchId) {
      params.push(branchId);
      queryText += ` AND c.branch_id = $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      queryText += ` AND (c.full_name ILIKE $${params.length} OR c.phone ILIKE $${params.length})`;
    }

    queryText += ` GROUP BY c.id, l.session_count, l.discount_pct ORDER BY c.full_name ASC`;

    const res = await db.query(queryText, params);
    return res.rows;
  }

  async getById(id) {
    const customerRes = await db.query('SELECT * FROM customers WHERE id = $1', [id]);
    if (customerRes.rowCount === 0) {
      throw new Error('Customer not found');
    }
    const customer = customerRes.rows[0];

    // Fetch loyalty metrics
    const loyaltyRes = await db.query('SELECT session_count, discount_pct FROM loyalty WHERE customer_id = $1', [id]);
    const loyalty = loyaltyRes.rows[0] || { session_count: 0, discount_pct: 0.00 };

    // Fetch visits timeline
    const sessionsRes = await db.query(
      `SELECT id, session_type, price_paid, total_cost, debt_amount, cups_used, notes, date 
       FROM sessions 
       WHERE customer_id = $1 
       ORDER BY date DESC`,
      [id]
    );

    // Calculate total remaining debt
    const debtRes = await db.query(
      `SELECT COALESCE(SUM(debt_amount), 0) as total_debt 
       FROM sessions 
       WHERE customer_id = $1`,
      [id]
    );
    const totalDebt = parseFloat(debtRes.rows[0].total_debt || 0);

    return {
      ...customer,
      loyalty,
      history: sessionsRes.rows,
      totalDebt
    };
  }

  async create(data, branchId) {
    const {
      fullName,
      phone,
      age,
      gender,
      medicalNotes,
      chronicDiseases,
      bloodPressureStatus,
      previousHijamaHistory,
      notes
    } = data;

    if (!fullName || !phone) {
      throw new Error('Full name and phone are required');
    }

    // Insert customer
    const res = await db.query(
      `INSERT INTO customers 
       (full_name, phone, age, gender, medical_notes, chronic_diseases, blood_pressure_status, previous_hijama_history, notes, branch_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        fullName,
        phone,
        parseInt(age) || 0,
        gender || 'OTHER',
        medicalNotes || '',
        chronicDiseases || '',
        bloodPressureStatus || '',
        previousHijamaHistory || '',
        notes || '',
        branchId
      ]
    );

    const customer = res.rows[0];

    // Initialize loyalty record
    await db.query(
      `INSERT INTO loyalty (customer_id, session_count, discount_pct) 
       VALUES ($1, 0, 0.0) 
       ON CONFLICT (customer_id) DO NOTHING`,
      [customer.id]
    );

    return customer;
  }

  async update(id, data) {
    const {
      fullName,
      phone,
      age,
      gender,
      medicalNotes,
      chronicDiseases,
      bloodPressureStatus,
      previousHijamaHistory,
      notes
    } = data;

    const res = await db.query(
      `UPDATE customers
       SET full_name = $1, phone = $2, age = $3, gender = $4, medical_notes = $5,
           chronic_diseases = $6, blood_pressure_status = $7, previous_hijama_history = $8, notes = $9
       WHERE id = $10
       RETURNING *`,
      [
        fullName,
        phone,
        parseInt(age) || 0,
        gender || 'OTHER',
        medicalNotes || '',
        chronicDiseases || '',
        bloodPressureStatus || '',
        previousHijamaHistory || '',
        notes || '',
        id
      ]
    );

    if (res.rowCount === 0) {
      throw new Error('Customer not found');
    }

    return res.rows[0];
  }

  async delete(id) {
    const res = await db.query('DELETE FROM customers WHERE id = $1 RETURNING id', [id]);
    if (res.rowCount === 0) {
      throw new Error('Customer not found');
    }
    return true;
  }

  async getUnpaidCustomers(branchId = null) {
    let queryText = `
      SELECT c.id, c.full_name, c.phone, COALESCE(SUM(s.debt_amount), 0) AS total_debt
      FROM customers c
      INNER JOIN sessions s ON c.id = s.customer_id
      WHERE s.debt_amount > 0
    `;
    const params = [];
    if (branchId) {
      params.push(branchId);
      queryText += ` AND c.branch_id = $${params.length}`;
    }
    queryText += ` GROUP BY c.id ORDER BY total_debt DESC`;
    const res = await db.query(queryText, params);
    return res.rows;
  }
}

module.exports = new CustomersService();
