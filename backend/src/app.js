import cors from 'cors';
import express from 'express';

import { config } from './config.js';
import alertsRoutes from './routes/alerts.routes.js';
import aiRoutes from './routes/ai.routes.js';
import authRoutes from './routes/auth.routes.js';
import chemicalsRoutes from './routes/chemicals.routes.js';
import controlRoutes from './routes/control.routes.js';
import devicesRoutes from './routes/devices.routes.js';
import labsRoutes from './routes/labs.routes.js';
import mediaRoutes from './routes/media.routes.js';
import permissionsRoutes from './routes/permissions.routes.js';
import telemetryRoutes from './routes/telemetry.routes.js';

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    date: new Date().toISOString(),
    apiPrefix: config.apiPrefix
  });
});

app.use(`${config.apiPrefix}/auth`, authRoutes);
app.use(`${config.apiPrefix}/permissions`, permissionsRoutes);
app.use(`${config.apiPrefix}/labs`, labsRoutes);
app.use(`${config.apiPrefix}/devices`, devicesRoutes);
app.use(`${config.apiPrefix}/control`, controlRoutes);
app.use(`${config.apiPrefix}/telemetry`, telemetryRoutes);
app.use(`${config.apiPrefix}/chemicals`, chemicalsRoutes);
app.use(`${config.apiPrefix}/media`, mediaRoutes);
app.use(`${config.apiPrefix}/ai-inspections`, aiRoutes);
app.use(`${config.apiPrefix}/alerts`, alertsRoutes);

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(error.statusCode ?? 500).json({
    message: error.message ?? 'Internal server error.'
  });
});

export default app;
