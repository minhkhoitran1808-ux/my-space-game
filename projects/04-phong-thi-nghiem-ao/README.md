# P4 · Phòng thí nghiệm ảo Vật lý 12

Bốn thí nghiệm tương tác cho các chương khó "nhìn thấy" nhất. Mỗi thí nghiệm có số đo, đồ thị so với lý thuyết và **4 câu hỏi khám phá có đáp án**.

| Thí nghiệm | Chương | Bạn làm được gì |
|---|---|---|
| **Khí lí tưởng** | II | 50–300 phân tử va chạm đàn hồi thật trong hộp có pit-tông (kéo được). Áp suất được **đo** từ xung lượng lên thành. Ghi điểm đo như làm thí nghiệm, vẽ p–S, p–1/S, p–T so với lý thuyết. Biểu đồ phân bố tốc độ so với Maxwell. Tắt bộ ổn nhiệt rồi nén nhanh để thấy khí nóng lên (định luật I NĐLH). |
| **Phân rã phóng xạ** | IV | Lưới 100–10 000 hạt nhân phân rã ngẫu nhiên; đường N(t) so với $N_0 2^{-t/T}$; chọn chất thật (I-131, Rn-222, Po-210, Co-60, C-14). "Đo chu kì bán rã 20 lần" cho thấy sai số thống kê giảm khi N₀ tăng. |
| **Định luật Lenz** | III | Kéo nam châm lại gần/ra xa vòng dây: điện kế, chiều dòng điện (nhìn từ bên trái), cực N/S cảm ứng của vòng dây, câu giải thích tự cập nhật ("lại gần thì đẩy, ra xa thì hút"), đồ thị Φ và e = −N·dΦ/dt. |
| **Máy phát điện xoay chiều** | III | Khung dây quay 3D trong từ trường; chỉnh N, B, S, n, R; dao động ký Φ(t) và e(t) lệch pha π/2; bảng E₀, E, I, P. Nút n = 50 vòng/s (chiếu chậm). |

## Cách mở
Mở `index.html` (hoặc `index.html#decay`, `#lenz`, `#gen`).

## Kiểm tra
- `node tools/test-labs.js` (17 phép kiểm lõi): khí 2D thỏa $pS = NkT$ (lệch ~2 % do kích thước phân tử), Boyle, p ∝ T, va chạm bảo toàn năng lượng tới 1e-16, phân bố tiến về Maxwell, nén đoạn nhiệt làm nóng; phân rã còn 50 % sau T và 12,5 % sau 3T; e = −dΦ/dt; E hiệu dụng khớp câu tu-s4 của P1.
- `node tools/test-labs-ui.js [thư-mục-ảnh]` (16 phép kiểm giao diện, gồm kiểm chiều dòng cảm ứng theo Lenz).

## Giới hạn
- Khí mô phỏng trong **2 chiều** (động năng trung bình = kT thay vì 3/2·kT; "thể tích" là diện tích) — đã ghi rõ trên trang. Đơn vị mô phỏng tùy ý.
- Từ thông nam châm dùng mô hình lưỡng cực trên trục, độ lớn đã chuẩn hóa (định tính).
- Máy phát bỏ qua điện trở trong và độ tự cảm của khung.
