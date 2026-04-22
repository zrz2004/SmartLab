import { ensureSmartLabTables } from '../services/nocodb.service.js';

try {
  const tables = await ensureSmartLabTables();
  console.log(JSON.stringify({
    inspectionMediaTableId: tables.inspectionMedia?.id ?? null,
    manualReviewsTableId: tables.manualReviews?.id ?? null
  }, null, 2));
  process.exit(0);
} catch (error) {
  console.error(error);
  process.exit(1);
}
