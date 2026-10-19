# P8 · Nhận xét code game Phi Thuyền

Đọc `REVIEW.md`: 3 lỗi ưu tiên (game phụ thuộc tần số màn hình, quái đã chết vẫn trừ máu, thiếu `touchcancel`/đặt lại trạng thái cảm ứng), 7 điểm cải thiện, đề xuất cấu trúc, kèm đoạn code sửa mẫu và số dòng tham chiếu. Game gốc **không bị sửa**.

Tự kiểm chứng: `node tools/probe-game-bugs.js` (chạy game trong Chromium headless và in kết quả tái hiện từng lỗi).
