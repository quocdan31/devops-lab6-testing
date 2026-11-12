#!/bin/bash
# ===========================================
# CI Test Script — Lab 6 DevOps
# Tích hợp: SAST + API Test + DAST
# ===========================================
set +e

echo "========================================="
echo "  DEVOPS LAB 6 — CI TESTING PIPELINE"
echo "========================================="
echo ""

SERVER_PID=""
cleanup() {
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

SONAR_URL="${SONAR_HOST_URL:-http://127.0.0.1:9000}"
ZAP_URL="${ZAP_URL:-http://127.0.0.1:8080}"
TARGET_URL="${TARGET_URL:-http://127.0.0.1:3000}"

# --- Stage 1: SAST — Static Code Analysis ---
echo "[1/4] SAST — SonarQube Static Analysis..."
if [ -n "$SONAR_TOKEN" ]; then
  npx sonar-scanner \
    -Dsonar.projectKey=devops-lab6 \
    -Dsonar.sources=. \
    -Dsonar.exclusions=node_modules/**,newman-report.json,zap-report.html,.scannerwork/** \
    -Dsonar.host.url="$SONAR_URL" \
    -Dsonar.token="$SONAR_TOKEN" \
    && echo "  SAST passed" || echo "  WARNING: SAST completed with warnings or SonarQube unavailable"
else
  echo "  SKIP: SONAR_TOKEN is not set (export SONAR_TOKEN=... to run SonarQube scan)"
fi

# --- Stage 2: Start API Server ---
echo "[2/4] Starting API server..."
node server.js &
SERVER_PID=$!
sleep 3

if ! curl -sf "$TARGET_URL/api/students" > /dev/null; then
  echo "  ERROR: API server failed to start at $TARGET_URL"
  exit 1
fi
echo "  Server running (PID: $SERVER_PID)"

# --- Stage 3: API Functional Test ---
echo "[3/4] API Functional Test — Newman..."
npx newman run Student-API-Tests.json \
  --reporters cli,json \
  --reporter-json-export newman-report.json \
  --color on

NEWMAN_EXIT=$?
if [ $NEWMAN_EXIT -eq 0 ]; then
  echo "  All API tests passed!"
else
  echo "  API tests failed! Check newman-report.json"
fi

# --- Stage 4: DAST — ZAP Security Scan ---
echo "[4/4] DAST — OWASP ZAP Security Scan..."
if ! curl -sf "$ZAP_URL/JSON/core/view/version/" > /dev/null; then
  echo "  WARNING: Cannot connect to OWASP ZAP at $ZAP_URL. Skipping DAST stage."
else
  echo "  ZAP is running."

  echo "  Starting Spider scan..."
  RESP=$(curl -s "$ZAP_URL/JSON/spider/action/scan/?url=$TARGET_URL&maxChildren=10")
  SCAN_ID=$(printf '%s' "$RESP" | node -e "const fs=require('fs');const d=JSON.parse(fs.readFileSync(0,'utf8'));process.stdout.write(String(d.scan||''));")

  if [ -z "$SCAN_ID" ]; then
    echo "  ERROR: Cannot start Spider ($RESP)"
  else
    echo "  Spider Scan ID: $SCAN_ID"
    for _ in $(seq 1 60); do
      STATUS_RESP=$(curl -s "$ZAP_URL/JSON/spider/view/status/?scanId=$SCAN_ID")
      STATUS=$(printf '%s' "$STATUS_RESP" | node -e "const fs=require('fs');try{const d=JSON.parse(fs.readFileSync(0,'utf8'));process.stdout.write(String(Array.isArray(d)?(d[0]?.status??'0'):(d.status??'0')));}catch{process.stdout.write('0');}")
      echo "  Spider Progress: ${STATUS}%"
      [ "$STATUS" = "100" ] && break
      sleep 2
    done
  fi

  echo "  Starting Active Scan..."
  RESP=$(curl -s "$ZAP_URL/JSON/ascan/action/scan/?url=$TARGET_URL")
  ASCAN_ID=$(printf '%s' "$RESP" | node -e "const fs=require('fs');const d=JSON.parse(fs.readFileSync(0,'utf8'));process.stdout.write(String(d.scan||''));")

  if [ -z "$ASCAN_ID" ]; then
    echo "  ERROR: Cannot start Active Scan ($RESP)"
  else
    echo "  Active Scan ID: $ASCAN_ID"
    sleep 2
    for _ in $(seq 1 60); do
      STATUS_RESP=$(curl -s "$ZAP_URL/JSON/ascan/view/status/?scanId=$ASCAN_ID")
      STATUS=$(printf '%s' "$STATUS_RESP" | node -e "const fs=require('fs');try{const d=JSON.parse(fs.readFileSync(0,'utf8'));process.stdout.write(String(Array.isArray(d)?(d[0]?.status??'0'):(d.status??'0')));}catch{process.stdout.write('0');}")
      echo "  Active Scan Progress: ${STATUS}%"
      [ "$STATUS" = "100" ] && break
      sleep 5
    done
  fi

  echo "  Generating HTML report..."
  curl -s "$ZAP_URL/OTHER/core/other/htmlreport/" -o zap-report.html
  ALERTS=$(curl -s "$ZAP_URL/JSON/core/view/alertsSummary/" | node -e "const fs=require('fs');try{const d=JSON.parse(fs.readFileSync(0,'utf8'));const s=d.alertsSummary||{};process.stdout.write(String(Object.values(s).reduce((a,b)=>a+Number(b),0)));}catch{process.stdout.write('0');}")

  echo "=========================================="
  echo "ZAP Scan Completed | Alerts: ${ALERTS:-0}"
  echo "Report: zap-report.html"
  echo "=========================================="
fi

echo ""
echo "========================================="
echo "  PIPELINE COMPLETE!"
echo "========================================="
echo "Reports:"
echo "  SAST:     $SONAR_URL/dashboard?id=devops-lab6"
echo "  API Test: newman-report.json"
echo "  DAST:     zap-report.html"

exit $NEWMAN_EXIT
