import app from './app.js';
import { config } from './config.js';
import { isDatabaseConfigured, testDatabaseConnection } from './db.js';

app.listen(config.port, async () => {
  console.log(`SmartLab backend listening on ${config.port}`);
  if (!isDatabaseConfigured()) {
    console.log('PostgreSQL not configured, repositories will use in-memory fallback.');
    return;
  }

  const connection = await testDatabaseConnection();
  if (connection.ok) {
    console.log(`PostgreSQL connected: ${connection.row.db} as ${connection.row.current_user}`);
  } else {
    console.log(`PostgreSQL unavailable, falling back to memory mode: ${connection.reason}`);
  }
});
