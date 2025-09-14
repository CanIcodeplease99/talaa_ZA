#!/usr/bin/env bash
set -euo pipefail
ORG="${ORG:-your-org}"; NAME="Talaa_ZA_v3_3_5_full"
git init; git add -A; git commit -m "init v3_3_5_full" || true; git branch -M main
if command -v gh >/dev/null 2>&1; then gh repo create "$ORG/$NAME" --private --source . --remote origin --push || true
else git remote add origin https://github.com/$ORG/$NAME.git || true; git push -u origin main || true; fi
echo "Pushed to https://github.com/$ORG/$NAME"
