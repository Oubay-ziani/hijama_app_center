const db = require('../../config/db');

class AppointmentsService {
  async getAll(startDate = null, endDate = null) {
    let queryText = `
      SELECT a.*, c.full_name as customer_name, c.phone as customer_phone, u.name as employee_name
      FROM appointments a
      JOIN customers c ON a.customer_id = c.id
      LEFT JOIN users u ON a.user_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (startDate) {
      params.push(startDate);
      queryText += ` AND a.scheduled_at >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      queryText += ` AND a.scheduled_at <= $${params.length}`;
    }

    queryText += ' ORDER BY a.scheduled_at ASC';
    const res = await db.query(queryText, params);
    return res.rows;
  }

  async getById(id) {
    const res = await db.query(
      `SELECT a.*, c.full_name as customer_name, c.phone as customer_phone, u.name as employee_name
       FROM appointments a
       JOIN customers c ON a.customer_id = c.id
       LEFT JOIN users u ON a.user_id = u.id
       WHERE a.id = $1`,
      [id]
    );
    if (res.rowCount === 0) {
      throw new Error('Appointment not found');
    }
    return res.rows[0];
  }

  async create(data) {
    const { customerId, userId, sessionType, scheduledAt, notes } = data;
    if (!customerId || !sessionType || !scheduledAt) {
      throw new Error('Customer ID, session type, and scheduled time are required');
    }

    const res = await db.query(
      `INSERT INTO appointments (customer_id, user_id, session_type, scheduled_at, status, notes)
       VALUES ($1, $2, $3, $4, 'PENDING', $5)
       RETURNING *`,
      [customerId, userId || null, sessionType, scheduledAt, notes || '']
    );

    return res.rows[0];
  }

  async update(id, data) {
    const { userId, sessionType, scheduledAt, status, notes } = data;
    
    // Support partial updates
    const getAppt = await db.query('SELECT * FROM appointments WHERE id = $1', [id]);
    if (getAppt.rowCount === 0) {
      throw new Error('Appointment not found');
    }
    const current = getAppt.rows[0];

    const res = await db.query(
      `UPDATE appointments
       SET user_id = $1, session_type = $2, scheduled_at = $3, status = $4, notes = $5
       WHERE id = $6
       RETURNING *`,
      [
        userId !== undefined ? userId : current.user_id,
        sessionType || current.session_type,
        scheduledAt || current.scheduled_at,
        status || current.status,
        notes !== undefined ? notes : current.notes,
        id
      ]
    );

    return res.rows[0];
  }

  async delete(id) {
    const res = await db.query('DELETE FROM appointments WHERE id = $1 RETURNING id', [id]);
    if (res.rowCount === 0) {
      throw new Error('Appointment not found');
    }
    return true;
  }

  // Find appointments scheduled between 50 and 70 minutes from now (for the 1 hour push alert)
  async getUpcomingAlerts() {
    const res = await db.query(
      `SELECT a.id, a.scheduled_at, c.full_name as customer_name, c.phone as customer_phone, a.session_type
       FROM appointments a
       JOIN customers c ON a.customer_id = c.id
       WHERE a.status = 'PENDING'
         AND a.scheduled_at BETWEEN NOW() + INTERVAL '50 minutes' AND NOW() + INTERVAL '70 minutes'`
    );
    return res.rows.map(appt => ({
      id: appt.id,
      scheduledAt: appt.scheduled_at,
      customerName: appt.customer_name,
      phone: appt.customer_phone,
      message: `Reminder: ${appt.customer_name} has a ${appt.session_type} session in 1 hour (${new Date(appt.scheduled_at).toLocaleTimeString()})`
    }));
  }
}

module.exports = new AppointmentsService();
