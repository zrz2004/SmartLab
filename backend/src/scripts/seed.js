import { closeDatabase, isDatabaseConfigured, runSeeds, testDatabaseConnection } from '../db.js';

try {
  if (!isDatabaseConfigured()) {
    console.error('PostgreSQL env vars are missing. Seed skipped.');
    process.exit(1);
  }

  const connection = await testDatabaseConnection();
  if (!connection.ok) {
    console.error(`Database connection failed: ${connection.reason}`);
    process.exit(1);
  }

  await runSeeds();
  console.log('Database seeds completed.');
  await closeDatabase();
} catch (error) {
  console.error(error);
  await closeDatabase().catch(() => {});
  process.exit(1);
}
