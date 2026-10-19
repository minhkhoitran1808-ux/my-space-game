# KẾ HOẠCH — Bộ công cụ học tập & portfolio

> Lập ngày 19/10/2026. Người thực hiện: Claude (tự chủ). Mọi sản phẩm mới nằm trong thư mục `projects/`, **không động vào** `index.html` (game Phi Thuyền có sẵn).

## 0. Hiện trạng repo

- `index.html`: game "Phi Thuyền: Update 1.4 - Kỹ Năng" (canvas, 1 file). → **Giữ nguyên, không sửa.**
- Chưa có README, chưa có công cụ học tập nào.

## 1. Nguyên tắc kỹ thuật chung (quyết định & lý do)

| Quyết định | Lý do |
|---|---|
| HTML/CSS/JS thuần, **không cần build** (không npm install, không bundler) | Mở trực tiếp bằng trình duyệt là chạy, đưa lên GitHub Pages ngay; bạn đọc và sửa code dễ. |
| Chạy được khi mở bằng `file://` (dùng `<script src>` cổ điển, dữ liệu là file `.js` thay vì `.json`) | `fetch()` và ES module bị chặn trên `file://` ở Chrome. |
| Dữ liệu cá nhân lưu `localStorage`, có nút **Xuất/Nhập JSON** | Không gửi gì ra ngoài; vẫn sao lưu được. |
| KaTeX đặt sẵn trong repo (`projects/shared/vendor/katex`) | Công thức đẹp, chạy offline, không phụ thuộc CDN. |
| Mỗi sản phẩm có `README.md` + kiểm thử tự động trong `tools/` | Yêu cầu "tự kiểm tra"; dùng lại được khi sửa sau này. |
| Số liệu/công thức có script đối chiếu (Node) | Tránh sai đáp án trong ngân hàng câu hỏi. |

## 2. Danh sách sản phẩm đề xuất

Điểm: Giá trị (1–5) cho việc học + hồ sơ; Công sức (1–5, 5 = nhiều nhất). **Ưu tiên = Giá trị² / Công sức** (bình phương giá trị vì đề bài yêu cầu chất lượng hơn số lượng).

| # | Sản phẩm | Giá trị với bạn | Công sức | GT | CS | Ưu tiên |
|---|---|---|---|---|---|---|
| P1 | **Ôn thi Vật lý 12 (dạng đề THPT mới)** — ngân hàng câu hỏi theo 4 chương CT 2018, 3 dạng câu (trắc nghiệm, Đúng/Sai, trả lời ngắn), giải thích chi tiết, sổ câu sai, lặp lại ngắt quãng (Leitner), chế độ thi thử 28 câu/50 phút chấm điểm theo thang mới | Trực tiếp tăng điểm thi; dùng hằng ngày | Lớn (engine + ~90 câu soạn kỹ + script kiểm đáp án) | 5 | 4 | **6.25** |
| P2 | **Orbit Lab** — mô phỏng quỹ đạo 2D (Kepler, vận tốc vũ trụ, chuyển quỹ đạo Hohmann, tên lửa Tsiolkovsky), có bài tập + lời giải | Đúng ngành hàng không – vũ trụ, rất hợp portfolio du học Đức | Vừa–lớn (vật lý số + UI canvas) | 5 | 3 | **8.33** |
| P3 | **Sổ tay công thức Vật lý 12** — 1 trang tra cứu, in được ra A4, có hằng số, đơn vị, "bẫy hay gặp" | Ôn nhanh trước giờ thi, in ra mang theo | Nhỏ | 4 | 2 | **8.00** |
| P4 | **Phòng thí nghiệm ảo Vật lý 12** — 3 mô phỏng: khí lí tưởng (hạt va chạm, đồ thị p–V), phân rã phóng xạ (ngẫu nhiên vs. lý thuyết), cảm ứng điện từ/máy phát xoay chiều | Hiểu bản chất các chương khó; portfolio | Vừa | 4 | 3 | **5.33** |
| P5 | **Bảng điều khiển ôn thi** — đếm ngược kỳ thi, kế hoạch tuần, Pomodoro, nhật ký giờ học, **sổ tay lỗi sai** (đọc thêm dữ liệu câu sai từ P1) | Tổ chức việc học, nhìn thấy tiến độ | Vừa | 4 | 3 | **5.33** |
| P6 | **Gói ôn Toán 12 + Tư duy V-ACT** cho cùng engine P1 — câu hỏi Toán (đạo hàm, tích phân, xác suất, Oxyz…) và câu phân tích số liệu/suy luận khoa học | Bao phủ cả THPT Toán và V-ACT | Vừa (engine có sẵn; tốn công soạn và kiểm đáp án) | 4 | 3 | **5.33** |
| P7 | **Trang hub portfolio + lộ trình du học Đức ngành hàng không** — trang chủ liên kết mọi dự án; tài liệu lộ trình (APS, Studienkolleg, tiếng Đức, trường có ngành Luft- und Raumfahrttechnik), ghi rõ chỗ "cần xác minh" | Hồ sơ trông chuyên nghiệp; định hướng rõ | Nhỏ–vừa | 3 | 2 | **4.50** |
| P8 | Review code game Phi Thuyền + đề xuất cải tiến (file riêng, không sửa game) | Học thêm về code của chính mình | Nhỏ | 2 | 1 | 4.00 |

### Thứ tự thực hiện (sau khi cân nhắc phụ thuộc)

Không làm thuần theo điểm, vì có phụ thuộc: P1 tạo ra engine + hạ tầng chung (theme, KaTeX, lưu trữ, khung kiểm thử) mà P5, P6 dùng lại.

1. **P1** Ôn thi Vật lý 12 — giá trị học tập cao nhất + dựng hạ tầng chung.
2. **P2** Orbit Lab — điểm ưu tiên cao nhất, mảnh portfolio chủ lực.
3. **P3** Sổ tay công thức — nhỏ, dùng lại nội dung đã kiểm ở P1.
4. **P4** Phòng thí nghiệm ảo.
5. **P5** Bảng điều khiển ôn thi + sổ lỗi sai.
6. **P6** Gói Toán + V-ACT.
7. **P7** Hub portfolio + lộ trình du học Đức.
8. **P8** Review game (nếu còn thời gian).

## 3. Tiêu chí "XONG" cho từng sản phẩm

**Chung cho mọi sản phẩm:** mở bằng trình duyệt chạy ngay (cả `file://` lẫn web server); không lỗi console (kiểm bằng Playwright); dùng được trên màn hình điện thoại (≥ 360 px); có README; được ghi vào PROGRESS.md.

- **P1:** ≥ 80 câu, phủ đủ 4 chương, đủ 3 dạng; mỗi câu có lời giải; mọi câu tính số được script đối chiếu lại; chế độ: luyện theo chương, ôn câu đến hạn (Leitner 5 hộp), sổ câu sai, thi thử 18 + 4 + 6 câu có đồng hồ và chấm điểm đúng thang 2025; xuất/nhập tiến độ.
- **P2:** tích phân số bảo toàn năng lượng (sai số < 0,1 % sau 10 vòng quỹ đạo, kiểm bằng test); ≥ 4 kịch bản (tròn, elip, thoát, Hohmann); máy tính Hohmann khớp số liệu tham chiếu Trái Đất → Sao Hỏa; ≥ 6 bài tập có lời giải.
- **P3:** đủ 4 chương + hằng số; in A4 gọn (CSS print); công thức trùng với P1.
- **P4:** 3 mô phỏng chạy mượt; mỗi cái có đồ thị so với lý thuyết và câu hỏi gợi mở; số liệu kiểm bằng test (VD: pV/T ≈ const, N(t) ≈ N₀·2^(−t/T)).
- **P5:** đếm ngược (ngày thi chỉnh được), kế hoạch tuần, Pomodoro, nhật ký, sổ lỗi sai, thống kê từ P1; xuất/nhập JSON.
- **P6:** ≥ 40 câu Toán + ≥ 15 câu Tư duy, đáp án được script kiểm; dùng chung engine P1.
- **P7:** hub liên kết mọi sản phẩm, có ảnh chụp/thumbnail; tài liệu lộ trình có nguồn và đánh dấu "cần xác minh".
- **P8:** file nhận xét có ví dụ cụ thể (dòng code) và đề xuất ưu tiên.

## 4. Rủi ro & cách xử lý

- **Sai kiến thức/đáp án** → script kiểm số, đọc lại từng câu, ghi "cần xác minh" khi không chắc (VD: lịch thi 2027, quy chế xét tuyển, thủ tục du học).
- **Khác biệt giữa 3 bộ SGK** (Kết nối tri thức, Cánh diều, Chân trời sáng tạo) → bám theo nội dung chung của Chương trình GDPT 2018, tránh chi tiết riêng của một bộ sách.
- **Hết token giữa chừng** → PROGRESS.md cập nhật sau từng sản phẩm, commit + push thường xuyên.
