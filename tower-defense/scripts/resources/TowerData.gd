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
## Cấp 3 không có next_level mà có 2 nhánh cấp 4 (branches[0] = nhánh A, branches[1] = nhánh B),
## mỗi nhánh có điểm yếu riêng (weakness_text). Nâng cấp tháp = thay data bằng get_upgrade().
##
## Tháp không bắn (is_attacker() = false):
## - Cờ hiệu: aura_radius > 0, cộng aura_damage_bonus sát thương cho tháp khác trong bán kính.
## - Mỏ vàng: gold_per_wave > 0, cộng vàng mỗi khi hết một wave.

enum AttackType {
	HITSCAN, ## Trúng ngay lập tức (tia sáng).
	PROJECTILE, ## Bắn đạn bay đuổi theo mục tiêu.
	PULSE, ## Sóng toả quanh tháp: trúng MỌI địch trong tầm bắn cùng lúc.
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
## Bộ chỉ số của cấp tiếp theo (để trống = hết chuỗi thẳng; xem branches).
@export var next_level: TowerData
## Các nhánh nâng cấp khi không còn next_level (thường ở cấp 3: [nhánh A, nhánh B]).
## (Kiểu Array[Resource] thay vì Array[TowerData]: mảng có kiểu chính lớp này tạo tham chiếu
## vòng tới script và làm Godot báo rò rỉ khi thoát. Phần tử luôn là TowerData.)
@export var branches: Array[Resource] = []
## Tên nhánh (vd "Xạ thủ") và điểm yếu của nhánh, hiện ở bảng thông tin tháp.
@export var branch_name: String = ""
@export var weakness_text: String = ""
## Chế độ nhắm tự đặt khi nâng lên nhánh này (-1 = giữ nguyên lựa chọn của người chơi).
@export var preferred_target_mode: int = -1

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
## Bỏ qua bao nhiêu phần giáp vật lý của địch (0.5 = chỉ còn tính một nửa giáp).
@export_range(0.0, 1.0, 0.05) var armor_pen: float = 0.0
## Hiệu ứng gây lên mọi địch bị trúng.
@export var on_hit_effects: Array[StatusEffectData] = []
## Có bắn được địch bay không (false = chỉ bắn mục tiêu mặt đất).
@export var can_hit_air: bool = true

@export_group("Hỗ trợ / kinh tế")
## Cờ hiệu: bán kính hào quang và % sát thương cộng thêm cho tháp khác (không cộng dồn nhiều cờ).
@export var aura_radius: float = 0.0
@export var aura_damage_bonus: float = 0.0
## Mỏ vàng: vàng nhận thêm mỗi khi hết một wave.
@export var gold_per_wave: int = 0
## Tỉ lệ hoàn tiền khi bán (-1 = dùng GameConfig.SELL_REFUND_RATIO).
@export var sell_ratio: float = -1.0

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
	return next_level != null or not branches.is_empty()


## Bộ chỉ số sau khi nâng cấp theo nhánh `branch` (null nếu không còn nâng được).
func get_upgrade(branch: int = 0) -> TowerData:
	if next_level:
		return next_level
	if branch >= 0 and branch < branches.size():
		return branches[branch] as TowerData
	return null


## Tháp có tự bắn không (Cờ hiệu / Mỏ vàng thì không).
func is_attacker() -> bool:
	return damage > 0.0 and fire_rate > 0.0


func get_sell_ratio() -> float:
	return sell_ratio if sell_ratio >= 0.0 else GameConfig.SELL_REFUND_RATIO
