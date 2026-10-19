# TỔNG KẾT

> Hoàn thành 19/10/2026 · nhánh `claude/intelligent-curie-jvf8gw` · **8/8 sản phẩm theo kế hoạch đã xong và đã tự kiểm tra**.
> Toàn bộ kiểm thử: `bash tools/run-all-tests.sh` → **13 bộ, 362 phép kiểm, tất cả đạt** (cả mở bằng `file://` lẫn qua web server).

## 1. Danh sách sản phẩm & cách mở

Mọi trang đều mở được bằng **nhấp đúp file `index.html`** (offline, không cần cài gì). Trang bắt đầu: **`projects/index.html`** (hub có ảnh và liên kết tới tất cả).

| # | Sản phẩm | Mở | Điểm nổi bật | Đã kiểm |
|---|---|---|---|---|
| P1 | **Ôn thi Vật lý 12** | `projects/01-on-thi-vat-ly-12/index.html` | 99 câu (4 chương, 3 dạng đề mới), lời giải + phân tích phương án nhiễu, Leitner 5 hộp, sổ câu sai, thi thử 18+4+6 câu/50 phút chấm thang 2025, xuất/nhập tiến độ | 76 đáp số tính lại độc lập + 29 kiểm thử giao diện + 671 công thức render |
| P2 | **Orbit Lab** | `projects/02-orbit-lab/index.html` | Mô phỏng quỹ đạo (Verlet, sai số năng lượng ~1e-9), Kepler II có số đo, Hohmann có thanh lệch pha, tên lửa nhiều tầng, 9 bài tập | 31 (so với giá trị tham chiếu) + 22 |
| P3 | **Sổ tay công thức Vật lý 12** | `projects/03-so-tay-cong-thuc/index.html` | 42 công thức + bẫy hay gặp, tìm không dấu, che công thức để tự kiểm tra, in PDF A4 4 trang | 16 |
| P4 | **Phòng thí nghiệm ảo** | `projects/04-phong-thi-nghiem-ao/index.html` | Khí lí tưởng từ va chạm phân tử (đo áp suất thật, Maxwell), phóng xạ ngẫu nhiên, Lenz kéo nam châm, máy phát 3D; 16 câu hỏi khám phá | 17 + 16 |
| P5 | **Bảng điều khiển ôn thi** | `projects/05-bang-dieu-khien/index.html` | Đếm ngược, kế hoạch tuần, Pomodoro tự ghi nhật ký, sổ lỗi sai có lịch ôn 1-3-7-14-30 ngày, đọc tiến độ từ P1/P6 | 16 |
| P6 | **Toán 12 & Tư duy V-ACT** | `projects/06-on-thi-toan-vact/index.html` | 50 câu Toán 12 + 24 câu V-ACT dùng chung engine P1 | 74 đáp án tính lại + 51 |
| P7 | **Hub portfolio + Lộ trình du học Đức** | `projects/index.html`, `projects/07-lo-trinh-du-hoc-duc/index.html` | Trang giới thiệu có ảnh; lộ trình APS/TestAS/Studienkolleg, 3 con đường, mốc thời gian, checklist 17 việc, nguồn chính thức | 14 (gồm kiểm mọi liên kết nội bộ) |
| P8 | **Nhận xét code game** | `projects/08-review-game/REVIEW.md` | 3 lỗi ưu tiên (2 lỗi đã tái hiện bằng trình duyệt), 7 cải thiện, code sửa mẫu; game gốc không bị sửa | `node tools/probe-game-bugs.js` |

Mỗi thư mục có `README.md` (làm gì, cách dùng, giới hạn). Toàn bộ thư mục `projects/` ~1,5 MB (KaTeX đặt sẵn ~600 KB, ảnh thu nhỏ ~280 KB).

## 2. Những gì đã được tự kiểm tra (và đã sửa nhờ kiểm tra)
- Đáp số: script tính lại **độc lập** 140 đáp số/mệnh đề (Vật lý + Toán + V-ACT) và kiểm rằng không phương án nhiễu nào trùng đáp án; mọi câu Toán/V-ACT đều được kiểm (10 câu thuần lý thuyết ghi rõ là "đã đọc lại").
- Vật lý mô phỏng: so với giá trị tham chiếu (v₁ = 7,91 km/s, GEO 42 164 km, Trái Đất→Sao Hỏa 2,94 + 2,65 km/s / 259 ngày / góc pha 44°; khí 2D thỏa pS = NkT trong ~2 %; phóng xạ 50 % sau T).
- Giao diện: Playwright bấm như người dùng, chụp ảnh, kiểm màn hình 375 px, console sạch.
- Lỗi đã bắt được và sửa trong quá trình (ghi chi tiết trong `PROGRESS.md`): lỗi cú pháp `${` làm trắng trang sổ tay; bản in bị nền đen khi máy để giao diện tối; thuộc tính `hidden` bị CSS đè; khung mô phỏng tính tỉ lệ khi canvas còn ẩn; quạt Kepler bị xóa mỗi chu kì; engine giữ lựa chọn chương của ngân hàng khác (ra 0 câu); vài lời giải/phương án nhiễu viết chưa chuẩn.

## 3. Điểm yếu còn lại (thẳng thắn)
1. **Số lượng câu hỏi còn khiêm tốn:** 99 câu Lý, 50 câu Toán, 24 câu V-ACT — đủ để luyện và thi thử nhưng một đề thi thử sẽ lặp câu sau vài lần. Toán chưa có nội dung lớp 10–11; chương sóng điện từ (Lý) còn ít câu.
2. **Thông tin cần xác minh:** cấu trúc đề THPT & V-ACT 2027, ngày thi 2027 (đang để giả định trong Bảng điều khiển), toàn bộ chi tiết du học Đức gắn nhãn "cần xác minh" (xếp loại anabin cho THPT Việt Nam, mức Sperrkonto 2027, học phí, hạn nộp, danh sách trường).
3. **Mô hình đơn giản hóa:** Orbit Lab 2D, không lực cản khí quyển; khí lí tưởng mô phỏng 2D (đã ghi rõ); Lenz dùng từ thông chuẩn hóa (định tính).
4. **Dữ liệu chỉ nằm trong trình duyệt:** đổi máy phải xuất/nhập JSON; mở bằng `file://` và qua web là hai "kho" khác nhau.
5. Bảng điều khiển dùng `prompt()` để sửa ngày thi — chạy được nhưng chưa đẹp.
6. Câu hỏi do mình soạn và tự kiểm bằng script; **nên nhờ thầy cô đọc lại** phần lời giải, đặc biệt cách diễn đạt theo bộ sách bạn đang học.

## 4. Ba việc bạn nên làm tiếp theo
1. **Dùng ngay mỗi ngày (tuần này):** mở `projects/05-bang-dieu-khien/index.html`, sửa ngày thi + kế hoạch tuần cho đúng; mỗi ngày làm 20 câu "Ôn câu đến hạn" ở P1/P6 và ghi lỗi sai vào sổ. Làm 1 đề thi thử Lý mỗi cuối tuần để theo dõi điểm. Xuất tệp sao lưu mỗi tuần.
2. **Bật GitHub Pages cho repo** (Settings → Pages → nhánh chứa `projects/`) để dùng trên điện thoại và có đường link đưa vào hồ sơ. Việc công khai là quyết định của bạn — tôi không tự làm. Trước đó, sửa 2 lỗi ưu tiên trong `REVIEW.md` của game (≈ 10 phút) để mục "Phi Thuyền" trong portfolio không còn lỗi.
3. **Xác minh lộ trình du học trong tháng này:** đọc trang APS của Đại sứ quán Đức tại Hà Nội và mục Việt Nam trên anabin, chọn con đường chính/dự phòng, **bắt đầu tiếng Đức A1 ngay** (2–4 giờ/tuần không ảnh hưởng ôn thi). Muốn portfolio mạnh hơn: mở rộng Orbit Lab (lực cản khí quyển → quỹ đạo suy giảm, hoặc bản 3D bằng Three.js) — đó là dự án đúng ngành hàng không, gắn với kỹ năng React/Three.js bạn đang học.

## 5. Bản đồ repo
```
index.html                  ← game Phi Thuyền (giữ nguyên)
README.md · PLAN.md · PROGRESS.md · SUMMARY.md
projects/
  index.html                ← hub portfolio
  shared/                   ← theme, tiện ích, engine ôn thi, KaTeX offline
  01 … 08 /                 ← 8 sản phẩm (mỗi cái có README.md)
  assets/thumbs/            ← ảnh thu nhỏ cho hub
tools/                      ← kiểm thử & kiểm đáp án (run-all-tests.sh)
```
