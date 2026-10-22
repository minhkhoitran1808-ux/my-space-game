# Tower Defense 2D (Godot 4)

Khung project Tower Defense 2D viết bằng GDScript, dùng **Godot 4.3+**.
Chưa cần asset nào: mọi thứ được vẽ tạm bằng `_draw()`, bấm Play là chơi được ngay.

## Chạy thử

1. Mở Godot 4.3 (hoặc mới hơn) → **Import** → chọn file `tower-defense/project.godot`.
2. Bấm **Play** (F5).

### Điều khiển

| Thao tác | Tác dụng |
|---|---|
| Chuột trái | Đặt tháp đang chọn (bóng xanh = đặt được, đỏ = không) |
| Chuột phải / Esc | Thoát chế độ xây |
| Phím `1`–`9` hoặc nút trên thanh UI | Chọn loại tháp |
| `Space` hoặc nút **Bắt đầu Wave** | Gọi wave tiếp theo |
| Click vào tháp (khi không xây) | Xem tầm bắn của tháp |

Bắt đầu với 150 vàng và 20 máu. Mỗi tháp cơ bản giá 50 vàng. Vượt qua 5 wave là thắng.

## Cấu trúc thư mục

```
tower-defense/
├── project.godot
├── assets/                  # sprite, âm thanh, font (để trống)
├── data/
│   └── waves.json           # cấu hình các wave
├── resources/
│   ├── enemies/basic_enemy.tres   # chỉ số địch (EnemyData)
│   └── towers/basic_tower.tres    # chỉ số tháp (TowerData)
├── scenes/
│   ├── main/Main.tscn       # scene chính
│   ├── enemies/Enemy.tscn
│   ├── towers/Tower.tscn
│   └── ui/HUD.tscn
└── scripts/
    ├── autoload/GameManager.gd   # vàng, máu, wave, trạng thái game
    ├── core/GameConfig.gd        # hằng số lưới / bản đồ
    ├── enemies/Enemy.gd
    ├── towers/Tower.gd
    ├── managers/WaveManager.gd   # spawn địch theo wave
    ├── managers/BuildManager.gd  # đặt tháp bằng chuột
    ├── resources/EnemyData.gd, TowerData.gd
    ├── main/Main.gd, Ground.gd
    └── ui/HUD.gd
```

### Cây node của `Main.tscn`

```
Main (Node2D)                 ← Main.gd: nối signal giữa các hệ thống
├── Ground (Node2D)           ← nền tạm (cỏ, đường đi, nhà chính)
├── Towers (Node2D)           ← chứa các tháp đã đặt
├── Enemies (Node2D)          ← chứa địch
│   └── EnemyPath (Path2D)    ← đường đi; mỗi địch là một PathFollow2D con
├── BuildManager (Node2D)     ← đặt tháp + vẽ bóng tháp
├── WaveManager (Node)        ← spawn địch
└── UI (CanvasLayer)
    └── HUD
```

Địch là `PathFollow2D` nên phải là con trực tiếp của `Path2D`. Vì vậy `Enemies`
chứa một hoặc nhiều `Path2D`, sau này có thể thêm nhiều làn đường.

## Luồng signal chính

- `Enemy.died` / `Enemy.reached_end` → `WaveManager` → `GameManager.add_gold()` / `lose_lives()`
- `GameManager.gold_changed`, `lives_changed`, `wave_changed` → `HUD` cập nhật chữ
- `GameManager.state_changed` → `Main` pause game, hiện bảng Thắng/Thua
- `HUD.start_wave_pressed` → `WaveManager.start_next_wave()`
- `HUD.tower_selected` → `BuildManager.select_tower()`; `BuildManager.placement_failed` → `HUD.show_message()`

## Mở rộng

**Thêm loại địch:** nhân bản `resources/enemies/basic_enemy.tres`, sửa máu, tốc độ, màu...
rồi dùng đường dẫn của nó trong `data/waves.json`.

**Thêm loại tháp:** nhân bản `resources/towers/basic_tower.tres`, sửa chỉ số, rồi thêm vào
mảng *Available Towers* của node `BuildManager` trong `Main.tscn`. Nút trên HUD và phím tắt sẽ tự có.

**Sửa wave:** chỉnh `data/waves.json`:

```json
{
  "reward_bonus": 30,
  "groups": [
    { "enemy": "res://resources/enemies/basic_enemy.tres", "count": 8, "interval": 0.7,
      "health_multiplier": 1.4 },
    { "enemy": "res://resources/enemies/basic_enemy.tres", "count": 6, "interval": 0.4,
      "delay": 2.0, "speed_multiplier": 1.5 }
  ]
}
```

| Trường | Ý nghĩa |
|---|---|
| `reward_bonus` | Vàng thưởng khi hết wave |
| `enemy` | Đường dẫn tới file `EnemyData` (.tres) |
| `count` | Số địch trong nhóm |
| `interval` | Giây giữa hai con liên tiếp |
| `delay` | Giây chờ trước con đầu tiên của nhóm (tính từ con cuối nhóm trước) |
| `health_multiplier`, `speed_multiplier` | Hệ số nhân máu / tốc độ (mặc định 1) |

**Sửa đường đi:** chọn node `Enemies/EnemyPath` trong `Main.tscn` và kéo các điểm của Curve2D.
Nền và luật cấm xây trên đường sẽ tự cập nhật theo.

**Thay nền bằng TileMapLayer:** xoá/ẩn node `Ground` và thêm `TileMapLayer` với ô 64×64
(`GameConfig.CELL_SIZE`).

**Đạn bay / hiệu ứng:** thay nội dung hàm `Tower._shoot()`.
