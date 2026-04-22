import axios from 'axios';

import { config } from '../config.js';

const RESPONSE_SCHEMA_PROMPT =
  '你必须只返回一个 JSON 对象，字段固定为 sceneType、deviceType、riskLevel、confidence、reason、recommendedAction、evidence、labId、capturedAt、reviewStatus。sceneType 和 deviceType 保持英文枚举；riskLevel 只能是 critical、warning、info；reason、recommendedAction、evidence 必须使用简体中文。';

const REWRITE_SCHEMA_PROMPT =
  '你必须只返回一个 JSON 对象，字段固定为 reason、recommendedAction、evidence。请将输入内容改写为准确、简洁、专业的简体中文实验室安全描述，其中 evidence 必须是 2 到 4 条中文短句数组。';

async function requestSiliconFlow(messages, { responseFormat = { type: 'json_object' } } = {}) {
  const models = [
    config.siliconflow.primaryModel,
    config.siliconflow.backupModel,
    config.siliconflow.compatModel
  ].filter(Boolean);

  let lastError = null;

  for (const model of models) {
    try {
      const response = await axios.post(
        `${config.siliconflow.baseUrl}/chat/completions`,
        {
          model,
          messages,
          response_format: responseFormat
        },
        {
          headers: {
            Authorization: `Bearer ${config.siliconflow.apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return {
        ...response.data,
        modelUsed: model
      };
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError ?? new Error('SiliconFlow request failed.');
}

export async function inspectImageWithSiliconFlow({ imageUrl, prompt }) {
  if (!config.siliconflow.apiKey) {
    throw new Error('Missing SiliconFlow API key.');
  }

  return requestSiliconFlow([
    {
      role: 'system',
      content: RESPONSE_SCHEMA_PROMPT
    },
    {
      role: 'user',
      content: [
        { type: 'text', text: prompt },
        { type: 'image_url', image_url: { url: imageUrl } }
      ]
    }
  ]);
}

export async function rewriteInspectionTextToChinese({
  reason,
  recommendedAction,
  evidence
}) {
  if (!config.siliconflow.apiKey) {
    throw new Error('Missing SiliconFlow API key.');
  }

  return requestSiliconFlow([
    {
      role: 'system',
      content: REWRITE_SCHEMA_PROMPT
    },
    {
      role: 'user',
      content: JSON.stringify({
        reason,
        recommendedAction,
        evidence
      })
    }
  ]);
}
