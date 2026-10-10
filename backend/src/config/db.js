const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const env = require('./env');

const pool = new Pool({
  connectionString: env.DATABASE_URL,
  ssl: env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Helper for generic queries
const query = (text, params) => pool.query(text, params);

// Transaction runner helper
const getClient = async () => {
  const client = await pool.connect();
  const query = client.query.bind(client);
  const release = client.release.bind(client);
  return { client, query, release };
};

// Automatical DB Bootstrap and Seeding
const initDb = async () => {
  try {
    console.log('Connecting to database...');
    // Read schema file
    const schemaPath = path.join(__dirname, '../database/schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');

    // Run schema migrations
    await pool.query(schemaSql);
    console.log('Database tables verified/created successfully.');

    // Seed default branch if empty
    const branchRes = await pool.query('SELECT * FROM branches LIMIT 1');
    let branchId;
    if (branchRes.rowCount === 0) {
      const newBranch = await pool.query(
        `INSERT INTO branches (name, address) 
         VALUES ($1, $2) RETURNING id`,
        ['Hijama Center Main', '123 Medical Avenue, Algiers']
      );
      branchId = newBranch.rows[0].id;
      console.log('Default clinic branch seeded.');
    } else {
      branchId = branchRes.rows[0].id;
    }

    // Seed default admin if empty
    const adminRes = await pool.query('SELECT * FROM users WHERE role = $1', ['ADMIN']);
    if (adminRes.rowCount === 0) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      await pool.query(
        `INSERT INTO users (name, email, password_hash, role, branch_id) 
         VALUES ($1, $2, $3, $4, $5)`,
        ['Dr. Karim (Admin)', 'admin@hijama.com', hashedPassword, 'ADMIN', branchId]
      );
      console.log('Default Admin seeded (admin@hijama.com / admin123).');
    }

    // Seed default employee if empty (for testing)
    const empRes = await pool.query('SELECT * FROM users WHERE role = $1', ['EMPLOYEE']);
    if (empRes.rowCount === 0) {
      const hashedPassword = await bcrypt.hash('staff123', 10);
      await pool.query(
        `INSERT INTO users (name, email, password_hash, role, branch_id) 
         VALUES ($1, $2, $3, $4, $5)`,
        ['Sarah (Staff)', 'employee@hijama.com', hashedPassword, 'EMPLOYEE', branchId]
      );
      console.log('Default Employee seeded (employee@hijama.com / staff123).');
    }

    // Seed basic inventory items if empty to help bootstrapping
    const invRes = await pool.query('SELECT * FROM inventory_items LIMIT 1');
    if (invRes.rowCount === 0) {
      const items = [
        ['Hijama Cups (Standard)', 120, 1.50, 'Medical Supplies Dz', 20],
        ['Gloves (Sterile)', 200, 0.40, 'SafeCare Co', 30],
        ['Blades (Disposable)', 150, 0.90, 'Medical Supplies Dz', 25],
        ['Tissues (Soft)', 300, 0.20, 'Local Brand', 40],
        ['Cotton (Pack)', 80, 0.80, 'SafeCare Co', 15],
        ['Alcohol Sanitizer', 50, 3.50, 'SafeCare Co', 10]
      ];
      for (const item of items) {
        await pool.query(
          `INSERT INTO inventory_items (name, quantity, purchase_price, supplier, min_threshold, branch_id)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [item[0], item[1], item[2], item[3], item[4], branchId]
        );
      }
      console.log('Default inventory items seeded.');
    }

  } catch (err) {
    console.error('Failed to initialize database: ', err.message);
  }
};

module.exports = {
  query,
  getClient,
  pool,
  initDb
};
