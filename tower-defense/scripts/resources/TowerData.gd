class_name TowerData
extends Resource
## Dữ liệu cấu hình cho một loại tháp.
##
## Muốn thêm loại tháp mới: tạo file .tres mới trong res://resources/towers/
## rồi thêm nó vào mảng "Available Towers" của node BuildManager trong Main.tscn.

@export var id: StringName = &"basic"
@export var display_name: String = "Tháp"
@export var cost: int = 50

@export_group("Chiến đấu")
## Sát thương mỗi phát bắn.
@export var damage: float = 20.0
## Số phát bắn mỗi giây.
@export var fire_rate: float = 1.5
## Tầm bắn (pixel, tính từ tâm tháp).
@export var attack_range: float = 160.0

@export_group("Hiển thị")
@export var color: Color = Color(0.3, 0.6, 1.0)

@export_group("Scene")
## Scene sẽ được instantiate khi đặt tháp (gốc phải là Tower).
@export var scene: PackedScene
