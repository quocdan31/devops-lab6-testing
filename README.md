# Lab 6: Kiểm thử & Phân tích Mã nguồn Tĩnh trong DevOps

## Cấu trúc thư mục

```text
.
├── server.js                    # Sample Student API (Node.js + Express)
├── package.json                 # Khai báo dependencies và scripts
├── Student-API-Tests.json       # Postman Collection v2.1 (5 requests, 12 assertions)
├── newman-report.json           # Báo cáo kết quả chạy Newman CLI
├── sonar-project.properties     # Cấu hình SonarQube Scanner
├── ci-test.sh                   # Script CI pipeline (SAST + API Test + DAST)
├── Lab6_Report.md               # Báo cáo so sánh 3 loại kiểm thử (Bước 6)
└── README.md
```

## Hướng dẫn chạy

### 1. Khởi động Sample API

```bash
npm install
npm start
```

API chạy tại `http://localhost:3000`:
- `GET /api/students`
- `GET /api/students/:id`
- `POST /api/students`
- `PUT /api/students/:id`
- `DELETE /api/students/:id`
- `GET /api/search?q=`
- `GET /api/debug`

### 2. Kiểm thử API với Newman CLI

```bash
npx newman run Student-API-Tests.json --reporters cli,json --reporter-json-export newman-report.json
```

### 3. Quét bảo mật với OWASP ZAP (DAST)

Khởi động OWASP ZAP (proxy `http://127.0.0.1:8080`, bật API và tắt API Key), thực hiện Spider + Active Scan đối với `http://localhost:3000` và xuất báo cáo `zap-report.html`.

### 4. Phân tích mã nguồn tĩnh với SonarQube (SAST)

```bash
docker run -d --name lab6-sonarqube -p 9000:9000 -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true sonarqube:lts-community
npx sonar-scanner -Dsonar.token=<SONAR_TOKEN>
```

### 5. Chạy CI Script

```bash
bash ci-test.sh
```
