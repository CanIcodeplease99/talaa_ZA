# Talaa ZA Backend (Starter)

Minimal Express + SQLite API for auth and profile.

## Quickstart
```bash
cp .env.sample .env
npm install
npm run dev
# open http://localhost:4000/health
```

## Endpoints
- `POST /auth/register` { email, password, name? }
- `POST /auth/login` { email, password }
- `GET /me` (Bearer token)
- `PUT /me` { name } (Bearer token)

Tokens expire in 7 days. Store securely on device.