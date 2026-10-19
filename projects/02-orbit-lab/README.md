# P2 · Orbit Lab — phòng thí nghiệm cơ học quỹ đạo

Mô phỏng quỹ đạo chạy trên trình duyệt, gắn với kiến thức Vật lý 10–12 (hấp dẫn, chuyển động tròn, bảo toàn năng lượng và mômen động lượng) và là "cửa ngõ" sang ngành **kỹ thuật hàng không – vũ trụ**.

## Bốn phần

| Phần | Làm được gì |
|---|---|
| **Mô phỏng quỹ đạo** | Phóng tàu từ độ cao/vận tốc/góc bay tùy ý quanh Trái Đất, Mặt Trăng, Sao Hỏa. 8 kịch bản mẫu (ISS, elip, địa tĩnh, vận tốc thoát, hypebol, rơi xuống, đạn đạo…). Đốt động cơ tăng tốc/hãm tức thời. Hiện quỹ đạo dự đoán, cận/viễn điểm, vectơ vận tốc, **định luật II Kepler** (12 hình quạt cùng Δt có diện tích bằng nhau, hiện số đo). Bảng số liệu: e, a, T, cơ năng riêng, **sai số năng lượng của tích phân số**. Kéo để di chuyển, cuộn/chụm 2 ngón để phóng to. |
| **Chuyển quỹ đạo Hohmann** | Giữa các hành tinh (Thủy → Thổ) hoặc quanh Trái Đất (vd. LEO → GEO). Bảng Δv₁, Δv₂, thời gian bay, góc pha, chu kì giao hội, Δv thoát từ quỹ đạo đỗ (hiệu ứng Oberth). Hoạt hình có **thanh lệch pha**: phóng sai thời điểm → thấy tàu trượt mục tiêu bao nhiêu triệu km. |
| **Tên lửa** | Phương trình Tsiolkovsky cho tên lửa 1–4 tầng: Δv từng tầng, biểu đồ Δv tích lũy so với ngưỡng lên quỹ đạo thấp, so sánh với phương án 1 tầng để thấy lợi ích của chia tầng. |
| **Bài tập** | 9 bài có gợi ý + lời giải từng bước (v₁, chu kì ISS, quỹ đạo địa tĩnh & ngày sao, v₂ = √2·v₁, vis-viva, Hohmann LEO→GEO, Trái Đất→Sao Hỏa, vì sao cần nhiều tầng, Kepler III). Số liệu trong lời giải được tính trực tiếp từ cùng lõi vật lý; mỗi bài có nút **Thử trong mô phỏng**. |

## Cách mở
Mở `index.html` bằng trình duyệt (chạy offline), hoặc chạy `npx http-server -c-1` ở thư mục gốc repo rồi vào `/projects/02-orbit-lab/`. Có thể mở thẳng một phần bằng `#hohmann`, `#rocket`, `#exercises`.

## Vật lý & độ chính xác
- `orbit.js` (không phụ thuộc giao diện): bài toán hai vật 2D, tích phân **velocity-Verlet** với bước thời gian thích nghi $\Delta t = 0{,}002\sqrt{r^3/GM}$; công thức giải tích (v₁, v₂, Kepler III, vis-viva, phần tử quỹ đạo từ trạng thái, phương trình Kepler, Hohmann, Tsiolkovsky).
- Kiểm thử `node tools/test-orbit.js` (31 phép kiểm, đều đạt), so với giá trị tham chiếu quen thuộc:
  v₁ = 7,91 km/s, v₂ = 11,19 km/s, chu kì ở 400 km ≈ 92,4 phút, bán kính GEO = 42 164 km, Trái Đất→Sao Hỏa Δv ≈ 2,94 + 2,65 km/s trong ≈ 259 ngày, góc pha ≈ 44°, chu kì giao hội ≈ 780 ngày, LEO 300 km → GEO tổng Δv ≈ 3,89 km/s.
  Độ chính xác số: sai lệch năng lượng ~1e-9 sau 10 vòng elip e = 0,69; mômen động lượng bảo toàn tới ~1e-14; định luật II Kepler kiểm được tới < 0,1 %.
- Kiểm thử giao diện `node tools/test-orbit-ui.js [thư-mục-ảnh]` (22 phép kiểm: các kịch bản, va chạm, đốt động cơ, Kepler II, Hohmann tới đích/trượt, tên lửa, bài tập, màn hình điện thoại, console sạch).

## Giới hạn (cố ý đơn giản hóa)
- Không có khí quyển (bỏ qua lực cản), vật trung tâm đứng yên, chỉ 2 chiều, không nhiễu loạn từ vật thứ ba.
- Hohmann: quỹ đạo hành tinh coi là tròn, đồng phẳng → số liệu sứ mệnh thật lệch vài phần trăm.
- **Cần xác minh:** con số ~9,4 km/s để lên quỹ đạo thấp là giá trị thường dẫn (9,3–10 km/s tùy tên lửa); các tên lửa mẫu là số liệu minh họa, không phải thông số thật.

## Ý tưởng mở rộng (nếu muốn phát triển tiếp làm portfolio)
Thêm lực cản khí quyển theo mô hình mật độ hàm mũ (quỹ đạo suy giảm), trợ lực hấp dẫn (gravity assist), chế độ 3D bằng Three.js, hoặc xuất dữ liệu quỹ đạo ra CSV để vẽ đồ thị.
