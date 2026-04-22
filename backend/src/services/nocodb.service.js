import axios from 'axios';
import FormData from 'form-data';

import { config } from '../config.js';

const REQUIRED_TABLES = {
  inspection_media: {
    title: 'inspection_media',
    columns: [
      { title: 'lab_id', column_name: 'lab_id', uidt: 'SingleLineText' },
      { title: 'scene_type', column_name: 'scene_type', uidt: 'SingleLineText' },
      { title: 'device_type', column_name: 'device_type', uidt: 'SingleLineText' },
      { title: 'target_id', column_name: 'target_id', uidt: 'SingleLineText' },
      { title: 'provider', column_name: 'provider', uidt: 'SingleLineText' },
      { title: 'file_name', column_name: 'file_name', uidt: 'SingleLineText' },
      { title: 'file_size', column_name: 'file_size', uidt: 'Number' },
      { title: 'attachment', column_name: 'attachment', uidt: 'Attachment' },
      { title: 'storage_path', column_name: 'storage_path', uidt: 'LongText' },
      { title: 'signed_path', column_name: 'signed_path', uidt: 'LongText' },
      { title: 'captured_at', column_name: 'captured_at', uidt: 'DateTime' },
      { title: 'inspection_status', column_name: 'inspection_status', uidt: 'SingleLineText' }
    ]
  },
  manual_reviews: {
    title: 'manual_reviews',
    columns: [
      { title: 'inspection_id', column_name: 'inspection_id', uidt: 'SingleLineText' },
      { title: 'lab_id', column_name: 'lab_id', uidt: 'SingleLineText' },
      { title: 'review_status', column_name: 'review_status', uidt: 'SingleLineText' },
      { title: 'risk_level', column_name: 'risk_level', uidt: 'SingleLineText' },
      { title: 'review_summary', column_name: 'review_summary', uidt: 'LongText' },
      { title: 'reviewer_name', column_name: 'reviewer_name', uidt: 'SingleLineText' },
      { title: 'reviewed_at', column_name: 'reviewed_at', uidt: 'DateTime' },
      { title: 'attachment', column_name: 'attachment', uidt: 'Attachment' }
    ]
  }
};

const schemaCache = new Map();

function getHeaders(extra = {}) {
  return {
    'xc-token': config.nocodb.apiToken,
    ...extra
  };
}

function getMetaClient() {
  return axios.create({
    baseURL: config.nocodb.baseUrl,
    headers: getHeaders()
  });
}

function isDuplicateColumnError(error) {
  return axios.isAxiosError(error) &&
      error.response?.status === 400 &&
      error.response?.data?.msg === 'Duplicate column alias';
}

function normalizeAttachment(attachment) {
  if (!attachment) {
    return null;
  }
  const item = Array.isArray(attachment) ? attachment[0] : attachment;
  if (!item) {
    return null;
  }
  return {
    raw: Array.isArray(attachment) ? attachment : [item],
    path: item.path,
    title: item.title,
    mimetype: item.mimetype,
    size: item.size,
    signedPath: item.signedPath,
    url: item.signedPath
      ? `${config.nocodb.baseUrl}/${item.signedPath}`
      : item.path
          ? `${config.nocodb.baseUrl}/${item.path}`
          : null
  };
}

export async function ensureSmartLabTables() {
  if (!config.nocodb.apiToken || !config.nocodb.projectId) {
    throw new Error('NocoDB credentials are missing.');
  }

  const cacheKey = `${config.nocodb.baseUrl}:${config.nocodb.projectId}`;
  if (schemaCache.has(cacheKey)) {
    return schemaCache.get(cacheKey);
  }

  const client = getMetaClient();
  const listed = await client.get(`/api/v1/db/meta/projects/${config.nocodb.projectId}/tables`);
  const tables = listed.data?.list ?? [];
  const byName = new Map(tables.map((table) => [table.title ?? table.table_name, table]));

  for (const definition of Object.values(REQUIRED_TABLES)) {
    let table = byName.get(definition.title);
    if (!table) {
      const created = await client.post(`/api/v1/db/meta/projects/${config.nocodb.projectId}/tables`, {
        title: definition.title,
        table_name: definition.title,
        columns: [{ title: 'id', column_name: 'id', uidt: 'ID', pk: true }]
      });
      table = created.data;
    }

    const existingColumns = new Map((table.columns ?? []).map((column) => [column.title ?? column.column_name, column]));
    for (const column of definition.columns) {
      if (existingColumns.has(column.title)) {
        continue;
      }
      try {
        const createdColumn = await client.post(`/api/v1/db/meta/tables/${table.id}/columns`, column);
        existingColumns.set(column.title, createdColumn.data);
        table.columns = [...(table.columns ?? []), createdColumn.data];
      } catch (error) {
        if (!isDuplicateColumnError(error)) {
          throw error;
        }
      }
    }
    byName.set(definition.title, table);
  }

  const resolved = {
    inspectionMedia: byName.get(REQUIRED_TABLES.inspection_media.title),
    manualReviews: byName.get(REQUIRED_TABLES.manual_reviews.title)
  };
  schemaCache.set(cacheKey, resolved);
  return resolved;
}

export async function uploadToNocoDb({ buffer, fileName }) {
  if (!config.nocodb.apiToken) {
    throw new Error('Missing NocoDB API token.');
  }

  const formData = new FormData();
  formData.append('file', buffer, fileName);

  const response = await axios.post(
    `${config.nocodb.baseUrl}/api/v1/db/storage/upload`,
    formData,
    {
      headers: {
        ...formData.getHeaders(),
        ...getHeaders()
      }
    }
  );

  return normalizeAttachment(response.data);
}

export async function createInspectionMediaRecord(payload) {
  const tables = await ensureSmartLabTables();
  const tableId = tables.inspectionMedia?.id;
  if (!tableId) {
    throw new Error('inspection_media table is not available.');
  }

  const response = await axios.post(
    `${config.nocodb.baseUrl}/api/v1/db/data/noco/${config.nocodb.projectId}/${tableId}`,
    {
      lab_id: payload.labId,
      scene_type: payload.sceneType,
      device_type: payload.deviceType,
      target_id: payload.targetId ?? '',
      provider: payload.provider,
      file_name: payload.fileName,
      file_size: payload.fileSize,
      attachment: payload.attachment ?? [],
      storage_path: payload.storagePath ?? '',
      signed_path: payload.signedPath ?? '',
      captured_at: payload.capturedAt ?? new Date().toISOString()
    },
    {
      headers: getHeaders({
        'Content-Type': 'application/json'
      })
    }
  );

  return response.data;
}

export async function createManualReviewRecord(payload) {
  const tables = await ensureSmartLabTables();
  const tableId = tables.manualReviews?.id;
  if (!tableId) {
    throw new Error('manual_reviews table is not available.');
  }

  const response = await axios.post(
    `${config.nocodb.baseUrl}/api/v1/db/data/noco/${config.nocodb.projectId}/${tableId}`,
    {
      inspection_id: payload.inspectionId,
      lab_id: payload.labId,
      review_summary: payload.reviewSummary,
      reviewer_name: payload.reviewerName ?? '',
      reviewed_at: payload.reviewedAt ?? new Date().toISOString(),
      attachment: payload.attachment ?? []
    },
    {
      headers: getHeaders({
        'Content-Type': 'application/json'
      })
    }
  );

  return response.data;
}
