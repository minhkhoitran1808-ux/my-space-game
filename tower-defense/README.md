# Tower Defense 2D (Godot 4.7)

Game Tower Defense 2D viết bằng GDScript. Chưa cần asset nào: mọi thứ được vẽ tạm bằng code,
mở project và bấm Play là chơi được ngay.

## Chạy game

1. Mở Godot 4.7 → **Import** → chọn `tower-defense/project.godot`.
2. Bấm **Play** (F5): game mở vào menu chính → **Chơi** → chọn màn.
   (Muốn vào thẳng trận màn 1 để thử nhanh: mở `scenes/main/Main.tscn` rồi bấm **F6**.)

## Điều khiển

| Phím / chuột | Tác dụng |
|---|---|
| `1`–`4` hoặc nút ở thanh dưới | Chọn loại tháp để xây (rê chuột lên nút để xem chỉ số) |
| Chuột trái | Đặt tháp (bóng xanh = đặt được, đỏ = không) / chọn tháp đã xây |
| Chuột phải / `Esc` | Huỷ xây / bỏ chọn tháp |
| `U` / `X` / `T` | Nâng cấp / bán / đổi cách chọn mục tiêu của tháp đang chọn |
| `Space` | Bắt đầu wave, hoặc **gọi sớm** wave sau (thưởng thêm vàng) |
| `F` | Tốc độ x1 / x2 / x3 |
| `P` (hoặc `Esc` khi không chọn gì) | Tạm dừng |

## Nội dung

**3 màn chơi**, màn sau mở khi qua màn trước. Qua màn được 1–3 sao theo số máu còn lại
(≥ 80% = 3 sao, ≥ 40% = 2 sao). Tiến độ lưu ở `user://save.cfg`.

| Màn | Bản đồ | Wave | Vàng đầu |
|---|---|---|---|
| Đồng cỏ | 1 làn quanh co | 10 | 200 |
| Ngã ba sông | 2 làn nhập làm một | 10 | 260 |
| Đường rắn | 1 làn rất dài, 2 Boss | 12 | 300 |

**4 loại tháp**, mỗi loại 3 cấp:

| Tháp | Giá | Kiểu bắn | Sát thương | Đặc điểm |
|---|---|---|---|---|
| Cung thủ | 50 | Đạn nhanh | Vật lý | Rẻ, bắn nhanh |
| Pháo | 90 | Đạn chậm | Vật lý | **Nổ lan**, khắc chế Bầy chuột |
| Băng | 70 | Tia | Phép | **Làm chậm** các địch quanh mục tiêu |
| Phép | 120 | Tia | Phép | Sát thương cao + **thiêu đốt**, khắc chế Bọc thép |

**5 loại địch:**

| Địch | Hình | Đặc điểm |
|---|---|---|
| Lính thường | Tròn đỏ | Cân bằng |
| Trinh sát | Tam giác vàng | Rất nhanh, kháng phép 50% |
| Bọc thép | Vuông xám | Giáp 60%, trừ 2 máu nhà |
| Bầy chuột | Tròn tím nhỏ | Yếu nhưng rất đông |
| Chúa quỷ (Boss) | Kim cương đỏ sẫm | Rất trâu, kháng chậm 50%, trừ 10 máu, chết thì **sinh 8 Bầy chuột** |

## Kiến trúc

```
tower-defense/
├── project.godot               # main scene = menu chính; autoload: GameManager, AudioManager, SaveManager
├── assets/audio/               # thả file âm thanh vào đây (xem README trong thư mục)
├── data/waves/level_XX.json    # wave của từng màn
├── resources/
│   ├── effects/                # StatusEffectData: làm chậm, thiêu đốt (3 cấp)
│   ├── enemies/                # EnemyData: 5 loại địch
│   ├── levels/                 # LevelData từng màn + catalog.tres (thứ tự màn)
│   ├── towers/                 # TowerData: 4 tháp × 3 cấp (chuỗi next_level)
│   └── ui/theme.tres           # theme UI dùng chung
├── scenes/
│   ├── main/Main.tscn          # trận đấu (nạp bản đồ theo màn)
│   ├── maps/Map01..03.tscn     # bản đồ: chỉ chứa các Path2D (làn đường)
│   ├── menus/                  # MainMenu, LevelSelect
│   ├── enemies/, towers/, projectiles/
│   └── ui/                     # HUD, TowerInfoPanel, PauseMenu
├── scripts/
│   ├── autoload/               # GameManager, AudioManager, SaveManager
│   ├── combat/                 # DamageInfo, Combat, Projectile, StatusEffectHandler
│   ├── managers/               # WaveManager, BuildManager, SelectionManager
│   ├── fx/FxManager.gd         # số sát thương, vụ nổ, rung màn hình
│   ├── main/                   # Main, Ground, GameMap
│   ├── menus/, ui/, resources/, enemies/, towers/, core/
└── tests/smoke_test.tscn       # test tự động
```

### Cây node của trận (`Main.tscn`)

```
Main                  ← Main.gd: nạp màn + nối signal giữa các hệ thống
├── Camera2D          ← dùng để rung màn hình
├── Ground            ← vẽ cỏ, đường đi (từ các Path2D của bản đồ), nhà chính
├── Towers            ← tháp đã xây
├── Map               ← bản đồ được nạp vào đây; địch (PathFollow2D) là con của các Path2D
├── Projectiles       ← đạn đang bay
├── FxManager         ← hiệu ứng (chỉ lắng nghe signal)
├── BuildManager      ← xây / nâng cấp / bán, ô nào có tháp
├── SelectionManager  ← click chọn tháp, phím U/X/T
├── WaveManager       ← đọc wave, spawn địch, đếm địch theo từng wave
└── UI/HUD            ← thanh trên/dưới, bảng thông tin tháp, menu tạm dừng, bảng kết thúc
```

### Nguyên tắc

- **Dữ liệu thay vì code:** tháp, địch, hiệu ứng, màn chơi đều là `.tres`; wave là JSON.
  Thêm nội dung hầu như không cần sửa code.
- **Hệ thống không gọi nhau trực tiếp:** chúng phát signal, `Main.gd` nối dây.
  `GameManager` là nơi duy nhất giữ vàng / máu / trạng thái và là nơi duy nhất đổi scene.
- **Sát thương đi một đường:** mọi cú đánh tạo `DamageInfo` → `Combat.apply_hit()` →
  `Enemy.take_damage()` (tính giáp / kháng phép, gắn hiệu ứng, báo thống kê cho tháp).

## Mở rộng

**Thêm loại địch:** nhân bản một file trong `resources/enemies/`, đổi `id` (duy nhất) và chỉ số.
WaveManager tự quét thư mục, trong file wave chỉ cần ghi `"enemy": "<id>"`.

**Thêm loại tháp:** nhân bản bộ 3 file cấp của một tháp trong `resources/towers/`, sửa chỉ số
(trường `next_level` nối cấp 1 → 2 → 3, `cost` của cấp 2/3 là giá nâng cấp), rồi thêm file cấp 1
vào *Available Towers* của node `BuildManager` trong `Main.tscn`.

**Thêm màn chơi:**
1. Tạo bản đồ: nhân bản `scenes/maps/Map01.tscn`, kéo các điểm của Path2D trong node `Paths`
   (thêm Path2D để có nhiều làn; mọi làn nên kết thúc ở cùng một điểm = nhà chính).
2. Tạo file wave `data/waves/level_04.json`.
3. Tạo `LevelData` trong `resources/levels/` trỏ tới bản đồ và file wave.
4. Thêm nó vào mảng `levels` của `resources/levels/catalog.tres`.
5. Chạy smoke test: bot sẽ tự chơi màn mới và báo thắng / thua.

**Cấu trúc file wave:**

```json
{ "reward_bonus": 30, "groups": [
    { "enemy": "basic", "count": 8, "interval": 0.7, "health_multiplier": 1.4 },
    { "enemy": "fast", "count": 6, "interval": 0.4, "delay": 2.0, "path": 1 }
] }
```

| Trường | Ý nghĩa |
|---|---|
| `reward_bonus` | Vàng thưởng khi hết wave |
| `enemy` | `id` của loại địch |
| `count`, `interval` | Số địch và số giây giữa hai con |
| `delay` | Giây chờ trước con đầu tiên của nhóm |
| `path` | Làn đường (0, 1...). Bỏ trống = chia đều các làn |
| `health_multiplier`, `speed_multiplier` | Hệ số nhân máu / tốc độ |

Lỗi trong file wave (sai id, sai số làn...) được báo rõ trong cửa sổ Output.

**Âm thanh:** thả file `.ogg` / `.wav` / `.mp3` đúng tên vào `assets/audio/`
(danh sách tên trong `assets/audio/README.md`). Không có file thì game im lặng, không lỗi.

## Test tự động

```
godot --headless --path tower-defense --fixed-fps 60 res://tests/smoke_test.tscn
```

Chạy khoảng 25 giây. Gồm:
- Kiểm tra từng hệ thống: kháng sát thương, hiệu ứng, Boss sinh con, đặt / nâng cấp / bán / chọn
  tháp bằng chuột và phím, tốc độ, tạm dừng, gọi wave sớm, khoá / mở màn, sao.
- Với **mỗi màn**: một bot tự chọn ô có độ phủ đường đi tốt nhất phải **thắng**, và không xây
  tháp thì phải **thua**. Bot hiện thắng cả 3 màn với 2 sao (còn 12 / 10 / 8 máu); 3 sao là thử thách.

Exit code 0 = đạt. Test dùng file save riêng nên không ảnh hưởng tiến độ thật.
