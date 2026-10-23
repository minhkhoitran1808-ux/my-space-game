extends Node
## SaveManager (Autoload): lưu tiến độ người chơi vào user://save.cfg.
##
## Lưu số sao tốt nhất của từng màn (theo LevelData.id). Màn đầu luôn mở;
## màn sau mở khi màn trước đã có ít nhất 1 sao.
## File nằm ở thư mục dữ liệu người dùng của Godot (Project > Open User Data Folder).

signal progress_changed

const SECTION_STARS := "stars"

## Đổi được (vd test dùng file riêng để không ghi đè tiến độ thật).
var save_path: String = "user://save.cfg":
	set(value):
		save_path = value
		_load()

var _config := ConfigFile.new()


func _ready() -> void:
	_load()


func get_stars(level_id: StringName) -> int:
	return int(_config.get_value(SECTION_STARS, String(level_id), 0))


## Ghi kết quả một màn; chỉ giữ lại số sao cao nhất.
func record_result(level_id: StringName, stars: int) -> void:
	if stars <= get_stars(level_id):
		return
	_config.set_value(SECTION_STARS, String(level_id), stars)
	_save()
	progress_changed.emit()


func is_level_unlocked(catalog: LevelCatalog, index: int) -> bool:
	if index <= 0:
		return true
	return get_stars(catalog.levels[index - 1].id) > 0


func get_total_stars() -> int:
	var total := 0
	if _config.has_section(SECTION_STARS):
		for key in _config.get_section_keys(SECTION_STARS):
			total += int(_config.get_value(SECTION_STARS, key, 0))
	return total


## Xoá toàn bộ tiến độ.
func reset_progress() -> void:
	_config.clear()
	_save()
	progress_changed.emit()


func _load() -> void:
	_config = ConfigFile.new()
	if FileAccess.file_exists(save_path):
		var error := _config.load(save_path)
		if error != OK:
			push_warning("SaveManager: không đọc được '%s' (lỗi %d), bắt đầu tiến độ mới." % [save_path, error])
			_config = ConfigFile.new()


func _save() -> void:
	var error := _config.save(save_path)
	if error != OK:
		push_error("SaveManager: không ghi được '%s' (lỗi %d)." % [save_path, error])
