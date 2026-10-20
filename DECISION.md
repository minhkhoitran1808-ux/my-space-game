# DECISION.md — Chọn ý tưởng

_Ngày: 20/10/2026. Dựa trên RESEARCH.md._

## 1. Cách chấm điểm

Thang 1–5 (5 = tốt nhất cho bạn). Trọng số theo yêu cầu:

| Tiêu chí | Trọng số | Cách hiểu |
|---|---|---|
| Rủi ro thấp | 40% | Trung bình 3 điểm con: **TC** = không mất tiền, **PL** = không rắc rối pháp lý/bản quyền, **MR** = không phụ thuộc may rủi (có lý do để tin sẽ có người mua, cạnh tranh miễn phí không quá áp đảo) |
| Nhu cầu có bằng chứng | 25% | Có nguồn cho thấy nỗi đau thật **và** có người đã trả tiền cho thứ tương tự |
| Công sức vừa 4–8h/tuần | 20% | Duy trì ít, không phải cập nhật dữ liệu liên tục |
| Chi phí gần 0 | 15% | Làm và bán được bằng công cụ miễn phí |

Tổng = 0,40×Rủi ro + 0,25×Nhu cầu + 0,20×Công sức + 0,15×Chi phí.

## 2. Bảng điểm

| # | Ý tưởng | TC | PL | MR | **Rủi ro** | Nhu cầu | Công sức | Chi phí | **Tổng** |
|---|---|---|---|---|---|---|---|---|---|
| CH1 | Công cụ tính tiền trọ "đúng luật" cho chủ trọ | 5 | 4 | 3 | **4,00** | 4 | 4 | 5 | **4,15** |
| CH4 | Bảng tài chính 6 chiếc lọ | 5 | 5 | 2 | 4,00 | 2 | 5 | 5 | 3,85 |
| CH8 | Gợi ý nhận xét học bạ TT27 | 5 | 4 | 2 | 3,67 | 3 | 4 | 5 | 3,77 |
| CH5 | Kế hoạch cưới + sổ mừng | 5 | 5 | 2 | 4,00 | 2 | 4 | 5 | 3,65 |
| CH10 | Template Notion tiếng Việt | 5 | 5 | 2 | 4,00 | 2 | 4 | 5 | 3,65 |
| CH2 | Tính giá & lãi thật trên sàn | 5 | 4 | 2 | 3,67 | 3 | 3 | 5 | 3,57 |
| CH6 | Chấm công F&B | 5 | 3 | 2 | 3,33 | 2 | 4 | 5 | 3,38 |
| CH11 | Bộ prompt AI | 5 | 4 | 1 | 3,33 | 2 | 4 | 5 | 3,38 |
| CH9 | Phiếu bài tập mầm non | 5 | 4 | 2 | 3,67 | 3 | 2 | 5 | 3,37 |
| CH12 | Ebook thuế bán online | 5 | 1 | 3 | 3,00 | 4 | 2 | 5 | 3,35 |
| CH3 | Sổ doanh thu S1a-HKD | 5 | 2 | 2 | 3,00 | 3 | 3 | 5 | 3,30 |
| CH7 | Template Canva spa/quán | 5 | 3 | 2 | 3,33 | 3 | 2 | 5 | 3,23 |

Điểm là đánh giá chủ quan có căn cứ (xem RESEARCH.md), không phải số đo.

## 3. Ý tưởng thắng: CH1 — "Sổ Trọ Minh Bạch" (tên tạm)

**Một câu:** Công cụ chạy trên trình duyệt (kèm bản Excel) giúp chủ trọ nhỏ nhập chỉ số công tơ mỗi tháng → tự chia tiền điện **không vượt hóa đơn EVN**, tính nước và phí dịch vụ, in/gửi phiếu thu từng phòng có mã QR chuyển khoản, theo dõi ai còn nợ, và cộng doanh thu cả năm để biết số liệu khi thông báo doanh thu.

**Vì sao thắng:**
1. **Nỗi đau mới, có mức phạt cụ thể:** Nghị định 133/2026 (từ 25/5/2026) phạt 20–30 triệu nếu thu điện cao hơn quy định. Chủ trọ có lý do rõ ràng để làm đúng, và báo lớn đưa tin dày.
2. **Có bằng chứng trả tiền:** đã có phần mềm thu 60.000đ/tháng cho 10 phòng (Khutro). Bán một lần ~99.000–149.000đ là rẻ hơn rõ rệt (ước lượng giá, cần thử thị trường).
3. **Rủi ro pháp lý thấp nếu thiết kế đúng:** công cụ không "tư vấn luật", chỉ **chia lại đúng số tiền trên hóa đơn điện** theo chỉ số từng phòng, rồi cảnh báo khi đơn giá vượt mức trần do người dùng xác nhận. Có ghi chú "tham khảo, đối chiếu văn bản gốc".
4. **Ít phải chăm sóc:** dữ liệu nằm trên máy người dùng (không máy chủ, không tài khoản, không thu thập dữ liệu cá nhân). Giá điện người dùng tự sửa được, nên không phải cập nhật hằng tuần.
5. **Chi phí 0đ:** web tĩnh (GitHub Pages miễn phí), file Excel, nhận tiền bằng chuyển khoản.

**Điểm yếu cần nói thẳng:**
- LOZIDO miễn phí và được đánh giá tốt; mình phải thắng bằng **sự đơn giản + đúng luật điện + mua một lần, không tài khoản**.
- Chủ trọ nhiều người lớn tuổi, ít mua hàng số online → kênh bán chính phải là nhóm Facebook chủ trọ/môi giới và nội dung "cách tính tiền điện đúng luật" (miễn phí) để kéo người.
- File bán ra có thể bị chia sẻ lậu (không có máy chủ khóa bản quyền). Chấp nhận vì giá thấp.

**Phạm vi MVP đề xuất (Giai đoạn 3):**
1. **Web app 1 file HTML, chạy offline**: danh sách phòng; nhập chỉ số điện/nước tháng; nhập tổng hóa đơn EVN → chia tiền điện theo tỷ lệ kWh (tổng thu ≤ hóa đơn); chế độ "đơn giá cố định" có cảnh báo khi vượt trần/vượt hóa đơn; phí dịch vụ; phiếu thu in được kèm VietQR; đánh dấu đã thu/còn nợ; tổng hợp doanh thu năm; sao lưu/khôi phục dữ liệu bằng file.
2. **Bản miễn phí** giới hạn 3 phòng để dùng thử; **bản đầy đủ** không giới hạn (bán).
3. **File Excel/Google Sheets** tương đương (cho người quen Excel).
4. **Hướng dẫn sử dụng** + **trang "Tính tiền điện trọ đúng luật"** miễn phí làm nội dung kéo khách.

## 4. Hai phương án dự phòng

- **Dự phòng 1 — CH4: Bảng tài chính gia đình "6 chiếc lọ" (Google Sheets).** Rủi ro pháp lý gần 0, làm nhanh (5–8 giờ), gần như không cần duy trì. Điểm yếu: bão hòa, đồ miễn phí tốt (MISA Sổ thu chi) → doanh số phụ thuộc nhiều vào khả năng làm nội dung.
- **Dự phòng 2 — CH8: Bộ gợi ý lời nhận xét học bạ tiểu học theo Thông tư 27.** Có bằng chứng giáo viên trả tiền tải tài liệu (Hoatieu Pro từ 99.000đ), nội dung tự viết được. Điểm yếu: theo mùa (cuối kỳ I, cuối năm), cạnh tranh miễn phí nhiều.

Nếu CH1 không có đơn nào sau 4 tuần chạy nội dung, nên chuyển sang dự phòng 1 (ít công nhất).

## 5. CẦN BẠN DUYỆT

Mình dừng ở đây theo yêu cầu. Bạn trả lời một trong các lựa chọn:
- **"Duyệt CH1"** → mình xây MVP như mục 3.
- **"Chọn dự phòng 1/2"** → mình chuyển hướng.
- Hoặc góp ý thay đổi phạm vi.
