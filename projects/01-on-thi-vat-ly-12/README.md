# P1 · Ôn thi Vật lý 12 (dạng đề THPT mới)

Ứng dụng web ôn thi Vật lý 12 theo Chương trình GDPT 2018, đúng 3 dạng câu của đề thi tốt nghiệp THPT từ 2025:
**trắc nghiệm nhiều lựa chọn**, **Đúng/Sai (4 ý)**, **trả lời ngắn (tối đa 4 ký tự)**.

## Có gì bên trong

| Tính năng | Mô tả |
|---|---|
| Ngân hàng 99 câu | 4 chương: Vật lí nhiệt · Khí lí tưởng · Từ trường · Vật lí hạt nhân (59 trắc nghiệm, 16 Đúng/Sai, 24 trả lời ngắn), 4 mức độ Biết → Vận dụng cao |
| Lời giải chi tiết | Mọi câu đều có lời giải từng bước; nhiều câu có **phân tích phương án nhiễu** (vì sao phương án sai lại "hấp dẫn") và mục **Mẹo / bẫy hay gặp** |
| Lặp lại ngắt quãng | Hệ thống hộp Leitner 5 hộp: làm sai → hộp 1 (ôn lại sau 10 phút); làm đúng → lên hộp, chờ 1 / 3 / 7 / 21 ngày |
| Sổ câu sai | Tự động ghi câu làm sai; câu tự rời sổ khi làm đúng **2 lần liên tiếp** |
| Thi thử | 18 + 4 + 6 câu, 50 phút, đồng hồ đếm ngược, bảng điều hướng câu; chấm đúng thang điểm mới (Đúng/Sai: 1/2/3/4 ý đúng = 0,1 / 0,25 / 0,5 / 1 điểm); bài làm dở được lưu khi tải lại trang |
| Thống kê | Tiến độ từng chương, tỉ lệ đúng, chuỗi ngày học, biểu đồ điểm thi thử, gợi ý chương yếu |
| Sao lưu | Xuất / nhập tệp JSON (gộp thông minh, không mất dữ liệu) |

## Cách mở

- **Cách nhanh nhất:** mở tệp `index.html` bằng Chrome/Edge/Firefox (nhấp đúp). Không cần cài gì, chạy offline.
- **Hoặc** qua web server: từ thư mục gốc repo chạy `npx http-server -c-1` rồi vào `http://localhost:8080/projects/01-on-thi-vat-ly-12/`.
- Khi đưa repo lên GitHub Pages, trang nằm ở `…/projects/01-on-thi-vat-ly-12/`.

Phím tắt khi luyện: <kbd>1</kbd>–<kbd>4</kbd> hoặc <kbd>A</kbd>–<kbd>D</kbd> chọn đáp án · <kbd>Enter</kbd> kiểm tra / sang câu.

## Độ tin cậy của nội dung

- **Mọi đáp số tính toán** (30 câu trắc nghiệm có số liệu, 24 câu trả lời ngắn, 22 ý Đúng/Sai có tính toán — tổng 76 phép kiểm) được tính lại **độc lập** bằng `tools/verify-vatly12.js`. Script cũng kiểm tra rằng không phương án nhiễu nào trùng giá trị đúng.
- `tools/validate-bank.js` kiểm tra cấu trúc (id trùng, đủ 4 phương án/4 ý, đáp án ngắn ≤ 4 ký tự…) và **render thử toàn bộ 671 công thức KaTeX**.
- Hằng số dùng thống nhất và luôn ghi trong đề: $T = t + 273$, $R = 8{,}31$, $k = 1{,}38\cdot10^{-23}$, $N_A = 6{,}02\cdot10^{23}$, $1\,\mathrm u = 931{,}5\ \mathrm{MeV}/c^2$, $m_p = 1{,}0073\ \mathrm u$, $m_n = 1{,}0087\ \mathrm u$.
- **Cần xác minh:** cấu trúc đề (18 + 4 + 6 câu, 50 phút) là của kỳ thi 2025; cần kiểm tra lại khi Bộ GD&ĐT công bố quy chế 2027. Cách gọi tên vài khái niệm có thể khác nhẹ giữa 3 bộ SGK.

## Cấu trúc thư mục

```
01-on-thi-vat-ly-12/
├── index.html          # trang ứng dụng (nạp engine dùng chung + ngân hàng)
├── banks/vatly12.js    # ngân hàng câu hỏi
└── README.md
../shared/quiz/         # engine ôn thi dùng chung (quiz.js, quiz.css) — P6 dùng lại
../shared/common.js     # tiện ích: lưu trữ, định dạng, KaTeX, giao diện sáng/tối
```

## Thêm câu hỏi mới

Mở `banks/vatly12.js`, thêm vào mảng của chương tương ứng. Ba mẫu:

```js
{ id: 'khi-16', type: 'mcq', level: 2,           // level: 1 Biết, 2 Hiểu, 3 Vận dụng, 4 Vận dụng cao
  q: R`Câu hỏi, công thức trong $...$`,
  choices: [R`...`, R`...`, R`...`, R`...`],      // đúng 4 phương án, sẽ được xáo trộn khi hiển thị
  answer: 1,                                      // chỉ số phương án đúng (0–3)
  why: [R`vì sao sai`, null, null, null],         // (tuỳ chọn) phân tích phương án nhiễu
  explain: R`Lời giải...`, tip: R`(tuỳ chọn) bẫy hay gặp` },

{ id: 'khi-tf5', type: 'tf', level: 3, q: R`Đề chung...`,
  statements: [ { s: R`ý a`, a: true, e: R`giải thích` }, /* đủ 4 ý */ ],
  explain: R`Tổng kết...` },

{ id: 'khi-s7', type: 'short', level: 3, q: R`...`,
  answer: '2,5',             // chuỗi ≤ 4 ký tự, dấu phẩy thập phân
  tol: 0.1,                  // (tuỳ chọn) sai số chấp nhận; mặc định phải khớp chính xác
  unit: 'atm', explain: R`...` }
```

Quy ước soạn: dùng `R\`...\`` để giữ nguyên dấu `\` của LaTeX; không viết `${` (dùng macro `\nuc{A}{Z}{X}` cho kí hiệu hạt nhân); lời giải **không** nhắc chữ cái phương án vì phương án bị xáo trộn. Sau khi sửa, chạy:

```bash
node tools/validate-bank.js projects/01-on-thi-vat-ly-12/banks/vatly12.js
node tools/verify-vatly12.js        # nhớ thêm dòng kiểm tra cho câu tính toán mới
node tools/test-quiz.js projects/01-on-thi-vat-ly-12/index.html
```

## Dữ liệu cá nhân

Tiến độ lưu trong `localStorage` của trình duyệt (khóa `sl.quiz.vatly12.v1`), không gửi đi đâu. Đổi máy/trình duyệt → dùng **Dữ liệu → Xuất tệp sao lưu**. Lưu ý: mở bằng `file://` và mở qua `http://` là hai "nơi lưu" khác nhau.
