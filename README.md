# DevOps Lab 6: Kiểm thử & Phân tích Mã nguồn Tĩnh

Repository thực hành **Bài 6 — Kiểm thử & Phân tích Mã nguồn Tĩnh trong DevOps** (Postman/Newman CLI, OWASP ZAP DAST, SonarQube SAST, và CI Pipeline).

## Cấu trúc Dự án

```text
.
├── server.js                    # Sample Student API (Node.js + Express)
├── package.json                 # Dependencies & npm scripts
├── Student-API-Tests.json       # Postman Collection v2.1 (5 requests, 12 assertions)
├── Student-API-Env.json         # Postman Environment ({{base_url}})
├── newman-report.json           # Kết quả chạy Newman CLI
├── sonar-project.properties     # Cấu hình SonarQube Scanner
├── ci-test.sh                   # Script CI tổng hợp (SAST + API Test + DAST)
├── Jenkinsfile                  # Pipeline mẫu cho Jenkins (mở rộng)
├── .github/workflows/ci.yml     # GitHub Actions CI chạy Newman API Tests
└── Lab6_Report.md               # Bảng so sánh 3 loại kiểm thử & phân tích kết quả
```

## Hướng dẫn Chạy Nhanh

### 1. Cài đặt & Chạy Sample API

```bash
npm install
npm start
```

Kiểm tra API tại `http://localhost:3000/api/students`:

```bash
curl http://localhost:3000/api/students
```

### 2. Chạy API Functional Tests với Newman CLI

Trong terminal khác (khi `server.js` đang chạy):

```bash
npm run test:api
```

Hoặc chạy trực tiếp:

```bash
npx newman run Student-API-Tests.json --reporters cli,json --reporter-json-export newman-report.json
```

**Kết quả đã kiểm chứng:** 5/5 requests pass, 12/12 assertions pass, 0 failed.

### 3. Quét Bảo mật DAST với OWASP ZAP (khi đã cài ZAP)

1. Khởi động OWASP ZAP (proxy mặc định `http://127.0.0.1:8080`, bật API và tắt API Key nếu dùng script).
2. Chạy Automated Scan vào `http://localhost:3000` hoặc dùng Stage 4 trong `ci-test.sh`.
3. Xuất báo cáo ra `zap-report.html`.

### 4. Phân tích Mã nguồn Tĩnh SAST với SonarQube (khi có Docker)

```bash
docker run -d --name lab6-sonarqube -p 9000:9000 -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true sonarqube:lts-community
```

Sau khi tạo project `devops-lab6` và lấy token trên `http://localhost:9000`:

```bash
export SONAR_TOKEN=<your-token>
npx sonar-scanner -Dsonar.token=$SONAR_TOKEN
```

### 5. Chạy CI Script Tổng hợp

```bash
bash ci-test.sh
```

> Lưu ý: Nếu chưa set `SONAR_TOKEN` hoặc chưa bật OWASP ZAP, `ci-test.sh` sẽ bỏ qua các stage chưa sẵn sàng và vẫn chạy stage khởi động API + Newman tests.
