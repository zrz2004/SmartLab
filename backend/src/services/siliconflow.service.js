import axios from 'axios';

import { config } from '../config.js';

export async function inspectImageWithSiliconFlow({ imageUrl, prompt }) {
  if (!config.siliconflow.apiKey) {
    throw new Error('Missing SiliconFlow API key.');
  }

  const response = await axios.post(
    `${config.siliconflow.baseUrl}/chat/completions`,
    {
      model: config.siliconflow.primaryModel,
      messages: [
        {
          role: 'system',
          content:
            'Return JSON only with sceneType, deviceType, riskLevel, confidence, reason, recommendedAction, evidence, labId, capturedAt, reviewStatus.'
        },
        {
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            { type: 'image_url', image_url: { url: imageUrl } }
          ]
        }
      ],
      response_format: { type: 'json_object' }
    },
    {
      headers: {
        Authorization: `Bearer ${config.siliconflow.apiKey}`,
        'Content-Type': 'application/json'
      }
    }
  );

  return response.data;
}
