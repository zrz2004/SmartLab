import { mediaRecords as memoryMedia } from '../data/store.js';

class MediaRepository {
  create(record) {
    memoryMedia.unshift(record);
    return record;
  }

  getById(id) {
    return memoryMedia.find((item) => item.id === id) ?? null;
  }
}

export const mediaRepository = new MediaRepository();
