import { mediaRecords as memoryMedia } from '../data/store.js';
import { hasTable, isDatabaseConfigured, isLegacySchema, query } from '../db.js';
import { toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';

class MediaRepository {
  async create(record) {
    if (!isDatabaseConfigured() || !(await hasTable('media_records'))) {
      memoryMedia.unshift(record);
      return record;
    }

    const databaseLabId = await isLegacySchema() ? toDatabaseLabId(record.metadata?.labId) : record.metadata?.labId;
    const result = await query(
      `
      insert into media_records (
        id, lab_id, file_name, mime_type, size_bytes, storage_provider, storage_url, metadata, created_by
      )
      values ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9)
      returning *
      `,
      [
        record.id,
        databaseLabId ?? null,
        record.fileName,
        record.mimeType,
        record.size,
        record.provider,
        record.url,
        JSON.stringify(record.metadata ?? {}),
        record.createdBy ?? null
      ]
    );

    memoryMedia.unshift(record);

    return {
      ...record,
      persisted: true,
      databaseId: result.rows[0]?.id,
      metadata: {
        ...(record.metadata ?? {}),
        ...(databaseLabId != null ? { labId: toExternalLabId(databaseLabId) } : {})
      }
    };
  }

  async getById(id) {
    const memoryRecord = memoryMedia.find((item) => item.id === id);
    if (memoryRecord) {
      return memoryRecord;
    }

    if (!isDatabaseConfigured() || !(await hasTable('media_records'))) {
      return null;
    }

    const result = await query('select * from media_records where id = $1 limit 1', [id]);
    if (result.rowCount === 0) {
      return null;
    }

    const row = result.rows[0];
    return {
      id: row.id,
      fileName: row.file_name,
      mimeType: row.mime_type,
      size: row.size_bytes,
      buffer: null,
      metadata: {
        ...(row.metadata ?? {}),
        ...(row.lab_id != null ? { labId: toExternalLabId(row.lab_id) } : {})
      },
      url: row.storage_url,
      provider: row.storage_provider,
      createdAt: row.created_at
    };
  }
}

export const mediaRepository = new MediaRepository();
