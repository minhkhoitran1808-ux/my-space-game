extends Node
## SaveManager (Autoload): lưu tiến độ người chơi và cài đặt.
##
## Hai file riêng:
## - Cài đặt (âm lượng, hiển thị...) -> ConfigFile `user://save.cfg` (save_path).
## - Hồ sơ người chơi (sao, kỷ lục, cờ, xu, cấp, thành tựu, kho đồ...) -> JSON
##   `user://save.profile.json` (profile_path, suy ra từ save_path).
##   Dùng JSON chứ không dùng Resource: file Resource có thể chứa script, không an toàn khi
##   người chơi chia sẻ / sửa save. JSON có "save_version" + hàm _migrate() để nâng cấp save cũ.
##
## Ghi an toàn: ghi ra file .tmp, chuyển file chính cũ thành .bak, rồi đổi tên .tmp thành file
## chính. Đọc lỗi thì tự lấy lại từ .bak. Save cũ (tiến độ nằm trong save.cfg) được chuyển
## sang hồ sơ JSON ở lần chạy đầu tiên.
##
## Các manager meta (Economy, Stats, Progression, Achievements, Inventory...) không giữ bản sao:
## chúng đọc / ghi thẳng vào section() của hồ sơ rồi gọi request_save(). Nhờ vậy "Xoá tiến độ"
## hay nạp lại hồ sơ không bao giờ để sót dữ liệu cũ trong bộ nhớ.
## request_save() chỉ đánh dấu và gộp mọi yêu cầu trong cùng frame thành một lần ghi.
##
## Màn đầu luôn mở; màn sau mở khi màn trước đã có ít nhất 1 sao.

## Tiến độ / hồ sơ thay đổi (UI menu nghe để vẽ lại).
signal progress_changed
## Phát ra khi một cài đặt thay đổi.
signal settings_changed(key: String, value: Variant)

const PROFILE_VERSION := 2
const SECTION_SETTINGS := "settings"
## Các section tiến độ của định dạng cũ (save.cfg), chỉ dùng khi chuyển sang JSON.
const LEGACY_SECTIONS := {"stars": "stars", "endless_best_wave": "endless_best", "flags": "flags"}

## Giá trị mặc định của các cài đặt.
const DEFAULT_SETTINGS := {
	"master_volume": 0.8,
	"damage_numbers": true,
	"screen_shake": true,
	"fullscreen": false,
	# Hiển thị / hỗ trợ người chơi (xem VisualSettings).
	"reduced_motion": false,
	"hit_flash": VisualSettings.HitFlash.ON,
	"health_bar_mode": VisualSettings.HealthBarMode.DAMAGED_ONLY,
	"colorblind": false,
	"view_3d": true,
	"shadows_3d": true,
}

## Đổi được (vd test dùng file riêng để không ghi đè tiến độ thật). Đổi là nạp lại cả hai file.
var save_path: String = "user://save.cfg":
	set(value):
		save_path = value
		_load()

## File hồ sơ JSON (suy ra từ save_path: "user://save.cfg" -> "user://save.profile.json").
var profile_path: String:
	get:
		return save_path.get_basename() + ".profile.json"

## Toàn bộ hồ sơ người chơi (Dictionary thuần, ghi ra JSON).
var profile: Dictionary = {}

var _config := ConfigFile.new()
var _save_pending := false


func _ready() -> void:
	_load()
	apply_settings()


func _notification(what: int) -> void:
	# Đóng cửa sổ khi còn yêu cầu lưu chưa ghi: ghi ngay.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if _save_pending:
			flush()


# --- Hồ sơ: truy cập chung ----------------------------------------------------------

## Một nhánh của hồ sơ (tạo rỗng nếu chưa có). Sửa Dictionary trả về rồi gọi request_save().
func section(name: String) -> Dictionary:
	if not profile.has(name) or not profile[name] is Dictionary:
		profile[name] = {}
	return profile[name]


## Đọc số nguyên từ Dictionary của hồ sơ (JSON trả mọi số về float nên luôn ép int).
static func read_int(dict: Dictionary, key: Variant, default: int = 0) -> int:
	var value: Variant = dict.get(key, default)
	return int(value) if value is float or value is int else default


## Đánh dấu cần lưu; mọi yêu cầu trong cùng frame được gộp thành một lần ghi.
func request_save() -> void:
	if _save_pending:
		return
	_save_pending = true
	flush.call_deferred()


## Ghi hồ sơ xuống đĩa ngay (an toàn: .tmp -> đổi tên, giữ .bak).
func flush() -> void:
	_save_pending = false
	profile["save_version"] = PROFILE_VERSION
	var tmp_path := profile_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: không ghi được '%s' (lỗi %d)." % [tmp_path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(profile, "\t"))
	file.close()
	var main_path := ProjectSettings.globalize_path(profile_path)
	var backup_path := main_path + ".bak"
	if FileAccess.file_exists(profile_path):
		if FileAccess.file_exists(profile_path + ".bak"):
			DirAccess.remove_absolute(backup_path)
		DirAccess.rename_absolute(main_path, backup_path)
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp_path), main_path)
	if error != OK:
		push_error("SaveManager: không đổi tên file lưu (lỗi %d)." % error)


## Xoá toàn bộ hồ sơ (sao, kỷ lục, cờ, xu, cấp, thành tựu, kho đồ...). Cài đặt được giữ nguyên.
func reset_progress() -> void:
	profile = _new_profile()
	flush()
	progress_changed.emit()
	Events.claimables_changed.emit()


# --- Sao + kỷ lục + cờ ------------------------------------------------------------------

## Sao tốt nhất của một màn, tính trên MỌI độ khó (dùng để mở màn sau).
func get_stars(level_id: StringName) -> int:
	var best := 0
	for difficulty in GameManager.Difficulty.size():
		best = maxi(best, get_stars_for(level_id, difficulty))
	return best


## Sao tốt nhất của một màn ở một độ khó.
func get_stars_for(level_id: StringName, difficulty: int) -> int:
	return read_int(section("stars"), _stars_key(level_id, difficulty))


## Ghi kết quả một màn; chỉ giữ lại số sao cao nhất của độ khó đó.
func record_result(level_id: StringName, stars: int, difficulty: int = GameManager.Difficulty.NORMAL) -> void:
	if stars <= get_stars_for(level_id, difficulty):
		return
	section("stars")[_stars_key(level_id, difficulty)] = stars
	request_save()
	progress_changed.emit()


static func _stars_key(level_id: StringName, difficulty: int) -> String:
	return "%s:%d" % [level_id, difficulty]


## Kỷ lục chế độ vô tận của một màn (wave cao nhất đã tới).
func get_endless_best(level_id: StringName) -> int:
	return read_int(section("endless_best"), String(level_id))


## Ghi kết quả vô tận; trả về true nếu là kỷ lục mới.
func record_endless(level_id: StringName, wave_reached: int) -> bool:
	if wave_reached <= get_endless_best(level_id):
		return false
	section("endless_best")[String(level_id)] = wave_reached
	request_save()
	progress_changed.emit()
	return true


func is_level_unlocked(catalog: LevelCatalog, index: int) -> bool:
	if index <= 0:
		return true
	return get_stars(catalog.levels[index - 1].id) > 0


## Tổng sao (mỗi màn tính mức sao tốt nhất trên mọi độ khó).
func get_total_stars() -> int:
	var best_by_level := {}
	for key: String in section("stars"):
		var level_id := key.get_slice(":", 0)
		best_by_level[level_id] = maxi(best_by_level.get(level_id, 0), read_int(section("stars"), key))
	var total := 0
	for value: int in best_by_level.values():
		total += value
	return total


func get_flag(flag: String) -> bool:
	return bool(section("flags").get(flag, false))


func set_flag(flag: String, value: bool) -> void:
	section("flags")[flag] = value
	request_save()


# --- Cài đặt ------------------------------------------------------------------------

func get_setting(key: String) -> Variant:
	return _config.get_value(SECTION_SETTINGS, key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	_config.set_value(SECTION_SETTINGS, key, value)
	_save_config()
	_apply_setting(key, value)
	settings_changed.emit(key, value)


## Áp dụng mọi cài đặt (gọi khi khởi động).
func apply_settings() -> void:
	for key: String in DEFAULT_SETTINGS:
		_apply_setting(key, get_setting(key))


## Cài đặt nào cần tác động trực tiếp lên engine thì xử lý ở đây; những cài đặt khác
## (số sát thương, rung màn hình) do hệ thống liên quan tự đọc qua get_setting().
func _apply_setting(key: String, value: Variant) -> void:
	VisualSettings.apply(key, value)
	match key:
		"master_volume":
			AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(value), 0.0001)))
		"fullscreen":
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value
						else DisplayServer.WINDOW_MODE_WINDOWED)


# --- Đọc / ghi file ---------------------------------------------------------------------

func _new_profile() -> Dictionary:
	return {"save_version": PROFILE_VERSION}


func _load() -> void:
	_save_pending = false
	_config = ConfigFile.new()
	if FileAccess.file_exists(save_path):
		var error := _config.load(save_path)
		if error != OK:
			push_warning("SaveManager: không đọc được '%s' (lỗi %d), dùng cài đặt mặc định." % [save_path, error])
			_config = ConfigFile.new()

	var loaded: Variant = _read_json(profile_path)
	var recovered := false
	if loaded == null and FileAccess.file_exists(profile_path + ".bak"):
		loaded = _read_json(profile_path + ".bak")
		recovered = loaded != null
		if recovered:
			push_warning("SaveManager: hồ sơ hỏng hoặc thiếu, đã khôi phục từ bản dự phòng.")
	if loaded is Dictionary:
		profile = _migrate(loaded)
		if recovered:
			# Bỏ file chính hỏng trước, để flush() không biến nó thành bản dự phòng.
			DirAccess.remove_absolute(ProjectSettings.globalize_path(profile_path))
			flush()
	else:
		profile = _new_profile()
		if _import_legacy_progress():
			flush()


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	# JSON.new().parse() không in lỗi ra console như JSON.parse_string().
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return json.data if json.data is Dictionary else null


## Nâng cấp hồ sơ từ phiên bản cũ lên PROFILE_VERSION (mỗi phiên bản thêm một bước).
func _migrate(data: Dictionary) -> Dictionary:
	var version := read_int(data, "save_version", 0)
	if version > PROFILE_VERSION:
		push_warning("SaveManager: hồ sơ từ phiên bản mới hơn (%d), có thể thiếu dữ liệu." % version)
	if version < 2:
		# v2: sao lưu theo độ khó ("level_01:1"); sao cũ tính là độ khó Thường.
		data["stars"] = _stars_to_v2(data.get("stars", {}))
	data["save_version"] = PROFILE_VERSION
	return data


static func _stars_to_v2(old: Variant) -> Dictionary:
	var converted := {}
	if old is Dictionary:
		for key: String in old:
			converted[key if ":" in key else _stars_key(StringName(key), GameManager.Difficulty.NORMAL)] = old[key]
	return converted


## Chuyển sao / kỷ lục / cờ từ save.cfg kiểu cũ sang hồ sơ JSON. Trả về true nếu có dữ liệu.
func _import_legacy_progress() -> bool:
	var imported := false
	for legacy_section: String in LEGACY_SECTIONS:
		if not _config.has_section(legacy_section):
			continue
		var target := section(LEGACY_SECTIONS[legacy_section])
		for key in _config.get_section_keys(legacy_section):
			target[key] = _config.get_value(legacy_section, key)
		_config.erase_section(legacy_section)
		imported = true
	if imported:
		profile["stars"] = _stars_to_v2(section("stars")) # save.cfg cũ chưa có độ khó => Thường.
		_save_config()
	return imported


func _save_config() -> void:
	var error := _config.save(save_path)
	if error != OK:
		push_error("SaveManager: không ghi được '%s' (lỗi %d)." % [save_path, error])
