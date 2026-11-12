# Báo cáo Tổng hợp Lab 6: Kiểm thử & Phân tích Mã nguồn Tĩnh trong DevOps

## 1. Bảng So sánh 3 Loại Kiểm thử (Bước 6.1)

| Tiêu chí | Postman / Newman | OWASP ZAP | SonarQube |
|----------|:---:|:---:|:---:|
| **Loại** | Functional Test (API) | DAST (Dynamic Application Security Testing) | SAST (Static Application Security Testing) |
| **Chạy ứng dụng?** | Có | Có | Không |
| **Phát hiện gì?** | API sai logic, sai status code, sai schema, response time chậm | XSS, SQL Injection, lộ thông tin (`/api/debug`), thiếu security headers (`X-Frame-Options`, `CSP`) | Bugs, Code Smells, Vulnerabilities, Security Hotspots, Duplications |
| **Cần source code?** | Không (chỉ cần endpoint API) | Không (chỉ cần URL đang chạy) | Có |
| **Giai đoạn CI** | Sau deploy / sau khi start server | Sau deploy / staging | Trước build (hoặc song song khi build) |
| **Thời gian chạy** | ~186ms (thực tế với Newman trên máy local) | ~30s–2 phút (tùy spider + active scan) | ~30s |
| **Tự động hóa được?** | Có (`newman run ...`) | Có (ZAP API / `ci-test.sh`) | Có (`sonar-scanner`) |
| **Kết quả trên Lab 6** | **5/5 requests pass, 12/12 assertions pass, 0 failed** (đã chạy thực tế) | *Chưa chạy thực tế trên máy này do chưa cài OWASP ZAP* — lý thuyết trên `server.js` có các lỗ hổng mục tiêu: Reflected XSS (`/api/search?q=`), Info Disclosure (`/api/debug`), thiếu `X-Frame-Options` & `CSP` | *Chưa chạy thực tế trên máy này do chưa cài Docker Desktop* — lý thuyết trên `server.js` có: CORS `*`, endpoint `/api/debug` lộ `process.env`, biến `students` dùng `let` nhưng không gán lại, reflected HTML từ `req.query.q` |

---

## 2. Phân tích Chi tiết Các Lỗ hổng & Vấn đề trong `server.js`

1. **Reflected XSS (`GET /api/search?q=`):**
   - `res.send(\`<p>Không tìm thấy sinh viên với từ khóa: <b>\${q}</b></p>\`)` phản hồi trực tiếp query `q` dưới dạng HTML mà không escape/encode.
   - **Cách phát hiện:** OWASP ZAP (DAST) gửi payload `<script>...</script>` và phát hiện phản hồi không escape; SonarQube (SAST) cũng có thể cảnh báo Security Hotspot / XSS sink.
2. **Information Disclosure (`GET /api/debug`):**
   - Trả về toàn bộ `process.env`, `process.memoryUsage()`, `process.uptime()`, có thể làm lộ biến môi trường nhạy cảm.
   - **Cách phát hiện:** OWASP ZAP spider/scan phát hiện endpoint debug; review / SAST cảnh báo Security Hotspot.
3. **Thiếu Validate & Sanitize Input (`POST /api/students`):**
   - Chỉ kiểm tra `!id || !name`, chưa kiểm tra kiểu dữ liệu (`age`, `grade`), độ dài hoặc ký tự đặc biệt.
4. **Mass Assignment (`PUT /api/students/:id`):**
   - Dùng `{ ...students[index], ...req.body }` cho phép ghi đè mọi thuộc tính kể cả `id`.
5. **Thiếu Security Headers & CORS mở rộng (`app.use(cors())`):**
   - Chưa dùng `helmet` nên thiếu `X-Frame-Options`, `Content-Security-Policy`, `X-Content-Type-Options`.
   - `cors()` mặc định cho phép tất cả origin (`*`) — SonarQube đánh dấu Security Hotspot.

---

## 3. Kết luận DevOps (Bước 6.2)

```text
SAST (SonarQube) → chạy SỚM (trước build) → phát hiện lỗi code pattern & security hotspots
Unit Test        → chạy sau build        → phát hiện lỗi logic đơn vị
API Test (Newman)→ chạy sau deploy       → phát hiện lỗi API contract & functional logic
DAST (ZAP)       → chạy sau deploy       → phát hiện lỗ hổng bảo mật runtime

Cả 4 loại đều cần thiết và bổ trợ cho nhau — không loại nào thay thế được loại nào.
```
