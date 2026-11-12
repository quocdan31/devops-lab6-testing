# Báo cáo Lab 6: Kiểm thử & Phân tích Mã nguồn Tĩnh trong DevOps

## 1. Bảng So sánh 3 Loại Kiểm thử

| Tiêu chí | Postman / Newman | OWASP ZAP | SonarQube |
|----------|:---:|:---:|:---:|
| **Loại** | Functional Test | DAST (Security) | SAST (Static) |
| **Chạy ứng dụng?** | Có | Có | Không |
| **Phát hiện gì?** | API sai logic, sai status code, sai dữ liệu trả về | XSS, lộ thông tin header/CORS, thiếu security headers (`CSP`, `X-Frame-Options`) | Bugs, Code Smells, Vulnerabilities, Security Hotspots, Duplications |
| **Cần source code?** | Không (chỉ cần API) | Không (chỉ cần URL) | Có |
| **Giai đoạn CI** | Sau deploy | Sau deploy | Trước build |
| **Thời gian chạy** | ~0.5s (455ms) | ~120s | ~170s (2m50s) |
| **Tự động hóa được?** | Có (`Newman CLI`) | Có (`ZAP API`) | Có (`SonarScanner`) |
| **Số issues / kết quả** | 5/5 requests pass, 12/12 assertions pass (0 failed) | 60 alerts: 1 High (Reflected XSS), 16 Medium (CSP, Anti-clickjacking, CORS), 19 Low, 24 Info | 0 Bugs, 0 Vulnerabilities, 0 Code Smells, 2 Security Hotspots (`server.js`) |

---

## 2. Phân tích Kết quả Thực tế

### 2.1 Postman / Newman CLI
- Thực thi 5 requests (`GET /api/students`, `GET /api/students/SV001`, `POST /api/students`, `GET /api/students/SV999`, `POST` thiếu trường bắt buộc): **12/12 assertions pass**, thời gian phản hồi trung bình `35ms`.

### 2.2 OWASP ZAP (DAST)
- **High (1):** `Cross Site Scripting (Reflected)` tại `/api/search?q=` do phản hồi trực tiếp `q` trong HTML (`<p>Không tìm thấy sinh viên với từ khóa: <b>${q}</b></p>`) không escape.
- **Medium (16):** `Cross-Domain Misconfiguration` (`Access-Control-Allow-Origin: *`), `Content Security Policy (CSP) Header Not Set`, `Missing Anti-clickjacking Header` (`X-Frame-Options`).
- **Low (19):** `Server Leaks Information via "X-Powered-By"`, `X-Content-Type-Options Header Missing`, `Cross Site Scripting Weakness (Persistent in JSON Response)`.

### 2.3 SonarQube (SAST)
- **Metrics (`devops-lab6`):** `74` dòng code (NCLOC), `0` Bugs, `0` Vulnerabilities, `0` Code Smells, `0.0%` Duplications, Quality Gate: **Passed**.
- **Security Hotspots (2):**
  1. `server.js` dòng 3 (`javascript:S5689`): `express()` tiết lộ fingerprinting framework (`X-Powered-By`).
  2. `server.js` dòng 6 (`javascript:S5122`): `app.use(cors())` bật CORS cho phép mọi origin.

---

## 3. Kết luận DevOps

```text
SAST (SonarQube)  → chạy SỚM (trước build) → phát hiện lỗi code pattern & security hotspots
Unit Test         → chạy sau build        → phát hiện lỗi logic đơn vị
API Test (Newman) → chạy sau deploy       → phát hiện lỗi API contract & functional logic
DAST (ZAP)        → chạy sau deploy       → phát hiện lỗ hổng bảo mật runtime

Cả 4 loại đều cần thiết — không loại nào thay thế được loại nào.
```
