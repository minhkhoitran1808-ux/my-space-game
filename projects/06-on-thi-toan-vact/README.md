# P6 · Ôn thi Toán 12 & Tư duy V-ACT

Dùng chung engine với P1 (lặp lại ngắt quãng, sổ câu sai, thi thử, thống kê, sao lưu). Chọn ngân hàng ở ô cạnh tên trang.

| Ngân hàng | Nội dung | Thi thử |
|---|---|---|
| **Toán 12** — 50 câu (28 trắc nghiệm, 9 Đúng/Sai, 13 trả lời ngắn) | Ứng dụng đạo hàm · Nguyên hàm & tích phân · Vectơ & tọa độ Oxyz · Số đặc trưng độ phân tán (ghép nhóm) · Xác suất có điều kiện (toàn phần, Bayes). Nhiều câu gắn Vật lý / hàng không (tên lửa mô hình, máy bay cất cánh trong Oxyz, quãng đường = tích phân vận tốc). | 12 + 4 + 6 câu, 90 phút, thang điểm 2025 (trả lời ngắn 0,5 điểm/câu) |
| **Tư duy V-ACT** — 24 câu trắc nghiệm | Suy luận logic · Phân tích số liệu (bảng) · Suy luận khoa học (biến độc lập/kiểm soát, sai số, thiết kế thí nghiệm) · Toán ứng dụng | Đề luyện 20 câu / 30 phút |

## Cách mở
Mở `index.html`. Tiến độ Toán và V-ACT lưu riêng (`sl.quiz.toan12.v1`, `sl.quiz.vact.v1`) và hiện trong Bảng điều khiển (P5).

## Độ tin cậy
- `node tools/verify-toan-vact.js` tính lại **độc lập cả 74 câu**: đạo hàm/cực trị bằng đạo hàm số và quét giá trị, tích phân bằng Simpson, thống kê ghép nhóm tính từ bảng, xác suất bằng liệt kê, bài logic bằng duyệt mọi trường hợp, ngày trong tuần bằng lịch máy tính. 10 câu thuần lý thuyết/suy luận định tính được ghi rõ là "đã đọc lại" thay vì tính.
- `node tools/validate-bank.js projects/06-on-thi-toan-vact/banks/*.js` — cấu trúc + 379 công thức KaTeX.
- `node tools/test-quiz.js projects/06-on-thi-toan-vact/index.html` — 51 phép kiểm giao diện cho cả hai ngân hàng (làm đúng hết = 10/10).

## Cần xác minh
- Cấu trúc đề Toán 2027 (đang theo đề 2025). Đề thật còn có kiến thức lớp 10–11 — gói này mới tập trung lớp 12.
- Cấu trúc đề V-ACT 2027 (đề thật khoảng 120 câu / 150 phút, gồm cả Tiếng Việt, Tiếng Anh). Gói này chỉ luyện **kiểu tư duy**; bảng số liệu là giả định.
