import { closeDatabase, isDatabaseConfigured, runMigrations, testDatabaseConnection } from '../db.js';

try {
  if (!isDatabaseConfigured()) {
    console.error('PostgreSQL env vars are missing. Migration skipped.');
    process.exit(1);
  }

  const connection = await testDatabaseConnection();
  if (!connection.ok) {
    console.error(`Database connection failed: ${connection.reason}`);
    process.exit(1);
  }

  await runMigrations();
  console.log('Database migrations completed.');
  await closeDatabase();
} catch (error) {
  console.error(error);
  await closeDatabase().catch(() => {});
  process.exit(1);
}
