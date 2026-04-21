# SmartLab Backend

This folder now contains a runnable in-memory backend for SmartLab. It is intended as the bridge between the current Flutter app and the future production backend repository.

## What works now

- User registration with pending review
- Login, logout, refresh token, and `/auth/me`
- Pending registration approval and rejection
- RBAC permissions with `/permissions/me`
- Two fixed labs with accessible-lab filtering and lab switching
- Media upload with local fallback and optional NocoDB upload proxy
- AI inspection creation with SiliconFlow attempt and server-side fallback normalization
- Unified alert list with sensor alerts and AI alerts
- Basic devices and chemicals inventory endpoints for front-end integration

## Run locally

```bash
cd backend
npm install
npm start
```

Server default:

- `http://127.0.0.1:3000`
- Health check: `GET /health`
- API prefix: `/api/v1`

Default local test accounts:

- `admin / admin123`
- `teacher / teacher123`
- `graduate / graduate123`
- `student / student123`

## Notes

- Secrets must stay on the server only. Do not place SiliconFlow or NocoDB credentials into Flutter code.
- The previously exposed SiliconFlow key must be rotated before any real deployment.
- Current lab scope is fixed to the two documented locations only, matching `LabConfig` and database seeds.
- NocoDB upload is optional in this in-memory backend. If NocoDB configuration is missing, media files stay in local memory for the current process lifetime.
