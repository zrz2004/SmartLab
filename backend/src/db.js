import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

import pg from 'pg';

import { config } from './config.js';

const { Pool } = pg;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..', '..');

const databaseConfigured = Boolean(
  config.postgres.host &&
      config.postgres.database &&
      config.postgres.user &&
      typeof config.postgres.password === 'string'
);

let pool = null;
const tableCache = new Map();
const columnCache = new Map();

function buildPool() {
  if (!databaseConfigured) return null;
  return new Pool({
    host: config.postgres.host,
    port: config.postgres.port,
    database: config.postgres.database,
    user: config.postgres.user,
    password: config.postgres.password,
    ssl: config.postgres.ssl
        ? { rejectUnauthorized: config.postgres.sslRejectUnauthorized }
        : undefined,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000
  });
}

export function isDatabaseConfigured() {
  return databaseConfigured;
}

export function getPool() {
  if (!pool) {
    pool = buildPool();
  }
  return pool;
}

export async function query(text, params = []) {
  const db = getPool();
  if (!db) {
    throw new Error('PostgreSQL is not configured.');
  }
  return db.query(text, params);
}

export async function withClient(callback) {
  const db = getPool();
  if (!db) {
    throw new Error('PostgreSQL is not configured.');
  }
  const client = await db.connect();
  try {
    return await callback(client);
  } finally {
    client.release();
  }
}

export async function testDatabaseConnection() {
  const db = getPool();
  if (!db) {
    return { ok: false, reason: 'PostgreSQL env vars are missing.' };
  }
  try {
    const result = await db.query('select current_database() as db, current_user as current_user');
    return { ok: true, row: result.rows[0] };
  } catch (error) {
    return { ok: false, reason: error.message };
  }
}

async function runSqlDirectory(relativeDirectory) {
  const directory = path.resolve(repoRoot, relativeDirectory);
  const entries = await fs.readdir(directory);
  const files = entries.filter((name) => name.endsWith('.sql')).sort();

  for (const file of files) {
    const sql = await fs.readFile(path.join(directory, file), 'utf8');
    if (!sql.trim()) continue;
    await query(sql);
  }
}

export async function hasTable(tableName) {
  const key = String(tableName).toLowerCase();
  if (tableCache.has(key)) {
    return tableCache.get(key);
  }

  const result = await query(
    `
    select exists (
      select 1
      from information_schema.tables
      where table_schema = 'public' and table_name = $1
    ) as present
    `,
    [key]
  );
  const present = Boolean(result.rows[0]?.present);
  tableCache.set(key, present);
  return present;
}

export async function hasColumn(tableName, columnName) {
  const key = `${String(tableName).toLowerCase()}:${String(columnName).toLowerCase()}`;
  if (columnCache.has(key)) {
    return columnCache.get(key);
  }

  const result = await query(
    `
    select exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = $1
        and column_name = $2
    ) as present
    `,
    [String(tableName).toLowerCase(), String(columnName).toLowerCase()]
  );
  const present = Boolean(result.rows[0]?.present);
  columnCache.set(key, present);
  return present;
}

export async function isLegacySchema() {
  return (await hasTable('sensors')) && !(await hasTable('devices'));
}

async function resolveMigrationDirectory() {
  return (await isLegacySchema()) ? 'database/migrations_legacy' : 'database/migrations';
}

async function resolveSeedDirectory() {
  return (await isLegacySchema()) ? 'database/seeds_legacy' : 'database/seeds';
}

export async function runMigrations() {
  await runSqlDirectory(await resolveMigrationDirectory());
}

export async function runSeeds() {
  await runSqlDirectory(await resolveSeedDirectory());
}

export async function closeDatabase() {
  if (pool) {
    await pool.end();
    pool = null;
  }
  tableCache.clear();
  columnCache.clear();
}
