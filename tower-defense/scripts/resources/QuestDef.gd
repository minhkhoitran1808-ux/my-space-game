class_name QuestDef
extends Resource
## Một mẫu nhiệm vụ ngày (file .tres trong res://resources/quests/).
## Tiến độ = bộ đếm stat_key tăng thêm bao nhiêu KỂ TỪ LÚC nhận nhiệm vụ.

@export var id: StringName = &""
## Mô tả; "{target}" được thay bằng mục tiêu.
@export var description: String = ""
@export var stat_key: StringName = &""
@export var target: int = 1
@export var reward_coins: int = 0
@export var reward_exp: int = 0


func get_text() -> String:
	return description.replace("{target}", str(target))
