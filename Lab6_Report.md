# Báo cáo Lab 6: Kiểm thử & Phân tích Mã nguồn Tĩnh trong DevOps

## 1. Bảng So sánh 3 Loại Kiểm thử

| Tiêu chí | Postman / Newman | OWASP ZAP | SonarQube |
|----------|:---:|:---:|:---:|
| **Loại** | Functional Test | DAST (Security) | SAST (Static) |
| **Chạy ứng dụng?** | Có | Có | Không |
| **Phát hiện gì?** | API sai logic, sai status code, sai dữ liệu trả về | XSS, SQL Injection, lộ thông tin (`/api/debug`), thiếu security headers | Bugs, Code Smells, Vulnerabilities, Security Hotspots, Duplications |
| **Cần source code?** | Không (chỉ cần API) | Không (chỉ cần URL) | Có |
| **Giai đoạn CI** | Sau deploy | Sau deploy | Trước build |
| **Thời gian chạy** | ~2s | ~30s | ~30s |
| **Tự động hóa được?** | Có (`Newman CLI`) | Có (`ZAP API`) | Có (`SonarScanner`) |
| **Số issues / kết quả** | 5/5 requests pass, 12/12 assertions pass | Reflected XSS (`/api/search`), Info Disclosure (`/api/debug`), thiếu `X-Frame-Options` & `CSP` | Bugs, Code Smells, Security Hotspots trên `server.js` |

---

## 2. Phân tích Lỗ hổng & Vấn đề trong `server.js`

1. **Reflected XSS (`GET /api/search?q=`):** Phản hồi trực tiếp tham số `q` trong HTML (`<p>Không tìm thấy sinh viên với từ khóa: <b>${q}</b></p>`) mà không escape/sanitize dữ liệu đầu vào.
2. **Information Disclosure (`GET /api/debug`):** Trả về toàn bộ `process.env`, `process.memoryUsage()`, `process.uptime()`, làm lộ thông tin cấu hình và môi trường hệ thống.
3. **Thiếu Input Validation & Sanitization (`POST /api/students`):** Chỉ kiểm tra sự tồn tại của `id` và `name`, chưa kiểm tra kiểu dữ liệu và chưa làm sạch input.
4. **Mass Assignment (`PUT /api/students/:id`):** Sao chép trực tiếp toàn bộ `req.body` vào object sinh viên (`{ ...students[index], ...req.body }`), cho phép ghi đè cả trường `id`.
5. **Thiếu Security Headers & CORS mở rộng:** Dùng `app.use(cors())` mặc định (cho phép mọi origin) và chưa cấu hình các HTTP security headers như `X-Frame-Options`, `Content-Security-Policy`.

---

## 3. Kết luận DevOps

```text
SAST (SonarQube)  → chạy SỚM (trước build) → phát hiện lỗi code pattern
Unit Test         → chạy sau build        → phát hiện lỗi logic đơn vị
API Test (Newman) → chạy sau deploy       → phát hiện lỗi API contract
DAST (ZAP)        → chạy sau deploy       → phát hiện lỗ hổng bảo mật runtime

Cả 4 loại đều cần thiết — không loại nào thay thế được loại nào.
```
