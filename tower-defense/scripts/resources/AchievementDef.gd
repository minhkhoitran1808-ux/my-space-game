class_name AchievementDef
extends Resource
## Định nghĩa một thành tựu (file .tres trong res://resources/achievements/).
##
## Hai cách hoàn thành:
## - Theo bộ đếm: stat_key + target (vd enemies_killed >= 1000). AchievementManager tự kiểm tra
##   mỗi khi bộ đếm đổi.
## - Theo điều kiện đặc biệt: challenge (vd &"perfect_clear"), AchievementManager kiểm tra
##   khi kết thúc ván hoặc khi có sự kiện tương ứng.
## id KHÔNG được đổi sau khi phát hành (là khoá trong file save); đổi title thì thoải mái.

enum Category { MILESTONE, CHALLENGE, DISCOVERY, HIDDEN }

const CATEGORY_NAMES := ["Cột mốc", "Thử thách", "Khám phá", "Ẩn"]

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
@export var category: Category = Category.MILESTONE
## Thứ tự hiển thị trong danh sách (nhỏ trước).
@export var order: int = 0

@export_group("Điều kiện")
## Bộ đếm của StatsManager (để trống nếu dùng challenge).
@export var stat_key: StringName = &""
@export var target: int = 1
## Mã điều kiện đặc biệt (xem AchievementManager.CHALLENGES).
@export var challenge: StringName = &""

@export_group("Phần thưởng")
@export var reward_coins: int = 0
## Danh hiệu nhận được (để trống = không có).
@export var reward_title: String = ""
## Vật phẩm nhận được (id ItemDef, để trống = không có).
@export var reward_item: StringName = &""


func is_hidden() -> bool:
	return category == Category.HIDDEN


## Mô tả phần thưởng cho UI.
func reward_text() -> String:
	var parts := PackedStringArray()
	if reward_coins > 0:
		parts.append("%d Xu" % reward_coins)
	if not reward_title.is_empty():
		parts.append("Danh hiệu \"%s\"" % reward_title)
	if reward_item != &"":
		var item := InventoryManager.get_def(reward_item)
		parts.append(item.display_name if item else String(reward_item))
	return ", ".join(parts)
