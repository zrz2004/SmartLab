import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: Number(process.env.PORT ?? 3000),
  apiPrefix: process.env.API_PREFIX ?? '/api/v1',
  postgres: {
    host: process.env.POSTGRES_HOST,
    port: Number(process.env.POSTGRES_PORT ?? 5432),
    database: process.env.POSTGRES_DB,
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    ssl: process.env.POSTGRES_SSL === 'true',
    sslRejectUnauthorized: process.env.POSTGRES_SSL_REJECT_UNAUTHORIZED !== 'false'
  },
  siliconflow: {
    baseUrl: process.env.SILICONFLOW_BASE_URL,
    apiKey: process.env.SILICONFLOW_API_KEY,
    primaryModel: process.env.SILICONFLOW_PRIMARY_MODEL,
    backupModel: process.env.SILICONFLOW_BACKUP_MODEL,
    compatModel: process.env.SILICONFLOW_COMPAT_MODEL
  },
  nocodb: {
    baseUrl: process.env.NOCODB_BASE_URL,
    apiToken: process.env.NOCODB_API_TOKEN,
    projectId: process.env.NOCODB_PROJECT_ID,
    mediaTable: process.env.NOCODB_MEDIA_TABLE,
    reviewTable: process.env.NOCODB_REVIEW_TABLE
  }
};
