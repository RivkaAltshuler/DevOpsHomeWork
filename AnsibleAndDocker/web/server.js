import express from 'express';
import pg from 'pg';

const { Client } = pg;  // Correct way to import Client

const app = express();
const port = 8080;


const client = new Client({
  connectionString: process.env.DATABASE_URL,
});

async function createTableIfNotExists() {
  try {//create table and insert initial 0 (idempotency)
    await client.query(`
      CREATE TABLE IF NOT EXISTS counter (
        id SERIAL PRIMARY KEY,
        hits INTEGER DEFAULT 0
      );
	  INSERT INTO counter (hits)
      SELECT 0
      WHERE NOT EXISTS (SELECT 1 FROM counter);
    `);
    console.log("Table 'counter' created or already exists.");
  } catch (error) {
    console.error("Error creating table:", error);
    throw error; 
  }
}

client.connect();

console.log("Connected to database.");

// Check and create the table before starting the server
await createTableIfNotExists();

app.get('/', async (req, res) => {
  try {
    const result = await client.query('SELECT hits FROM counter'); // Assuming you have a "counter" table
    let hits = 0;
    if (result.rows.length > 0) {		
      hits = result.rows[0].hits;
    }

    hits++;
    await client.query('UPDATE counter SET hits = $1', [hits]);

    res.send(`<h1>Hello World!</h1><p>Hits: ${hits}</p>`);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error');
  }
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
  console.log(process.env.DATABASE_URL);
});