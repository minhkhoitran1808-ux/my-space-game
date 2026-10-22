class_name WaveManager
extends Node
## Quản lý việc spawn địch theo từng wave.
##
## Dữ liệu wave đọc từ file JSON (mặc định res://data/waves.json) để chỉnh độ khó
## mà không phải sửa code. Mỗi wave gồm nhiều "group", mỗi group là một loạt địch
## cùng loại được spawn cách nhau "interval" giây.
##
## WaveManager lắng nghe signal của từng Enemy để:
##   - cộng vàng (died) / trừ mạng (reached_end) qua GameManager
##   - biết khi nào wave kết thúc và khi nào thắng.

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int, reward_bonus: int)
signal all_waves_completed
signal enemy_spawned(enemy: Enemy)

@export_file("*.json") var waves_file: String = "res://data/waves.json"
## Path2D mà địch sẽ đi theo (địch được add làm con của node này).
@export var enemy_path: Path2D

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

func _load_waves() -> void:
	if not FileAccess.file_exists(waves_file):
		push_error("WaveManager: không tìm thấy file wave '%s'." % waves_file)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(waves_file))
	if not parsed is Dictionary or not parsed.get("waves") is Array:
		push_error("WaveManager: file '%s' phải có dạng { \"waves\": [ ... ] }." % waves_file)
		return
	_waves = parsed["waves"]


func _build_spawn_queue(wave: Dictionary) -> void:
	_spawn_queue.clear()
	for group: Dictionary in wave.get("groups", []):
		var enemy_path_str: String = group.get("enemy", "")
		var enemy_data := load(enemy_path_str) as EnemyData if ResourceLoader.exists(enemy_path_str) else null
		if enemy_data == null or enemy_data.scene == null:
			push_error("WaveManager: EnemyData không hợp lệ '%s'." % enemy_path_str)
			continue

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
		_spawn_enemy(_spawn_queue.pop_front())

	_is_spawning = false
	_check_wave_completed()


func _spawn_enemy(entry: Dictionary) -> void:
	var enemy_data: EnemyData = entry.data
	var enemy := enemy_data.scene.instantiate() as Enemy
	enemy.setup(enemy_data, entry.health_multiplier, entry.speed_multiplier)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy_path.add_child(enemy)
	_alive_enemies += 1
	enemy_spawned.emit(enemy)


func _on_enemy_died(_enemy: Enemy, reward: int) -> void:
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
