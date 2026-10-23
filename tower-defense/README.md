# Tower Defense 2D (Godot 4)

Project Tower Defense 2D viết bằng GDScript, dùng **Godot 4.7**.
Chưa cần asset nào: mọi thứ được vẽ tạm bằng `_draw()`, bấm Play là chơi được ngay.

## Chạy thử

1. Mở Godot 4.7 → **Import** → chọn file `tower-defense/project.godot`.
2. Bấm **Play** (F5).

### Điều khiển

| Thao tác | Tác dụng |
|---|---|
| Chuột trái | Đặt tháp đang chọn (bóng xanh = đặt được, đỏ = không) |
| Chuột phải / Esc | Thoát chế độ xây |
| Phím `1`–`4` hoặc nút ở thanh dưới | Chọn loại tháp |
| `Space` hoặc nút **Bắt đầu Wave** | Gọi wave tiếp theo |
| Click vào tháp (khi không xây) | Xem tầm bắn của tháp |

Bắt đầu với 200 vàng và 20 máu. Vượt qua 10 wave là thắng.

## Tháp

| Tháp | Giá | Kiểu bắn | Sát thương | Đặc điểm |
|---|---|---|---|---|
| Cung thủ | 50 | Đạn nhanh | Vật lý | Rẻ, bắn nhanh |
| Pháo | 90 | Đạn chậm | Vật lý | **Nổ lan** bán kính 64, khắc chế Bầy chuột |
| Băng | 70 | Tia (trúng ngay) | Phép | **Làm chậm 40%** các địch quanh mục tiêu |
| Phép | 120 | Tia (trúng ngay) | Phép | Sát thương cao + **thiêu đốt**, khắc chế Bọc thép |

## Địch

| Địch | Hình | Đặc điểm |
|---|---|---|
| Lính thường | Tròn đỏ | Cân bằng |
| Trinh sát | Tam giác vàng | Rất nhanh, kháng phép 50% |
| Bọc thép | Vuông xám | Giáp 60% (giảm sát thương vật lý), trừ 2 máu nhà |
| Bầy chuột | Tròn tím nhỏ | Yếu nhưng đi rất đông |
| Chúa quỷ (Boss) | Kim cương đỏ sẫm | Rất trâu, kháng chậm 50%, chết thì **sinh 8 Bầy chuột** |

## Hệ thống chiến đấu

- **Loại sát thương** (`DamageInfo.Type`): `PHYSICAL` bị giảm bởi `armor`, `MAGIC` bị giảm bởi
  `magic_resist`, `TRUE` bỏ qua kháng (dùng cho thiêu đốt).
- **Hiệu ứng trạng thái** (`StatusEffectData`): làm chậm và/hoặc sát thương theo thời gian.
  Hiệu ứng cùng `id` không cộng dồn: cái mạnh hơn thay thế, cái yếu hơn chỉ làm mới thời gian.
  Nhiều hiệu ứng làm chậm khác nhau thì lấy cái mạnh nhất.
- **Đạn** (`Projectile`): đuổi theo mục tiêu. Mục tiêu chết giữa đường thì đạn bay tới vị trí cuối:
  đạn nổ lan vẫn gây sát thương, đạn thường thì trượt.
- Mọi cú đánh (tia hay đạn) đều đi qua `Combat.apply_hit()` nên nổ lan và hiệu ứng hoạt động giống nhau.

## Cấu trúc thư mục

```
tower-defense/
├── project.godot
├── assets/                     # sprite, âm thanh, font (để trống)
├── data/waves.json             # cấu hình 10 wave
├── resources/
│   ├── effects/                # slow.tres, burn.tres (StatusEffectData)
│   ├── enemies/                # 5 loại địch (EnemyData)
│   └── towers/                 # 4 loại tháp (TowerData)
├── scenes/
│   ├── main/Main.tscn          # scene chính
│   ├── enemies/Enemy.tscn
│   ├── projectiles/Projectile.tscn
│   ├── towers/Tower.tscn
│   └── ui/HUD.tscn
├── scripts/
│   ├── autoload/GameManager.gd     # vàng, máu, wave, trạng thái game
│   ├── combat/                     # DamageInfo, Combat, Projectile, StatusEffectHandler
│   ├── core/GameConfig.gd          # hằng số lưới / bản đồ
│   ├── enemies/Enemy.gd
│   ├── towers/Tower.gd
│   ├── managers/WaveManager.gd     # spawn địch theo wave
│   ├── managers/BuildManager.gd    # đặt tháp bằng chuột
│   ├── resources/                  # EnemyData, TowerData, StatusEffectData
│   ├── main/Main.gd, Ground.gd
│   └── ui/HUD.gd
└── tests/smoke_test.tscn       # test tự động chơi hết game
```

### Cây node của `Main.tscn`

```
Main (Node2D)                 ← Main.gd: nối signal giữa các hệ thống
├── Ground (Node2D)           ← nền tạm (cỏ, đường đi, nhà chính)
├── Towers (Node2D)           ← chứa các tháp đã đặt
├── Enemies (Node2D)          ← chứa địch
│   └── EnemyPath (Path2D)    ← đường đi; mỗi địch là một PathFollow2D con
├── Projectiles (Node2D)      ← đạn đang bay (vẽ trên địch)
├── BuildManager (Node2D)     ← đặt tháp + vẽ bóng tháp
├── WaveManager (Node)        ← spawn địch
└── UI (CanvasLayer)
    └── HUD
```

## Luồng signal chính

- `Enemy.died` / `Enemy.reached_end` → `WaveManager` → `GameManager.add_gold()` / `lose_lives()`
  (và sinh địch con nếu `EnemyData.spawn_on_death` được đặt)
- `GameManager.gold_changed`, `lives_changed`, `wave_changed` → `HUD` cập nhật chữ
- `GameManager.state_changed` → `Main` pause game, hiện bảng Thắng/Thua
- `HUD.start_wave_pressed` → `WaveManager.start_next_wave()`
- `HUD.tower_selected` → `BuildManager.select_tower()`; `BuildManager.placement_failed` → `HUD.show_message()`
- `Enemy.damaged`, `Tower.fired`, `Projectile.impacted`: đã có sẵn cho hiệu ứng hình ảnh và âm thanh sau này

## Test tự động

```
godot --headless --path tower-defense --fixed-fps 60 res://tests/smoke_test.tscn
```

Test kiểm tra kháng sát thương, làm chậm, thiêu đốt, Boss sinh con, luật đặt tháp và dữ liệu wave.
Sau đó một bot đặt tháp theo kế hoạch và phải **thắng** cả 10 wave; không đặt tháp thì phải **thua**.
Exit code 0 = đạt. Trong editor, có thể mở `tests/smoke_test.tscn` rồi bấm **F6** để chạy.

## Mở rộng

**Thêm loại địch:** nhân bản một file trong `resources/enemies/`, đổi `id` (phải duy nhất) và chỉ số.
WaveManager tự quét thư mục này, nên trong `waves.json` chỉ cần ghi `"enemy": "<id>"`.

**Thêm loại tháp:** nhân bản một file trong `resources/towers/`, chỉnh chỉ số, rồi thêm vào mảng
*Available Towers* của node `BuildManager` trong `Main.tscn`. Nút ở thanh dưới và phím tắt sẽ tự có.

**Thêm hiệu ứng:** tạo `StatusEffectData` mới trong `resources/effects/` rồi thêm vào
`On Hit Effects` của tháp.

**Sửa wave:** chỉnh `data/waves.json`. Nếu có lỗi (sai id, thiếu `groups`...), cửa sổ Output
sẽ báo rõ wave và group nào bị sai.

```json
{
  "reward_bonus": 30,
  "groups": [
    { "enemy": "basic", "count": 8, "interval": 0.7, "health_multiplier": 1.4 },
    { "enemy": "fast", "count": 6, "interval": 0.4, "delay": 2.0, "speed_multiplier": 1.5 }
  ]
}
```

| Trường | Ý nghĩa |
|---|---|
| `reward_bonus` | Vàng thưởng khi hết wave |
| `enemy` | `id` của loại địch (hoặc đường dẫn `res://...tres`) |
| `count` | Số địch trong nhóm |
| `interval` | Giây giữa hai con liên tiếp |
| `delay` | Giây chờ trước con đầu tiên của nhóm (tính từ con cuối nhóm trước) |
| `health_multiplier`, `speed_multiplier` | Hệ số nhân máu / tốc độ (mặc định 1) |

**Sửa đường đi:** chọn node `Enemies/EnemyPath` trong `Main.tscn` và kéo các điểm của Curve2D.
Nền và luật cấm xây trên đường sẽ tự cập nhật theo.
