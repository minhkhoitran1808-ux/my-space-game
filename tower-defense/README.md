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
| `Q` | Kỹ năng **Thiên thạch**: chuột trái chọn vùng (chuột phải / Esc để huỷ) |
| `E` | Kỹ năng **Băng giá**: làm chậm 90% toàn bộ địch trong 3 giây |
| `Space` | Bắt đầu wave, hoặc **gọi sớm** wave sau (thưởng thêm vàng) |
| `F` | Tốc độ x1 / x2 / x3 |
| `P` (hoặc `Esc` khi không chọn gì) | Tạm dừng (trong menu có Cài đặt) |

## Nội dung

**3 màn chơi**, màn sau mở khi qua màn trước. Qua màn được 1–3 sao theo số máu còn lại
(≥ 80% = 3 sao, ≥ 40% = 2 sao). Tiến độ lưu ở `user://save.cfg`.

| Màn | Bản đồ | Wave | Vàng đầu |
|---|---|---|---|
| Đồng cỏ | 1 làn quanh co | 10 | 200 |
| Ngã ba sông | 2 làn nhập làm một | 10 | 260 |
| Đường rắn | 1 làn rất dài, 2 Boss | 12 | 300 |

**Hướng dẫn chơi lần đầu:** vào màn 1 lần đầu sẽ có hướng dẫn từng bước (xây tháp → gọi wave →
chọn tháp → nâng cấp → dùng kỹ năng), có nút "Bỏ qua". Xem lại được trong Cài đặt.

**Cài đặt** (menu chính hoặc menu tạm dừng): âm lượng, bật/tắt số sát thương, rung màn hình,
toàn màn hình. Lưu cùng tiến độ trong `user://save.cfg` ("Xoá tiến độ" không xoá cài đặt).

**Chế độ vô tận:** qua một màn sẽ mở chế độ vô tận của màn đó (nút ở màn chọn màn).
Wave được sinh tự động và mạnh dần, cứ 10 wave có Boss; kỷ lục wave cao nhất được lưu lại.

**2 kỹ năng chủ động** (có thời gian hồi):

| Kỹ năng | Phím | Hồi | Tác dụng |
|---|---|---|---|
| Thiên thạch | Q | 35s | Chọn vùng: 120 sát thương chuẩn (bỏ qua giáp) + thiêu đốt |
| Băng giá | E | 50s | Làm chậm 90% toàn bộ địch trong 3 giây |

**4 loại tháp**, mỗi loại 3 cấp:

| Tháp | Giá | Kiểu bắn | Sát thương | Đặc điểm |
|---|---|---|---|---|
| Cung thủ | 50 | Đạn nhanh | Vật lý | Rẻ, bắn nhanh |
| Pháo | 90 | Đạn chậm | Vật lý | **Nổ lan**, khắc chế Bầy chuột. **Không bắn được địch bay** |
| Băng | 70 | Tia | Phép | **Làm chậm** các địch quanh mục tiêu |
| Phép | 120 | Tia | Phép | Sát thương cao + **thiêu đốt**, khắc chế Bọc thép |

**6 loại địch:**

| Địch | Hình | Đặc điểm |
|---|---|---|
| Lính thường | Tròn đỏ | Cân bằng |
| Trinh sát | Tam giác vàng | Rất nhanh, kháng phép 50% |
| Bọc thép | Vuông xám | Giáp 60%, trừ 2 máu nhà |
| Bầy chuột | Tròn tím nhỏ | Yếu nhưng rất đông |
| Dơi lửa | Có cánh, cam | **Bay** thẳng tới nhà chính, bỏ qua đường đi; Pháo không bắn được |
| Chúa quỷ (Boss) | Kim cương đỏ sẫm | Rất trâu, kháng chậm 50%, trừ 10 máu, chết thì **sinh 8 Bầy chuột** |

## Giao diện trong trận (HUD)

- Scene: `scenes/ui/HUD.tscn`, script `scripts/ui/HUD.gd`; cập nhật hoàn toàn theo signal của
  `GameManager` (vàng, máu, wave, tốc độ), không cập nhật mỗi frame.
- **Theme riêng của HUD:** `resources/ui/hud_theme.tres` (chỉ gắn vào HUD nên không ảnh hưởng menu).
  Bảng màu theo token: nền `#0B101D`, panel `#182238`, vàng `#FFC72C`, máu `#E63946`, wave `#4EA8DE`,
  thành công `#38B000`, khoá `#5C677D`, viền focus `#00F5D4`.
  - Biến thể nút: `Button` (mặc định), `PrimaryButton` (xanh), `GoldButton` (gọi sớm), `RetryButton` (cam),
    `DockButton` (thanh dưới). Mỗi biến thể có đủ trạng thái Normal / Hover / Pressed / Disabled (+ Focus).
  - Biến thể panel / chữ: `HudBar`, `StatChip`, `ModalPanel`, `StatValue`, `StatCaption`, `MutedLabel`, `HudTitle`, `LivesBar`.
  - Sửa nhanh trong Godot (mở file theme), hoặc đổi bảng `TOKENS` trong `tools/gen_hud_theme.py`
    rồi chạy `python3 tools/gen_hud_theme.py` để sinh lại toàn bộ.
- Icon (tim, đồng xu, wave, cúp, đầu lâu...) vẽ bằng code: `scripts/ui/HudIcon.gd`.
- Hiệu ứng dùng chung (hover phóng to, lún khi nhấn, rung khi bấm nút khoá, nảy số, nhấp nháy): `scripts/ui/UiFx.gd`.
- Font **Be Vietnam Pro** (SemiBold / ExtraBold) trong `assets/fonts/`, giấy phép SIL Open Font License
  (`assets/fonts/OFL.txt`) – được phép đóng gói kèm game.

## Tầm bắn và ghost tháp

- `scripts/fx/RangeIndicator.gd`: một vòng tầm bắn (fill alpha 0.15 + viền 2px + halo tối 1px), 6 trạng thái.
  Mỗi trạng thái khác nhau cả màu lẫn **hình dạng** (đọc được với người mù màu, kể cả ảnh xám):

  | Trạng thái | Màu | Viền | Khi nào |
  |---|---|---|---|
  | VALID | `#56B4E9` | liền | ô đặt được |
  | INVALID | `#D55E00` | **đứt nét** + ✕ trên ghost + dòng lý do | trên đường, trùng tháp, thiếu vàng, ngoài bản đồ |
  | SELECTED | trắng | liền, nhịp sáng rất nhẹ | click vào tháp đã xây |
  | UPGRADE_PREVIEW | trắng | đứt nét, không fill | rê chuột lên nút Nâng cấp |
  | NEIGHBOR | trắng mờ 1px | liền | tầm bắn các tháp khác khi đang đặt |

  Fill nằm dưới địch, viền nằm trên địch (node con `z_index = 1`). Thông số gom trong `RangeIndicator.STYLE`.
- `scripts/fx/TowerRangeDisplay.gd`: ghost (hình tháp thật, alpha 0.6, pha 35% màu trạng thái, khung ô, bóng đổ,
  nhãn giá) + các vòng + phản hồi. Chỉ nghe signal và gọi lại `BuildManager.get_placement_error()`, đúng hàm
  lệnh đặt thật dùng, nên ghost và kết quả đặt không bao giờ lệch nhau.
- Phản hồi: đặt sai → ghost rung ±4px 0.2s + lý do nổi lên; đặt đúng → tháp "đáp đất" (squash 0.18s),
  sóng vòng lan tới đúng tầm bắn, bụi, "-giá". Animation chỉ để trình diễn, không khoá input.

## Kiến trúc

```
tower-defense/
├── project.godot               # main scene = menu chính; autoload: GameManager, AudioManager, SaveManager
├── assets/audio/               # thả file âm thanh vào đây (xem README trong thư mục)
├── data/waves/level_XX.json    # wave của từng màn
├── resources/
│   ├── abilities/              # AbilityData: Thiên thạch, Băng giá
│   ├── effects/                # StatusEffectData: làm chậm, thiêu đốt (3 cấp), đóng băng
│   ├── enemies/                # EnemyData: 5 loại địch
│   ├── levels/                 # LevelData từng màn + catalog.tres (thứ tự màn)
│   ├── towers/                 # TowerData: 4 tháp × 3 cấp (chuỗi next_level)
│   └── ui/theme.tres           # theme UI dùng chung
├── scenes/
│   ├── main/Main.tscn          # trận đấu (nạp bản đồ theo màn)
│   ├── maps/Map01..03.tscn     # bản đồ: chỉ chứa các Path2D (làn đường)
│   ├── menus/                  # MainMenu, LevelSelect
│   ├── enemies/, towers/, projectiles/
│   └── ui/                     # HUD, TowerInfoPanel, PauseMenu, SettingsMenu
├── scripts/
│   ├── autoload/               # GameManager, AudioManager, SaveManager (tiến độ + cài đặt)
│   ├── combat/                 # DamageInfo, Combat, Projectile, StatusEffectHandler
│   ├── managers/               # WaveManager, WaveGenerator, BuildManager, SelectionManager,
│   │                           # AbilityManager, TutorialManager
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
├── AbilityManager    ← kỹ năng chủ động: hồi chiêu, ngắm vùng, phím Q/E
├── WaveManager       ← đọc wave (hoặc sinh wave vô tận), spawn địch, đếm địch theo từng wave
├── TutorialManager   ← hướng dẫn lần đầu (Main chuyển tiếp sự kiện cho nó)
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

**Thêm kỹ năng:** tạo `AbilityData` trong `resources/abilities/` (phím tắt, hồi chiêu, bán kính,
sát thương, hiệu ứng), rồi thêm vào mảng *Abilities* của node `AbilityManager` trong `Main.tscn`.

**Địch bay:** bật `is_flying` trong `EnemyData`. Địch bay đi theo các Path2D trong node `AirPaths`
của bản đồ; nếu bản đồ không có node này, một làn thẳng từ đầu làn 1 tới nhà chính được tạo tự động.
Tháp có `can_hit_air = false` (như Pháo) không nhắm và không nổ lan trúng địch bay.

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

## Xuất bản (Windows / Web)

> Chi tiết bản build hiện tại, cách chạy và cách đưa lên itch.io: xem **[README_BUILD.md](README_BUILD.md)**.

Project đã có sẵn `export_presets.cfg` với 2 cấu hình: **Windows Desktop** và **Web**
(cả hai đã tự kèm các file `data/*.json` và bỏ thư mục `tests/`). Chỉ cần làm một lần:

1. Trong Godot: **Editor → Manage Export Templates → Download and Install**
   (tải bộ template đúng phiên bản 4.7.2, khoảng vài trăm MB).
2. **Project → Export…** → chọn **Windows Desktop** hoặc **Web** → **Export Project**.
   - Windows: ra file `build/windows/TowerDefense.exe` (đã gộp dữ liệu vào trong file .exe).
   - Web: ra thư mục `build/web/` (mở `index.html` qua một web server; có thể nén cả thư mục
     thành .zip để đăng lên itch.io với tuỳ chọn "This file will be played in the browser").

Thư mục `build/` đã nằm trong `.gitignore`. Cấu hình Web tắt đa luồng (`thread_support = false`)
nên chạy được trên itch.io / GitHub Pages mà không cần cấu hình header đặc biệt.

## Test tự động

```
godot --headless --path tower-defense --fixed-fps 60 res://tests/smoke_test.tscn
```

Chạy khoảng 25 giây. Gồm:
- Kiểm tra từng hệ thống: kháng sát thương, hiệu ứng, Boss sinh con, đặt / nâng cấp / bán / chọn
  tháp bằng chuột và phím, tốc độ, tạm dừng, gọi wave sớm, khoá / mở màn, sao.
- Với **mỗi màn**: một bot tự chọn ô có độ phủ đường đi tốt nhất phải **thắng**, và không xây
  tháp thì phải **thua**. Bot hiện thắng cả 3 màn với 2 sao (còn 10 / 10 / 8 máu); 3 sao là thử thách.
Ở chế độ vô tận (đo riêng), bot nâng cấp tối đa trụ được tới khoảng wave 31–40.

Exit code 0 = đạt. Test dùng file save riêng nên không ảnh hưởng tiến độ thật.
