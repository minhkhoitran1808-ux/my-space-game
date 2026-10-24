class_name StatusEffectData
extends Resource
## Cấu hình một hiệu ứng trạng thái (làm chậm, thiêu đốt...).
##
## Một hiệu ứng có thể vừa làm chậm vừa gây sát thương theo thời gian.
## Các hiệu ứng cùng "id" không cộng dồn: cái mạnh hơn sẽ thay thế,
## cái yếu hơn hoặc bằng chỉ làm mới thời gian.

@export var id: StringName = &"slow"
@export var display_name: String = "Hiệu ứng"
## Thời gian tồn tại (giây).
@export var duration: float = 2.0

@export_group("Làm chậm")
## Tỉ lệ giảm tốc độ (0.4 = chậm đi 40%).
@export_range(0.0, 0.9, 0.05) var slow_amount: float = 0.0

@export_group("Sát thương theo thời gian")
@export var damage_per_second: float = 0.0
@export var damage_type: DamageInfo.Type = DamageInfo.Type.TRUE
## Bao lâu trừ máu một lần (giây).
@export var tick_interval: float = 0.5

@export_group("Hiển thị")
## Màu vòng sáng vẽ quanh địch đang dính hiệu ứng.
@export var tint: Color = Color(0.4, 0.8, 1.0)


## Dùng để so sánh hai hiệu ứng cùng id: số lớn hơn = mạnh hơn.
func get_strength() -> float:
	return slow_amount * 100.0 + damage_per_second
