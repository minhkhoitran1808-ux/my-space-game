class_name TowerData
extends Resource
## Dữ liệu cấu hình cho một loại tháp.
##
## Hành vi của tháp được quyết định hoàn toàn bằng dữ liệu (kiểu bắn, loại sát thương,
## nổ lan, hiệu ứng...), nên tháp mới thường chỉ là một file .tres mới.
## Muốn thêm loại tháp: tạo .tres trong res://resources/towers/ rồi thêm vào mảng
## "Available Towers" của node BuildManager trong Main.tscn.
##
## Nâng cấp là một chuỗi .tres: cấp 1 trỏ next_level tới cấp 2, cấp 2 trỏ tới cấp 3.
## Nâng cấp tháp = thay data của nó bằng next_level.

enum AttackType {
	HITSCAN, ## Trúng ngay lập tức (tia sáng).
	PROJECTILE, ## Bắn đạn bay đuổi theo mục tiêu.
}

@export var id: StringName = &"basic"
@export var display_name: String = "Tháp"
## Mô tả ngắn hiện trong tooltip của nút xây.
@export_multiline var description: String = ""
## Giá xây (cấp 1) hoặc giá nâng cấp lên cấp này (cấp 2, 3...).
@export var cost: int = 50

@export_group("Nâng cấp")
## Cấp của bộ chỉ số này (1, 2, 3...).
@export var level: int = 1
## Bộ chỉ số của cấp tiếp theo (để trống = đã tối đa).
@export var next_level: TowerData

@export_group("Chiến đấu")
@export var attack_type: AttackType = AttackType.PROJECTILE
@export var damage_type: DamageInfo.Type = DamageInfo.Type.PHYSICAL
## Sát thương mỗi phát bắn.
@export var damage: float = 20.0
## Số phát bắn mỗi giây.
@export var fire_rate: float = 1.5
## Tầm bắn (pixel, tính từ tâm tháp).
@export var attack_range: float = 160.0
## Bán kính nổ lan (0 = chỉ trúng một mục tiêu).
@export var splash_radius: float = 0.0
## Hiệu ứng gây lên mọi địch bị trúng.
@export var on_hit_effects: Array[StatusEffectData] = []

@export_group("Đạn")
## Tốc độ đạn (pixel / giây). Chỉ dùng khi attack_type = PROJECTILE.
@export var projectile_speed: float = 500.0
## Scene đạn riêng (để trống = dùng đạn mặc định).
@export var projectile_scene: PackedScene

@export_group("Hiển thị")
@export var color: Color = Color(0.3, 0.6, 1.0)

@export_group("Scene")
## Scene sẽ được instantiate khi đặt tháp (gốc phải là Tower).
@export var scene: PackedScene


func can_upgrade() -> bool:
	return next_level != null
