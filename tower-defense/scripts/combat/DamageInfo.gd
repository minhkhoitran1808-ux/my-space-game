class_name DamageInfo
extends RefCounted
## Gói thông tin của MỘT lần gây sát thương.
##
## Truyền nguyên gói này cho Enemy.take_damage() thay vì một con số trần,
## để địch tự tính kháng (giáp / kháng phép) và nhận hiệu ứng kèm theo.

enum Type {
	PHYSICAL, ## Vật lý: bị giảm bởi armor.
	MAGIC, ## Phép: bị giảm bởi magic_resist.
	TRUE, ## Chuẩn: bỏ qua mọi kháng (dùng cho thiêu đốt...).
}

## Lượng sát thương trước khi tính kháng.
var amount: float = 0.0
var type: Type = Type.PHYSICAL
## Node gây ra sát thương (thường là Tower). Có thể null.
var source: Node = null
## Hiệu ứng trạng thái gắn kèm cú đánh (làm chậm, thiêu đốt...).
var effects: Array[StatusEffectData] = []
## true nếu là sát thương theo thời gian (thiêu đốt...), để UI hiển thị nhỏ hơn.
var is_periodic: bool = false
## false = đòn đánh mặt đất, nổ lan không trúng địch bay.
var hits_air: bool = true


func _init(p_amount: float = 0.0, p_type: Type = Type.PHYSICAL, p_source: Node = null) -> void:
	amount = p_amount
	type = p_type
	source = p_source


static func type_name(damage_type: Type) -> String:
	match damage_type:
		Type.MAGIC:
			return "Phép"
		Type.TRUE:
			return "Chuẩn"
		_:
			return "Vật lý"
