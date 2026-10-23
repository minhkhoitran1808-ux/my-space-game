class_name WaveManager
extends Node
## Quản lý việc spawn địch theo từng wave.
##
## Dữ liệu wave đọc từ file JSON (mặc định res://data/waves.json) để chỉnh độ khó
## mà không phải sửa code. Mỗi wave gồm nhiều "group", mỗi group là một loạt địch
## cùng loại được spawn cách nhau "interval" giây. Loại địch ghi bằng "id"
## (khớp EnemyData.id của các file .tres trong enemies_folder).
##
## WaveManager lắng nghe signal của từng Enemy để:
##   - cộng vàng (died) / trừ mạng (reached_end) qua GameManager
##   - sinh địch con khi một địch có spawn_on_death chết
##   - biết khi nào wave kết thúc và khi nào thắng.

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int, reward_bonus: int)
signal all_waves_completed
signal enemy_spawned(enemy: Enemy)

@export_file("*.json") var waves_file: String = "res://data/waves.json"
## Thư mục chứa các file EnemyData (.tres). Được quét tự động khi khởi động.
@export_dir var enemies_folder: String = "res://resources/enemies"
## Path2D mà địch sẽ đi theo (địch được add làm con của node này).
@export var enemy_path: Path2D

## Khoảng cách (pixel trên đường đi) giữa các địch con sinh ra khi địch mẹ chết.
const DEATH_SPAWN_SPACING := 14.0

var _enemy_types: Dictionary = {} # StringName id -> EnemyData
var _waves: Array = []
var _current_wave_index := -1
## Hàng đợi spawn của wave hiện tại. Mỗi phần tử:
## { data: EnemyData, delay: float, health_multiplier: float, speed_multiplier: float }
var _spawn_queue: Array[Dictionary] = []
var _alive_enemies := 0
var _is_spawning := false
var _spawn_timer: Timer


func _ready() -> void:
	# Dùng Timer con (thay vì await create_timer) để tự dừng khi pause
	# và tự huỷ cùng scene khi chơi lại.
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_process_spawn_queue)
	add_child(_spawn_timer)
	_load_enemy_types()
	_load_waves()


# --- API công khai --------------------------------------------------------------

func get_total_waves() -> int:
	return _waves.size()


## Số thứ tự wave hiện tại (bắt đầu từ 1, 0 = chưa bắt đầu).
func get_current_wave_number() -> int:
	return _current_wave_index + 1


func has_more_waves() -> bool:
	return _current_wave_index + 1 < _waves.size()


func is_wave_in_progress() -> bool:
	return _is_spawning or _alive_enemies > 0


func can_start_next_wave() -> bool:
	return GameManager.is_playing() and not is_wave_in_progress() and has_more_waves()


func get_enemy_type(id: StringName) -> EnemyData:
	return _enemy_types.get(id)


## Bắt đầu wave tiếp theo. Trả về false nếu chưa thể bắt đầu.
func start_next_wave() -> bool:
	if not can_start_next_wave():
		return false
	_current_wave_index += 1
	GameManager.set_current_wave(get_current_wave_number())
	_build_spawn_queue(_waves[_current_wave_index])
	_is_spawning = true
	wave_started.emit(get_current_wave_number())
	_process_spawn_queue()
	return true


# --- Đọc dữ liệu ----------------------------------------------------------------

## Quét enemies_folder và lập bảng id -> EnemyData.
func _load_enemy_types() -> void:
	# list_directory xử lý được cả file đã bị đổi tên khi export (.remap).
	for file_name in ResourceLoader.list_directory(enemies_folder):
		if not (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			continue
		var enemy_data := load(enemies_folder.path_join(file_name)) as EnemyData
		if enemy_data == null:
			continue
		if _enemy_types.has(enemy_data.id):
			push_error("WaveManager: trùng id địch '%s' (%s)." % [enemy_data.id, file_name])
		_enemy_types[enemy_data.id] = enemy_data


func _load_waves() -> void:
	if not FileAccess.file_exists(waves_file):
		push_error("WaveManager: không tìm thấy file wave '%s'." % waves_file)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(waves_file))
	if not parsed is Dictionary or not parsed.get("waves") is Array:
		push_error("WaveManager: file '%s' phải có dạng { \"waves\": [ ... ] }." % waves_file)
		return
	_waves = parsed["waves"]
	for error in validate_waves():
		push_error("WaveManager (%s): %s" % [waves_file, error])


## Kiểm tra dữ liệu wave, trả về danh sách lỗi dễ đọc (rỗng = hợp lệ).
func validate_waves() -> PackedStringArray:
	var errors := PackedStringArray()
	for wave_index in _waves.size():
		var wave: Variant = _waves[wave_index]
		var where := "wave %d" % (wave_index + 1)
		if not wave is Dictionary or not wave.get("groups") is Array or wave.groups.is_empty():
			errors.append("%s: thiếu mảng \"groups\"." % where)
			continue
		for group_index in wave.groups.size():
			var group: Variant = wave.groups[group_index]
			var group_where := "%s, group %d" % [where, group_index + 1]
			if not group is Dictionary:
				errors.append("%s: phải là một object." % group_where)
				continue
			if _resolve_enemy(str(group.get("enemy", ""))) == null:
				errors.append("%s: không có địch với id \"%s\". Có các id: %s." \
						% [group_where, group.get("enemy", ""), ", ".join(_enemy_types.keys())])
			if int(group.get("count", 1)) <= 0:
				errors.append("%s: \"count\" phải > 0." % group_where)
	return errors


## Nhận id (vd "fast") hoặc đường dẫn res:// tới file .tres.
func _resolve_enemy(key: String) -> EnemyData:
	if key.begins_with("res://"):
		return load(key) as EnemyData if ResourceLoader.exists(key) else null
	return _enemy_types.get(StringName(key))


func _build_spawn_queue(wave: Dictionary) -> void:
	_spawn_queue.clear()
	for group: Dictionary in wave.get("groups", []):
		var enemy_data := _resolve_enemy(str(group.get("enemy", "")))
		if enemy_data == null or enemy_data.scene == null:
			continue # Lỗi đã được báo lúc validate.

		var count := int(group.get("count", 1))
		var interval := float(group.get("interval", 1.0))
		var delay := float(group.get("delay", 0.0))
		for i in count:
			_spawn_queue.append({
				"data": enemy_data,
				# Con đầu tiên của group chờ "delay", các con sau chờ "interval".
				"delay": delay if i == 0 else interval,
				"health_multiplier": float(group.get("health_multiplier", 1.0)),
				"speed_multiplier": float(group.get("speed_multiplier", 1.0)),
			})


# --- Spawn ----------------------------------------------------------------------

## Spawn tất cả địch đã tới lượt; nếu phần tử kế tiếp cần chờ thì hẹn Timer.
func _process_spawn_queue() -> void:
	while not _spawn_queue.is_empty():
		var next: Dictionary = _spawn_queue[0]
		if next.delay > 0.0:
			_spawn_timer.start(next.delay)
			next.delay = 0.0 # Lần gọi tiếp theo (khi Timer hết giờ) sẽ spawn ngay.
			return
		var entry: Dictionary = _spawn_queue.pop_front()
		_spawn_enemy(entry.data, entry.health_multiplier, entry.speed_multiplier)

	_is_spawning = false
	_check_wave_completed()


func _spawn_enemy(enemy_data: EnemyData, health_multiplier: float, speed_multiplier: float,
		start_progress: float = 0.0) -> Enemy:
	var enemy := enemy_data.scene.instantiate() as Enemy
	enemy.setup(enemy_data, health_multiplier, speed_multiplier)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy_path.add_child(enemy)
	enemy.progress = start_progress
	_alive_enemies += 1
	enemy_spawned.emit(enemy)
	return enemy


func _on_enemy_died(enemy: Enemy, reward: int) -> void:
	# Sinh địch con TRƯỚC khi giảm bộ đếm để wave không bị coi là đã xong.
	var child_data := enemy.data.spawn_on_death
	if child_data and child_data.scene:
		for i in enemy.data.spawn_on_death_count:
			_spawn_enemy(child_data, enemy.health_multiplier, 1.0,
					maxf(enemy.progress - i * DEATH_SPAWN_SPACING, 0.0))

	_alive_enemies -= 1
	GameManager.add_gold(reward)
	_check_wave_completed()


func _on_enemy_reached_end(_enemy: Enemy, damage: int) -> void:
	_alive_enemies -= 1
	GameManager.lose_lives(damage)
	_check_wave_completed()


func _check_wave_completed() -> void:
	if is_wave_in_progress() or not GameManager.is_playing():
		return
	var wave_number := get_current_wave_number()
	var bonus := int(_waves[_current_wave_index].get("reward_bonus", 0))
	GameManager.add_gold(bonus)
	wave_completed.emit(wave_number, bonus)
	if not has_more_waves():
		all_waves_completed.emit()
		GameManager.win()
