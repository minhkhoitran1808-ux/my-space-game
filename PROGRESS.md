# TIẾN ĐỘ

> Cập nhật sau mỗi sản phẩm. Nếu phiên làm việc bị ngắt, đọc file này + `PLAN.md` là tiếp tục được ngay.
> Nhánh làm việc: `claude/intelligent-curie-jvf8gw`.

## Trạng thái tổng

| # | Sản phẩm | Thư mục | Trạng thái |
|---|---|---|---|
| P1 | Ôn thi Vật lý 12 | `projects/01-on-thi-vat-ly-12/` | ✅ Xong (đã tự kiểm tra) |
| P2 | Orbit Lab | `projects/02-orbit-lab/` | ✅ Xong (đã tự kiểm tra) |
| P3 | Sổ tay công thức Vật lý 12 | `projects/03-so-tay-cong-thuc/` | ⏳ Tiếp theo |
| P4 | Phòng thí nghiệm ảo Vật lý 12 | `projects/04-phong-thi-nghiem-ao/` | ⬜ Chưa làm |
| P5 | Bảng điều khiển ôn thi + sổ lỗi sai | `projects/05-bang-dieu-khien/` | ⬜ Chưa làm |
| P6 | Gói Toán 12 + Tư duy V-ACT | `projects/06-on-thi-toan-vact/` | ⬜ Chưa làm |
| P7 | Hub portfolio + lộ trình du học Đức | `projects/index.html`, `projects/07-lo-trinh-du-hoc-duc/` | ⬜ Chưa làm |
| P8 | Review code game Phi Thuyền | `projects/08-review-game/` | ⬜ Chưa làm |

## Nhật ký

### P1 · Ôn thi Vật lý 12 — ✅ XONG
- **Đã làm:**
  - Hạ tầng chung: `projects/shared/theme.css` (sáng/tối), `projects/shared/common.js` (lưu trữ, định dạng, KaTeX), KaTeX 0.16.22 đặt sẵn offline trong `projects/shared/vendor/katex/` (chỉ woff2, ~600 KB).
  - Engine ôn thi dùng chung `projects/shared/quiz/` — 3 dạng câu, Leitner 5 hộp, sổ câu sai, thi thử có đồng hồ + chấm thang 2025, thống kê, xuất/nhập JSON, hỗ trợ nhiều ngân hàng (P6 sẽ dùng lại).
  - Ngân hàng `banks/vatly12.js`: 99 câu (59 TN / 16 Đ-S / 24 TLN), 4 chương, có lời giải, phân tích phương án nhiễu, 2 hình SVG.
- **Tự kiểm tra (đều đạt):**
  - `node tools/validate-bank.js projects/01-on-thi-vat-ly-12/banks/vatly12.js` → 0 lỗi, 671 công thức render được.
  - `node tools/verify-vatly12.js` → 76/76 phép kiểm đáp số đạt (sau khi sửa 5 trường hợp script báo "trùng số" — thực ra là phương án khác chữ tăng/giảm, tỏa/thu → đã thêm kiểm tra theo chữ).
  - `node tools/test-quiz.js projects/01-on-thi-vat-ly-12/index.html` → 29/29 đạt: luyện chương, phím tắt, sổ sai, thi thử làm đúng hết = 10/10, để trống = 0, chấm Đúng/Sai từng phần, lọc ngân hàng, xóa dữ liệu, không tràn ngang ở 375 px, console sạch.
  - Đã xem ảnh chụp giao diện (nền tối + sáng, máy tính + điện thoại).
- **Sửa trong vòng kiểm tra:** cảnh báo KaTeX với chữ Việt trong `\text{}` (lọc riêng cảnh báo vô hại), thiếu định dạng `code`, 4 chú thích phương án nhiễu chưa chuẩn.
- **Còn tồn / cần xác minh:** cấu trúc đề 2027 (đang theo đề 2025); chưa có câu hỏi về sóng điện từ chi tiết (mới 1 câu Đ/S + 2 câu TN).

### P2 · Orbit Lab — ✅ XONG
- **Đã làm:** `orbit.js` (lõi vật lý thuần, chạy được trong Node), `app.js` + `index.html` + `style.css` (4 tab: mô phỏng quỹ đạo, Hohmann, tên lửa, 9 bài tập có lời giải).
- **Tự kiểm tra:** `node tools/test-orbit.js` → 31/31 (so với giá trị tham chiếu + độ chính xác số); `node tools/test-orbit-ui.js` → 22/22.
- **Sửa trong vòng kiểm tra:** quạt Kepler bị xóa sau mỗi chu kì (→ vòng xoay 12 quạt); `hidden` bị `display:grid` đè (→ quy tắc chung trong theme.css); khung Hohmann/sandbox căn tỉ lệ khi canvas còn ẩn (→ căn trễ khi vẽ); điểm sáng hành tinh quá gắt.
- **Còn tồn:** không có lực cản khí quyển, chỉ 2D (ghi trong README).

## Việc tiếp theo
1. P3 Sổ tay công thức Vật lý 12 (in được A4).

## Cách chạy toàn bộ kiểm thử
```bash
node tools/validate-bank.js projects/01-on-thi-vat-ly-12/banks/vatly12.js
node tools/verify-vatly12.js
node tools/test-quiz.js projects/01-on-thi-vat-ly-12/index.html [thư-mục-ảnh]
node tools/test-orbit.js
node tools/test-orbit-ui.js [thư-mục-ảnh]
```
