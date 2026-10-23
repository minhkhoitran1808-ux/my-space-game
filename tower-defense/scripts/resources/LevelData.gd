class_name LevelData
extends Resource
## Cấu hình một màn chơi: bản đồ, file wave, vàng và máu ban đầu.
##
## Muốn thêm màn: tạo scene bản đồ trong res://scenes/maps/, file wave trong
## res://data/waves/, một LevelData .tres trong res://resources/levels/, rồi thêm nó
## vào mảng "levels" của res://resources/levels/catalog.tres (thứ tự = thứ tự mở khoá).

## Mã định danh, dùng làm khoá khi lưu tiến độ. Phải duy nhất và không nên đổi.
@export var id: StringName = &"level_01"
@export var display_name: String = "Màn chơi"
@export_multiline var description: String = ""
## Scene bản đồ (gốc là GameMap, chứa các Path2D).
@export var map_scene: PackedScene
@export_file("*.json") var waves_file: String = ""
@export var starting_gold: int = 200
@export var starting_lives: int = 20


## Đọc nhanh số wave từ file JSON (để hiển thị ở màn chọn màn).
func get_wave_count() -> int:
	if not FileAccess.file_exists(waves_file):
		return 0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(waves_file))
	if parsed is Dictionary and parsed.get("waves") is Array:
		return parsed.waves.size()
	return 0
