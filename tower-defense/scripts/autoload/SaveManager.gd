extends Node
## SaveManager (Autoload): lưu tiến độ người chơi vào user://save.cfg.
##
## Lưu số sao tốt nhất của từng màn (theo LevelData.id), kỷ lục chế độ vô tận,
## cờ trạng thái (vd đã xem hướng dẫn) và cài đặt người chơi.
## Màn đầu luôn mở; màn sau mở khi màn trước đã có ít nhất 1 sao.
## File nằm ở thư mục dữ liệu người dùng của Godot (Project > Open User Data Folder).

signal progress_changed
## Phát ra khi một cài đặt thay đổi.
signal settings_changed(key: String, value: Variant)

const SECTION_STARS := "stars"
const SECTION_ENDLESS := "endless_best_wave"
const SECTION_FLAGS := "flags"
const SECTION_SETTINGS := "settings"

## Giá trị mặc định của các cài đặt.
const DEFAULT_SETTINGS := {
	"master_volume": 0.8,
	"damage_numbers": true,
	"screen_shake": true,
	"fullscreen": false,
}

## Đổi được (vd test dùng file riêng để không ghi đè tiến độ thật).
var save_path: String = "user://save.cfg":
	set(value):
		save_path = value
		_load()

var _config := ConfigFile.new()


func _ready() -> void:
	_load()
	apply_settings()


func get_stars(level_id: StringName) -> int:
	return int(_config.get_value(SECTION_STARS, String(level_id), 0))


## Ghi kết quả một màn; chỉ giữ lại số sao cao nhất.
func record_result(level_id: StringName, stars: int) -> void:
	if stars <= get_stars(level_id):
		return
	_config.set_value(SECTION_STARS, String(level_id), stars)
	_save()
	progress_changed.emit()


## Kỷ lục chế độ vô tận của một màn (wave cao nhất đã tới).
func get_endless_best(level_id: StringName) -> int:
	return int(_config.get_value(SECTION_ENDLESS, String(level_id), 0))


## Ghi kết quả vô tận; trả về true nếu là kỷ lục mới.
func record_endless(level_id: StringName, wave_reached: int) -> bool:
	if wave_reached <= get_endless_best(level_id):
		return false
	_config.set_value(SECTION_ENDLESS, String(level_id), wave_reached)
	_save()
	progress_changed.emit()
	return true


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


## Xoá tiến độ (sao, kỷ lục, cờ hướng dẫn). Cài đặt được giữ nguyên.
func reset_progress() -> void:
	for section in [SECTION_STARS, SECTION_ENDLESS, SECTION_FLAGS]:
		if _config.has_section(section):
			_config.erase_section(section)
	_save()
	progress_changed.emit()


# --- Cờ trạng thái ----------------------------------------------------------------

func get_flag(flag: String) -> bool:
	return bool(_config.get_value(SECTION_FLAGS, flag, false))


func set_flag(flag: String, value: bool) -> void:
	_config.set_value(SECTION_FLAGS, flag, value)
	_save()


# --- Cài đặt ------------------------------------------------------------------------

func get_setting(key: String) -> Variant:
	return _config.get_value(SECTION_SETTINGS, key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	_config.set_value(SECTION_SETTINGS, key, value)
	_save()
	_apply_setting(key, value)
	settings_changed.emit(key, value)


## Áp dụng mọi cài đặt (gọi khi khởi động).
func apply_settings() -> void:
	for key: String in DEFAULT_SETTINGS:
		_apply_setting(key, get_setting(key))


## Cài đặt nào cần tác động trực tiếp lên engine thì xử lý ở đây; những cài đặt khác
## (số sát thương, rung màn hình) do hệ thống liên quan tự đọc qua get_setting().
func _apply_setting(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(value), 0.0001)))
		"fullscreen":
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value
						else DisplayServer.WINDOW_MODE_WINDOWED)


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
