# TIẾN ĐỘ

> Cập nhật sau mỗi sản phẩm. Nếu phiên làm việc bị ngắt, đọc file này + `PLAN.md` là tiếp tục được ngay.
> Nhánh làm việc: `claude/intelligent-curie-jvf8gw`.

## Trạng thái tổng

| # | Sản phẩm | Thư mục | Trạng thái |
|---|---|---|---|
| P1 | Ôn thi Vật lý 12 | `projects/01-on-thi-vat-ly-12/` | ✅ Xong (đã tự kiểm tra) |
| P2 | Orbit Lab | `projects/02-orbit-lab/` | ✅ Xong (đã tự kiểm tra) |
| P3 | Sổ tay công thức Vật lý 12 | `projects/03-so-tay-cong-thuc/` | ✅ Xong (đã tự kiểm tra) |
| P4 | Phòng thí nghiệm ảo Vật lý 12 | `projects/04-phong-thi-nghiem-ao/` | ✅ Xong (đã tự kiểm tra) |
| P5 | Bảng điều khiển ôn thi + sổ lỗi sai | `projects/05-bang-dieu-khien/` | ✅ Xong (đã tự kiểm tra) |
| P6 | Gói Toán 12 + Tư duy V-ACT | `projects/06-on-thi-toan-vact/` | ✅ Xong (đã tự kiểm tra) |
| P7 | Hub portfolio + lộ trình du học Đức | `projects/index.html`, `projects/07-lo-trinh-du-hoc-duc/` | ✅ Xong (đã tự kiểm tra) |
| P8 | Review code game Phi Thuyền | `projects/08-review-game/` | ✅ Xong (lỗi đã tái hiện) |

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

### P3 · Sổ tay công thức Vật lý 12 — ✅ XONG
- **Đã làm:** `formulas.js` (42 mục + hằng số), `index.html` (tìm không dấu, chế độ che công thức, in A4 4 trang).
- **Tự kiểm tra:** `node tools/test-formulas.js` → 16/16; đã xem bản PDF in thật.
- **Sửa trong vòng kiểm tra:** lỗi `${` trong template literal làm hỏng cả trang; tìm "bán rã" không ra (thêm từ khóa + tìm không dấu); công thức dạng chữ bị tràn (chuyển sang văn bản); bản in khi giao diện tối bị nền đen (ép bảng màu sáng khi in — áp dụng cho mọi trang).

### P4 · Phòng thí nghiệm ảo — ✅ XONG
- **Đã làm:** `labs-core.js` (lõi), `app.js` (4 thí nghiệm: khí lí tưởng, phóng xạ, Lenz, máy phát), mỗi cái 4 câu hỏi khám phá.
- **Tự kiểm tra:** `node tools/test-labs.js` → 17/17; `node tools/test-labs-ui.js` → 16/16; đã xem ảnh chụp.
- **Sửa trong vòng kiểm tra:** phản xạ ở pit-tông viết rối → viết lại; biểu thức kiểm tra số liệu máy phát trong test sai (ứng dụng đúng).
- **Còn tồn:** khí mô phỏng 2D (ghi rõ trên trang).

### P5 · Bảng điều khiển ôn thi — ✅ XONG
- **Đã làm:** `dash.js` (5 tab: tổng quan, kế hoạch tuần, Pomodoro & nhật ký, sổ lỗi sai có lịch ôn, dữ liệu), đọc thống kê từ `sl.quiz.*`.
- **Tự kiểm tra:** `node tools/test-dash.js` → 16/16.
- **Sửa trong vòng kiểm tra:** kỳ vọng sai trong test (ứng dụng tính đúng 67 %).
- **Cần xác minh:** ngày thi 2027 (đang để giả định).

### P6 · Toán 12 & Tư duy V-ACT — ✅ XONG
- **Đã làm:** `banks/toan12.js` (50 câu, 5 chủ đề), `banks/vact.js` (24 câu, 4 dạng), trang dùng chung engine với ô chọn ngân hàng.
- **Tự kiểm tra:** `node tools/verify-toan-vact.js` → 74/74; `validate-bank` → 0 lỗi; `test-quiz` → 51/51 (cả 2 ngân hàng). Chạy lại test P1 sau khi sửa engine → 29/29.
- **Sửa trong vòng kiểm tra:** engine giữ lựa chọn chương của ngân hàng khác → 0 câu (sửa: lọc theo ngân hàng đang mở); test giả định có câu Đúng/Sai; validator báo nhầm "chọn D…"; lời giải va-l6 viết "lùi" thay vì "tiến thêm" 1 thứ.

### P7 · Hub portfolio + Lộ trình du học Đức — ✅ XONG
- **Đã làm:** `projects/index.html` (hub có 8 ảnh thu nhỏ tạo bằng `tools/make-thumbs.js`), `projects/07-lo-trinh-du-hoc-duc/index.html` (tổng quan, 3 con đường, mốc thời gian, bảng trường, checklist 17 việc, nguồn). Đã tra cứu web ngày 19/10/2026 (trang APS & thị thực của Đại sứ quán Đức, DAAD, Uni Stuttgart, TUM + nguồn thứ cấp).
- **Tự kiểm tra:** `node tools/test-hub.js` → 14/14 (mọi liên kết nội bộ của 8 trang tồn tại, ảnh tải được, checklist lưu được, 14 nhãn "cần xác minh", điện thoại).
- **Sửa trong vòng kiểm tra:** số liệu tổng trên hub đếm lại cho đúng (140 đáp số, 7 mô phỏng, 340+ kiểm thử); CSS làm số lớn bị nhỏ.

### P8 · Nhận xét code game — ✅ XONG
- **Đã làm:** `projects/08-review-game/REVIEW.md` + `tools/probe-game-bugs.js` (tái hiện lỗi). Không sửa game.
- **Tự kiểm tra:** tái hiện được lỗi "quái đã chết vẫn trừ HP" (cần ≥ 2 quái), `autoShootInt` không về null; 2 nghi vấn khác chạy thử thấy **không** phải lỗi → ghi riêng.

### Kết thúc
- `README.md` gốc, `tools/run-all-tests.sh`, `SUMMARY.md`.
- Chạy toàn bộ: 13 bộ, 362 phép kiểm, tất cả đạt; kiểm thêm qua web server (http-server): 9 trang không lỗi.
- Trong lần chạy tổng, test Lenz bị chập chờn (phụ thuộc thời gian) → viết lại để di chuyển nam châm mỗi khung hình; phát hiện thêm lỗi trong chính test (đặt ngược điểm xuất phát) và sửa.

## Việc tiếp theo (gợi ý cho phiên sau)
1. Mở rộng ngân hàng câu hỏi (sóng điện từ, Toán lớp 10–11, thêm câu V-ACT phần ngôn ngữ).
2. Thay `prompt()` sửa ngày thi trong Bảng điều khiển bằng form.
3. Orbit Lab: lực cản khí quyển / bản 3D.

## Cách chạy toàn bộ kiểm thử
```bash
node tools/validate-bank.js projects/01-on-thi-vat-ly-12/banks/vatly12.js
node tools/verify-vatly12.js
node tools/test-quiz.js projects/01-on-thi-vat-ly-12/index.html [thư-mục-ảnh]
node tools/test-orbit.js
node tools/test-orbit-ui.js [thư-mục-ảnh]
node tools/test-formulas.js [thư-mục-ảnh]
node tools/test-labs.js
node tools/test-labs-ui.js [thư-mục-ảnh]
node tools/test-dash.js [thư-mục-ảnh]
node tools/verify-toan-vact.js
node tools/test-quiz.js projects/06-on-thi-toan-vact/index.html
node tools/test-hub.js
# hoặc tất cả một lần:
bash tools/run-all-tests.sh
```
