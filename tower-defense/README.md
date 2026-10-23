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

**4 màn chơi**, màn sau mở khi qua màn trước. Qua màn được 1–3 sao theo số máu còn lại
(≥ 80% = 3 sao, ≥ 40% = 2 sao). Tiến độ lưu ở `user://save.profile.json` (xem "Meta-progression").

| Màn | Bản đồ | Wave | Vàng đầu |
|---|---|---|---|
| Đồng cỏ | 1 làn quanh co | 10 | 200 |
| Ngã ba sông | 2 làn nhập làm một | 10 | 260 |
| Đường rắn | 1 làn rất dài, 2 Boss | 12 | 300 |
| Pháo đài | 2 làn hội quân giữa bản đồ, nhiều Thầy lang | 12 | 320 |

**Hướng dẫn chơi lần đầu:** vào màn 1 lần đầu sẽ có hướng dẫn từng bước (xây tháp → gọi wave →
chọn tháp → nâng cấp → dùng kỹ năng), có nút "Bỏ qua". Xem lại được trong Cài đặt.

**Cài đặt** (menu chính hoặc menu tạm dừng): âm lượng, bật/tắt số sát thương, rung màn hình,
toàn màn hình, và nhóm hiển thị / hỗ trợ (xem bên dưới). Lưu trong `user://save.cfg`, tách khỏi tiến độ ("Xoá tiến độ" không xoá cài đặt).

**Giới thiệu địch mới:** lần đầu một loại địch xuất hiện (theo file save), một dòng mẹo hiện ở cuối
màn hình, vd "Địch mới: Thầy lang - Hồi máu cho đồng đội: hạ nó trước!" (`EnemyData.hint`).

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

**7 loại địch:**

| Địch | Hình | Đặc điểm |
|---|---|---|
| Lính thường | Tròn đỏ | Cân bằng |
| Trinh sát | Tam giác vàng | Rất nhanh, kháng phép 50% |
| Bọc thép | Vuông xám | Giáp 60%, trừ 2 máu nhà |
| Bầy chuột | Tròn tím nhỏ | Yếu nhưng rất đông |
| Dơi lửa | Có cánh, cam | **Bay** thẳng tới nhà chính, bỏ qua đường đi; Pháo không bắn được |
| Chúa quỷ (Boss) | Kim cương đỏ sẫm | Rất trâu, kháng chậm 50%, trừ 10 máu, chết thì **sinh 8 Bầy chuột** |
| Thầy lang | Tròn xanh có dấu cộng | Cứ 2.5s **hồi máu** cho địch khác trong 110px (không tự hồi), giáp 20%. Nên hạ trước |

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

## Thanh máu địch và hiệu ứng trúng đòn

Hai component con của `scenes/enemies/Enemy.tscn`, chỉ nghe signal của Enemy (`health_changed`, `damaged`),
không đụng tới máu, tốc độ hay việc chết / chạm nhà.

- `scenes/enemies/HealthBar.tscn` + `scripts/enemies/HealthBar.gd`: thanh mảnh 4–6px, viền 1px tối, nền tối.
  - Màu đổi theo ngưỡng: > 50% xanh lá `#4ADE50`, 25–50% vàng `#FACC15`, ≤ 25% đỏ `#EF4444`
    (máu thấp còn đổi viền sang trắng, để không phụ thuộc chỉ vào màu).
  - Vệt sát thương trắng: máu thật tụt ngay, vệt giữ 0.4s rồi rút (1.5 thanh/giây).
  - Ẩn khi đầy máu, hiện dần 0.08s từ cú trúng đầu tiên. Địch `elite = true` (Boss): luôn hiện, rộng 56px, vạch chia 25%.
  - Rộng theo cỡ địch (`radius × 2.6`, kẹp 26–40px), đặt trên đỉnh thân 7px (địch bay: trên thân đang bay),
    `z_index = 10` nên luôn nằm trên mọi địch. Không xoay, không bị nén theo thân.
- `scripts/enemies/HitFeedback.gd`: nháy trắng 0.10s (ease-out) + giật (1.08, 0.92) trong 0.12s, neo ở chân.
  Tối đa 3 lần nháy / giây mỗi địch; thiêu đốt (sát thương theo thời gian) không nháy; Boss giật nhẹ hơn.
- Hiệu năng: cả hai chỉ chạy `_process` trong lúc có hiệu ứng rồi tự tắt; thanh máu chỉ vẽ lại khi máu đổi.
- Thanh máu Boss trên HUD (`scripts/ui/BossBar.gd`): hiện khi địch `elite` xuất hiện, dùng lại `HealthBar`
  (440×12px, vệt sát thương, vạch chia), kèm tên, "máu / tối đa" và "×N" nếu nhiều Boss cùng lúc.
- Tia lửa khi trúng đòn (`FxManager`): 3 vệt nhỏ, 0.22s, màu theo loại sát thương; tối đa 90 tia cùng lúc,
  thiêu đốt không tạo tia.

## Cài đặt hiển thị và hỗ trợ người chơi

Menu Cài đặt có nhóm "Hiển thị & hỗ trợ", lưu trong `user://save.cfg` và áp dụng ngay (kể cả giữa trận):

| Cài đặt | Giá trị | Ảnh hưởng |
|---|---|---|
| Nháy khi địch trúng đòn | Đầy đủ / Nhẹ (35%) / Tắt | `HitFeedback` |
| Thanh máu địch | Khi bị thương / Luôn hiện / Tắt (Boss luôn hiện) | `HealthBar` |
| Giảm chuyển động | bật / tắt | tắt giật thân địch, vệt máu rút dần, rung màn hình, xoay / nhịp vòng tầm bắn, rung ghost, squash + sóng lan khi đặt tháp, nảy / rung nút HUD |
| Màu cho người mù màu | bật / tắt | thanh máu xanh dương / vàng / cam thay cho xanh lá / vàng / đỏ |

Giá trị được giữ ở biến static trong `scripts/core/VisualSettings.gd` (SaveManager cập nhật), nên hiệu ứng chạy mỗi frame đọc thẳng mà không tra file.

## Meta-progression (tiến trình ngoài trận)

Mỗi ván, kể cả khi thua, đều mang về thứ gì đó. Toàn bộ chạy offline: không bán vật phẩm ngẫu nhiên
bằng tiền thật, không mạnh lên nhờ trả tiền, không trao đổi giữa người chơi (cần server mới làm an toàn).

| Hệ thống | Tóm tắt |
|---|---|
| **Thưởng cuối ván** | Xu = `coin_reward` của màn × (wave đã qua / tổng)^1.3, thắng +40%. KN = 20 + 2 × wave. Bảng kết quả đếm xu, chạy thanh KN, lật đồ rơi theo độ hiếm. |
| **Cấp tài khoản** | Cần 100 + 40 × cấp KN để lên cấp; mỗi cấp thưởng 50 × cấp xu. |
| **Thành tựu** (19) | Cột mốc / Thử thách / Khám phá / Ẩn. Bấm "Nhận" mới cộng thưởng (xu, danh hiệu, skin độc quyền). Thông báo nổi góc trên phải, xếp hàng, không chặn game. |
| **Vật phẩm** (16) | 5 độ hiếm (Thường xám, Ít gặp xanh lá, Hiếm xanh dương, Sử thi tím, Huyền thoại cam), mỗi bậc có **khung riêng** (vuông / vuông + vạch / góc vát / lục giác / lục giác + hào quang) và tên chữ. Skin tháp chỉ đổi ngoại hình; đồ tiêu hao (+vàng / +máu, tối đa 2 món mỗi ván); nguyên liệu. Đồ rơi cuối ván: 1 món, thắng +1. Skin trùng tự thành Bụi. |
| **Cửa hàng** | Hôm nay: 4 món giá cố định, đổi theo ngày, không trả tiền để đổi sớm. Thương nhân: công thức đổi cố định. Ghép đồ: 5 món cùng bậc → 1 món bậc kế. Nâng cấp vĩnh viễn: 300 × 1.15^cấp xu, **giới hạn** +10% vàng đầu, +2 máu. |
| **Nhiệm vụ ngày** | 3 nhiệm vụ / ngày, giữ tối đa 3 ngày, đổi miễn phí 1 lần / ngày. |
| **Quà đăng nhập** | Chuỗi 7 ngày, bỏ lỡ ngày thì tạm dừng chứ không reset. |
| **Codex** | Album địch đã gặp (chỉ số + mẹo) và mọi vật phẩm (chưa có thì hiện bóng tối + nguồn nhận). |

Menu chính là "hub": thẻ hồ sơ (cấp, danh hiệu, KN, Xu, Bụi) và lưới nút các màn hình trên, có chấm đỏ
khi có thứ để nhận.

**Kiến trúc meta:**
- `Events` (autoload, chỉ khai báo signal). Trong trận, `MatchTracker` (node con của Main) nghe các hệ thống
  rồi phát `enemy_killed`, `wave_survived`, `tower_built`, `match_ended`... Hệ thống meta chỉ nghe Events.
- Autoload: `SaveManager` → `EconomyManager` (xu, bụi; mọi thay đổi ghi lý do) → `StatsManager` (bộ đếm)
  → `ProgressionManager` (cấp, KN, danh hiệu, thưởng ván) → `InventoryManager` → `ShopManager`
  → `AchievementManager` → `DailyManager` → `ToastLayer`.
- **Hồ sơ = JSON** (`user://save.profile.json`), có `save_version` + `_migrate()`; ghi ra `.tmp` rồi đổi tên,
  giữ `.bak` và tự khôi phục nếu file chính hỏng. Không lưu save bằng Resource (Resource có thể chứa script).
  Save cũ (tiến độ trong `save.cfg`) được chuyển sang tự động ở lần chạy đầu.
- Các manager không giữ bản sao: đọc / ghi thẳng `SaveManager.section(...)` rồi `request_save()` (gộp
  mọi yêu cầu trong một frame). Không ghi đĩa sau mỗi lần hạ địch, chỉ khi hết wave / hết ván / nhận thưởng.
- Nội dung là Resource `.tres`: `resources/achievements/`, `resources/items/`, `resources/merchant/`,
  `resources/quests/`. **`id` không được đổi sau khi phát hành** (là khoá trong file save).
- `tradeable_p2p` luôn false: trao đổi giữa người chơi để dành cho khi có server.

## Kiến trúc

```
tower-defense/
├── project.godot               # main scene = menu chính; autoload: Events, GameManager, AudioManager,
│                               # SaveManager + các manager meta (xem "Meta-progression")
├── assets/audio/               # 16 âm thanh tổng hợp bằng tools/gen_sfx.py (thay được bằng file của bạn)
├── data/waves/level_XX.json    # wave của từng màn
├── resources/
│   ├── abilities/              # AbilityData: Thiên thạch, Băng giá
│   ├── effects/                # StatusEffectData: làm chậm, thiêu đốt (3 cấp), đóng băng
│   ├── enemies/                # EnemyData: 7 loại địch
│   ├── levels/                 # LevelData từng màn + catalog.tres (thứ tự màn)
│   ├── achievements/, items/,  # Meta: AchievementDef, ItemDef, MerchantRecipe, QuestDef
│   │   merchant/, quests/
│   ├── towers/                 # TowerData: 4 tháp × 3 cấp (chuỗi next_level)
│   └── ui/theme.tres           # theme UI dùng chung
├── scenes/
│   ├── main/Main.tscn          # trận đấu (nạp bản đồ theo màn)
│   ├── maps/Map01..04.tscn     # bản đồ: chỉ chứa các Path2D (làn đường)
│   ├── menus/                  # MainMenu, LevelSelect
│   ├── enemies/, towers/, projectiles/
│   └── ui/                     # HUD, TowerInfoPanel, PauseMenu, SettingsMenu
├── scripts/
│   ├── autoload/               # GameManager, AudioManager, SaveManager (hồ sơ JSON + cài đặt),
│   │                           # Events, Economy/Stats/Progression/Inventory/Shop/Achievement/Daily, ToastLayer
│   ├── combat/                 # DamageInfo, Combat, Projectile, StatusEffectHandler
│   ├── managers/               # WaveManager, WaveGenerator, BuildManager, SelectionManager,
│   │                           # AbilityManager, TutorialManager
│   ├── fx/FxManager.gd         # số sát thương, vụ nổ, rung màn hình
│   ├── enemies/                # Enemy + HealthBar + HitFeedback + HealerAura
│   ├── main/                   # Main, Ground, GameMap, MatchTracker
│   ├── ui/meta/                # MetaScreen + Thành tựu, Kho đồ, Cửa hàng, Nhiệm vụ, Codex, ItemSlot
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

**Thêm thành tựu / vật phẩm / công thức thương nhân / nhiệm vụ:** nhân bản một `.tres` trong
`resources/achievements/`, `items/`, `merchant/` hoặc `quests/` và đổi `id`. Các manager tự quét thư mục.

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

**Âm thanh:** game đã có đủ 16 âm thanh tổng hợp (`python3 tools/gen_sfx.py` để tạo lại).
Muốn thay: thả file `.ogg` / `.wav` / `.mp3` đúng tên vào `assets/audio/`
(danh sách tên trong `assets/audio/README.md`). Thiếu file thì sự kiện đó im lặng, không lỗi.

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
