class_name TowerData
extends Resource
## Dữ liệu cấu hình cho một loại tháp.
##
## Hành vi của tháp được quyết định hoàn toàn bằng dữ liệu (kiểu bắn, loại sát thương,
## nổ lan, hiệu ứng...), nên tháp mới thường chỉ là một file .tres mới.
## Muốn thêm loại tháp: tạo .tres trong res://resources/towers/ rồi thêm vào mảng
## "Available Towers" của node BuildManager trong Main.tscn.

enum AttackType {
	HITSCAN, ## Trúng ngay lập tức (tia sáng).
	PROJECTILE, ## Bắn đạn bay đuổi theo mục tiêu.
}

@export var id: StringName = &"basic"
@export var display_name: String = "Tháp"
@export var cost: int = 50

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
