# Talaa ZA Frontend (Source Starter)

These files are meant to be copied into an **existing React Native CLI app** (like TalaaZAApp).

## How to use
1) In your RN app root (e.g., `TalaaZAApp/`):
   - Install deps:
     ```bash
     npm i @react-navigation/native @react-navigation/native-stack axios
     npx pod-install ios || true
     ```
2) Copy files:
   - Put `App.tsx` into the app root (replace existing).
   - Put the `src/` folder into the app root.
3) Point the API URL:
   - In `src/api.ts`, set `API_BASE` to your backend URL.
     For Android emulator: `http://10.0.2.2:4000`.
4) Run:
   ```bash
   # Android debug
   npm run android
   # Release via CI uses Gradle (already configured)
   ```