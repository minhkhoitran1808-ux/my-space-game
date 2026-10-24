class_name ItemDef
extends Resource
## Định nghĩa một vật phẩm meta (file .tres trong res://resources/items/).
##
## - SKIN: chỉ đổi ngoại hình một loại tháp (không tăng sức mạnh). Mỗi skin chỉ sở hữu 1;
##   nhận trùng thì tự đổi thành Bụi.
## - CONSUMABLE: dùng một lần cho ván kế tiếp (chuẩn bị ở Kho đồ), vd +vàng / +máu đầu ván.
## - MATERIAL: nguyên liệu cho thương nhân / ghép đồ.
## id KHÔNG được đổi sau khi phát hành (là khoá trong file save).

enum Kind { SKIN, CONSUMABLE, MATERIAL }
## Hoạ tiết vẽ thêm lên tháp khi dùng skin.
enum Pattern { NONE, RING, STRIPES, STAR, GLOW }

const KIND_NAMES := ["Skin tháp", "Tiêu hao", "Nguyên liệu"]

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: Kind = Kind.MATERIAL
@export var rarity: Rarity.Tier = Rarity.Tier.COMMON
## Gợi ý nguồn nhận (hiện trong chi tiết vật phẩm / Codex).
@export var source_hint: String = "Rơi cuối ván"
## Có thể rơi ngẫu nhiên cuối ván không (đồ độc quyền của thành tựu: false).
@export var droppable: bool = true
## Đổi được với thương nhân NPC. (Trao đổi giữa người chơi: chưa hỗ trợ, luôn false.)
@export var tradeable_npc: bool = true
@export var tradeable_p2p: bool = false

@export_group("Skin")
## Tháp áp dụng (TowerData.id), chỉ với SKIN.
@export var tower_id: StringName = &""
@export var skin_color: Color = Color.WHITE
@export var skin_accent: Color = Color.BLACK
@export var pattern: Pattern = Pattern.NONE

@export_group("Tiêu hao")
## Hiệu ứng: &"bonus_gold_pct" (cộng % vàng đầu ván) hoặc &"bonus_lives" (cộng máu nhà chính).
@export var effect: StringName = &""
@export var effect_value: float = 0.0


func is_stackable() -> bool:
	return kind != Kind.SKIN


## Mô tả hiệu ứng ngắn cho UI.
func effect_text() -> String:
	match effect:
		&"bonus_gold_pct":
			return "+%d%% vàng đầu ván" % roundi(effect_value)
		&"bonus_lives":
			return "+%d máu nhà chính" % roundi(effect_value)
	return ""
