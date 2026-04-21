import axios from 'axios';
import FormData from 'form-data';

import { config } from '../config.js';

export async function uploadToNocoDb({ buffer, fileName }) {
  if (!config.nocodb.apiToken) {
    throw new Error('Missing NocoDB API token.');
  }

  const formData = new FormData();
  formData.append('file', buffer, fileName);

  const response = await axios.post(
    `${config.nocodb.baseUrl}/api/v2/storage/upload`,
    formData,
    {
      headers: {
        ...formData.getHeaders(),
        'xc-token': config.nocodb.apiToken
      }
    }
  );

  return response.data;
}
