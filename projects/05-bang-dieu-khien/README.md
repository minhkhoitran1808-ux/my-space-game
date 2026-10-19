# P5 · Bảng điều khiển ôn thi

Trang "trung tâm chỉ huy" cho việc học hằng ngày — chạy offline, dữ liệu chỉ nằm trong trình duyệt.

| Phần | Chức năng |
|---|---|
| **Tổng quan** | Đếm ngược các kỳ thi (sửa/thêm được), việc hôm nay, số giờ học tuần này, biểu đồ 14 ngày theo môn, số lỗi sai cần ôn, **thống kê tự đọc từ các bộ ôn thi** (P1, P6): câu đã làm, tỉ lệ đúng, câu đến hạn, sổ sai, điểm thi thử gần nhất. |
| **Kế hoạch tuần** | Mẫu kế hoạch lặp lại theo thứ (có sẵn kế hoạch mẫu, sửa thoải mái), đánh dấu hoàn thành theo từng ngày, xem tuần trước/sau, thêm môn học. |
| **Pomodoro & nhật ký** | Đồng hồ học/nghỉ (mặc định 25/5), có chuông; hết phiên tự ghi vào nhật ký; vẫn chạy đúng khi tải lại trang. Thêm giờ học thủ công, thống kê theo môn. |
| **Sổ lỗi sai** | Ghi *sai thế nào → cách đúng → mẹo nhận biết*, phân loại lỗi (khái niệm, công thức, tính toán, đọc đề, đơn vị…). Lịch ôn lại 1 → 3 → 7 → 14 → 30 ngày theo kiểu "nhớ rồi / vẫn quên"; biểu đồ "mình hay sai kiểu gì". |
| **Dữ liệu** | Xuất/nhập một tệp JSON gồm cả tiến độ các bộ ôn thi; quản lý ngày thi; đặt lại. |

## Cách dùng
Mở `index.html`. Lần đầu sẽ thấy kế hoạch và ngày thi **mẫu** — sửa cho đúng với bạn.

**Cần xác minh:** ngày thi tốt nghiệp THPT 2027 (đặt tạm 10/06/2027) và V-ACT 2027 đợt 1 (đặt tạm 04/04/2027) là **giả định**; hãy sửa khi Bộ GD&ĐT / ĐHQG-HCM công bố lịch chính thức.

Lưu ý: thống kê từ các bộ ôn thi chỉ hiện khi mở các trang **cùng một trình duyệt và cùng cách mở** (cùng `file://` hoặc cùng một địa chỉ web), vì localStorage tách theo nguồn.

## Kiểm tra
`node tools/test-dash.js [thư-mục-ảnh]` — 16 phép kiểm: đếm ngược đúng số ngày, đọc thống kê ôn thi, thêm/xóa việc, nhật ký, Pomodoro tự ghi khi hết giờ, lịch ôn lỗi sai, xuất tệp, giao diện điện thoại, console sạch.
