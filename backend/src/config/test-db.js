const { Client } = require('pg');
async function run() {
  const client = new Client({ connectionString: 'postgres://postgres:1234@localhost:5432/postgres' });
  try {
    await client.connect();
    const res = await client.query("SELECT 1 FROM pg_database WHERE datname='hijama'");
    if (res.rowCount === 0) {
      await client.query("CREATE DATABASE hijama");
      console.log("Database 'hijama' created successfully!");
    } else {
      console.log("Database 'hijama' already exists.");
    }
  } catch (e) {
    console.error("Error checking/creating database:", e.message);
  } finally {
    await client.end();
  }
}
run();
