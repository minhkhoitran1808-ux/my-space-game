class_name AbilityData
extends Resource
## Cấu hình một kỹ năng chủ động của người chơi (Thiên thạch, Băng giá...).
##
## Kỹ năng gây sát thương + hiệu ứng trong một vùng (targeted = true, người chơi click chọn
## vị trí) hoặc lên toàn bộ địch trên bản đồ (radius = 0). Sau khi dùng phải chờ hồi chiêu.

@export var id: StringName = &"meteor"
@export var display_name: String = "Kỹ năng"
@export_multiline var description: String = ""
## Phím tắt kích hoạt.
@export var hotkey: Key = KEY_Q
## Thời gian hồi chiêu (giây).
@export var cooldown: float = 30.0

@export_group("Hiệu quả")
## true = người chơi phải click chọn vị trí; false = dùng ngay.
@export var targeted: bool = true
## Bán kính vùng ảnh hưởng (0 = toàn bộ địch trên bản đồ).
@export var radius: float = 90.0
@export var damage: float = 0.0
@export var damage_type: DamageInfo.Type = DamageInfo.Type.TRUE
@export var effects: Array[StatusEffectData] = []

@export_group("Hiển thị")
@export var color: Color = Color(1.0, 0.5, 0.2)
