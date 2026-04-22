const appToDbLabIdMap = new Map([
  ['lab_yuanlou_806', 1],
  ['lab_xixue_xinke', 2],
  ['1', 1],
  ['2', 2]
]);

const dbToAppLabIdMap = new Map([
  [1, 'lab_yuanlou_806'],
  [2, 'lab_xixue_xinke']
]);

const legacyLabPresentation = new Map([
  [1, {
    name: '院楼806实验室',
    building_name: '信息科学楼',
    floor: '8F',
    room_number: '806',
    type: 'computer',
    description: '计算机与信息安全实验室'
  }],
  [2, {
    name: '西学楼一楼信科实验室',
    building_name: '西学楼',
    floor: '1F',
    room_number: '101',
    type: 'electronics',
    description: '信科综合实验室'
  }]
]);

export function toDatabaseLabId(labId) {
  if (labId === null || labId === undefined) return null;
  const normalized = String(labId);
  return appToDbLabIdMap.get(normalized) ?? (Number.isNaN(Number(normalized)) ? null : Number(normalized));
}

export function toExternalLabId(labId) {
  if (labId === null || labId === undefined) return null;
  const numeric = Number(labId);
  return dbToAppLabIdMap.get(numeric) ?? String(labId);
}

export function getSupportedLegacyLabIds() {
  return [...dbToAppLabIdMap.keys()];
}

export function mapLegacyLabRow(row) {
  if (!row) return null;
  const databaseId = Number(row.id);
  const presentation = legacyLabPresentation.get(databaseId) ?? {};

  return {
    id: toExternalLabId(databaseId),
    database_id: databaseId,
    name: presentation.name ?? row.name,
    building_id: row.building_id != null ? String(row.building_id) : '',
    building_name: presentation.building_name ?? row.building_name ?? 'SmartLab Building',
    floor: presentation.floor ?? (row.floor != null ? `${row.floor}F` : ''),
    room_number: presentation.room_number ?? row.room_number ?? '',
    type: presentation.type ?? row.type ?? 'general',
    description: presentation.description ?? row.description ?? null,
    safety_score: row.safety_score != null ? Number(row.safety_score) : 100,
    status: row.status ?? 'normal',
    device_count: row.device_count != null ? Number(row.device_count) : 0
  };
}
