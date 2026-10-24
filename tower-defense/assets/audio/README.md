# Âm thanh

Mọi file `.wav` ở đây được TỔNG HỢP bằng code (không ghi âm, không bản quyền) bởi
`tools/gen_sfx.py`. Chạy lại để tạo lại: `python3 tools/gen_sfx.py` (cần numpy).

Muốn thay bằng âm thanh của bạn: thả file (`.ogg`, `.wav` hoặc `.mp3`) đúng tên dưới đây
(xoá file `.wav` cùng tên nếu dùng đuôi khác). Thiếu file nào thì sự kiện đó im lặng, không báo lỗi.

| Tên file (không đuôi) | Khi nào phát |
|---|---|
| `shoot_archer` | Cung thủ bắn |
| `shoot_cannon` | Pháo bắn |
| `shoot_frost` | Tháp Băng bắn |
| `shoot_mage` | Tháp Phép bắn |
| `explosion` | Đạn nổ lan chạm đất |
| `enemy_death` | Địch chết |
| `base_hit` | Địch chạm nhà chính |
| `build` | Xây tháp |
| `upgrade` | Nâng cấp tháp |
| `sell` | Bán tháp |
| `wave_start` | Bắt đầu wave |
| `wave_complete` | Hết wave |
| `victory` | Thắng màn |
| `defeat` | Thua màn |
| `ability_meteor` | Dùng kỹ năng Thiên thạch |
| `ability_freeze` | Dùng kỹ năng Băng giá |
| `achievement` | Mở khoá thành tựu |

Ví dụ: `assets/audio/enemy_death.wav`. Danh sách này cũng nằm trong `AudioManager.SOUND_NAMES`.
