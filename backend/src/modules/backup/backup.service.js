const db = require('../../config/db');

class BackupService {
  async exportDb() {
    const backup = {};

    // Get all tables data
    const tables = [
      'branches',
      'users',
      'customers',
      'loyalty',
      'inventory_items',
      'purchases',
      'expenses',
      'sessions',
      'session_materials',
      'appointments'
    ];

    for (const table of tables) {
      const res = await db.query(`SELECT * FROM ${table}`);
      backup[table] = res.rows;
    }

    return {
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      data: backup
    };
  }

  async importDb(backupJson) {
    const { data } = backupJson;
    if (!data) {
      throw new Error('Invalid backup format: missing data container');
    }

    const { client, query, release } = await db.getClient();

    try {
      await query('BEGIN');

      console.log('[BACKUP IMPORT] Truncating tables in order of dependency...');
      // 1. Truncate in safe order (cascading equivalent or reverse-fk order)
      const truncateOrder = [
        'session_materials',
        'purchases',
        'sessions',
        'appointments',
        'loyalty',
        'inventory_items',
        'customers',
        'expenses',
        'users',
        'branches'
      ];

      for (const table of truncateOrder) {
        await query(`TRUNCATE TABLE ${table} CASCADE`);
      }

      console.log('[BACKUP IMPORT] Reinserting tables in reference order...');
      
      // Helper for columns/placeholders
      const insertRows = async (table, rows) => {
        if (!rows || rows.length === 0) return;
        
        const sampleRow = rows[0];
        const keys = Object.keys(sampleRow);
        const colNames = keys.join(', ');
        
        for (const row of rows) {
          const vals = keys.map(k => row[k]);
          const placeholders = keys.map((_, idx) => `$${idx + 1}`).join(', ');
          
          await query(
            `INSERT INTO ${table} (${colNames}) VALUES (${placeholders})`,
            vals
          );
        }
      };

      // 2. Insert in safe order (dependency-first)
      await insertRows('branches', data.branches);
      await insertRows('users', data.users);
      await insertRows('expenses', data.expenses);
      await insertRows('customers', data.customers);
      await insertRows('inventory_items', data.inventory_items);
      await insertRows('loyalty', data.loyalty);
      await insertRows('appointments', data.appointments);
      await insertRows('sessions', data.sessions);
      await insertRows('purchases', data.purchases);
      await insertRows('session_materials', data.session_materials);

      await query('COMMIT');
      return true;
    } catch (err) {
      await query('ROLLBACK');
      console.error('[BACKUP IMPORT ERROR]', err);
      throw err;
    } finally {
      release();
    }
  }
}

module.exports = new BackupService();
