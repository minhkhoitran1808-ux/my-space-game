class_name WaveManager
extends Node
## Quản lý việc spawn địch theo từng wave.
##
## Dữ liệu wave đọc từ file JSON (mỗi màn một file trong res://data/waves/) để chỉnh
## độ khó mà không phải sửa code. Mỗi wave gồm nhiều "group", mỗi group là một loạt địch
## cùng loại được spawn cách nhau "interval" giây. Loại địch ghi bằng "id"
## (khớp EnemyData.id của các file .tres trong enemies_folder).
##
## Bản đồ có nhiều làn: group có "path": <số thứ tự làn, từ 0> thì địch đi làn đó,
## không ghi thì địch lần lượt chia đều vào các làn.
##
## WaveManager lắng nghe signal của từng Enemy để:
##   - cộng vàng (died) / trừ mạng (reached_end) qua GameManager
##   - sinh địch con khi một địch có spawn_on_death chết
##   - biết khi nào wave kết thúc và khi nào thắng.
##
## Gọi wave sớm: khi wave hiện tại đã spawn xong (nhưng địch còn trên đường), người chơi
## được gọi wave tiếp theo và nhận thưởng thêm. Vì vậy số địch còn sống được đếm
## RIÊNG cho từng wave; mỗi wave báo hoàn thành khi địch của chính nó chết hết.
##
## Địch bay (EnemyData.is_flying) đi theo các làn trên không (air_paths).
## Chế độ vô tận (endless = true): không đọc file, wave được WaveGenerator sinh dần, không bao giờ hết.

signal wave_started(wave_number: int)
## Phát ra khi wave đã spawn hết địch (địch có thể vẫn còn trên đường).
signal spawning_finished(wave_number: int)
signal wave_completed(wave_number: int, reward_bonus: int)
## Phát ra khi người chơi gọi wave sớm, kèm vàng thưởng.
signal wave_called_early(wave_number: int, bonus: int)
signal all_waves_completed
signal enemy_spawned(enemy: Enemy)
## Đếm ngược giữa wave đổi sang giây mới (0 = hết đếm ngược).
signal countdown_changed(seconds_left: int)

## Thư mục chứa các file EnemyData (.tres). Được quét tự động khi khởi động.
@export_dir var enemies_folder: String = "res://resources/enemies"

var waves_file: String = ""
## Các làn đường (Path2D); địch được add làm con của làn nó đi.
var paths: Array[Path2D] = []
## Làn trên không cho địch bay.
var air_paths: Array[Path2D] = []
## Chế độ vô tận: wave sinh tự động, không có chiến thắng.
var endless: bool = false
## Khoá seed cho WaveGenerator (thường là id màn) để chế độ vô tận lặp lại được.
var endless_seed: String = ""

## Khoảng cách (pixel trên đường đi) giữa các địch con sinh ra khi địch mẹ chết.
const DEATH_SPAWN_SPACING := 14.0
## Vàng hạ địch tăng thêm chừng này mỗi wave (máu địch tăng nhanh hơn => không lăn cầu tuyết).
const REWARD_GROWTH_PER_WAVE := 0.03
## Thưởng gọi sớm = EARLY_CALL_BASE_BONUS + EARLY_CALL_BONUS_PER_WAVE * số thứ tự wave được gọi.
## Nghỉ giữa hai wave (giây). Hết giờ thì wave sau tự bắt đầu (nếu auto_start_waves).
const DEFAULT_INTERMISSION := 20.0
## Thưởng hết wave khi file wave không ghi "reward_bonus": 15 + 3 × số thứ tự wave.
const CLEAR_BONUS_BASE := 15
const CLEAR_BONUS_PER_WAVE := 3

## Bản đồ (để địch biết đang đi qua bùn). Main gán; có thể null.
var map: GameMap = null
## Đếm ngược giữa wave: tự gọi wave sau khi hết giờ. Smoke-test bot tắt để tự quyết khi nào gọi.
var auto_start_waves := true
var intermission_time := DEFAULT_INTERMISSION

var _enemy_types: Dictionary = {} # StringName id -> EnemyData
var _waves: Array = []
var _current_wave_index := -1
## Hàng đợi spawn của wave hiện tại. Mỗi phần tử:
## { data, delay, health_multiplier, speed_multiplier, path_index }
var _spawn_queue: Array[Dictionary] = []
## Số địch còn sống của từng wave đang diễn ra: wave_index -> int.
var _alive_by_wave: Dictionary = {}
## Wave đang spawn (-1 = không có wave nào đang spawn).
var _spawning_wave_index := -1
## Bộ đếm để chia đều địch vào các làn khi group không ghi "path".
var _next_path_index := 0
var _spawn_timer: Timer
## Đếm ngược tới wave sau (chạy sau khi một wave sinh xong địch).
var _intermission_timer: Timer
var _last_countdown_second := -1


func _ready() -> void:
	# Dùng Timer con (thay vì await create_timer) để tự dừng khi pause
	# và tự huỷ cùng scene khi chơi lại.
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_process_spawn_queue)
	add_child(_spawn_timer)
	_intermission_timer = Timer.new()
	_intermission_timer.one_shot = true
	_intermission_timer.timeout.connect(_on_intermission_timeout)
	add_child(_intermission_timer)
	_load_enemy_types()


## Main gọi sau khi nạp bản đồ: gán file wave + các làn đường (mặt đất và trên không).
func setup(p_waves_file: String, p_paths: Array[Path2D], p_air_paths: Array[Path2D]) -> void:
	waves_file = p_waves_file
	paths = p_paths
	air_paths = p_air_paths
	_load_waves()


## Bật chế độ vô tận (gọi thay cho setup()).
func setup_endless(seed_key: String, p_paths: Array[Path2D], p_air_paths: Array[Path2D]) -> void:
	paths = p_paths
	air_paths = p_air_paths
	endless = true
	endless_seed = seed_key
	_waves.clear()


# --- API công khai --------------------------------------------------------------

## Tổng số wave (0 trong chế độ vô tận).
func get_total_waves() -> int:
	return 0 if endless else _waves.size()


## Số thứ tự wave hiện tại (bắt đầu từ 1, 0 = chưa bắt đầu).
func get_current_wave_number() -> int:
	return _current_wave_index + 1


func has_more_waves() -> bool:
	return endless or _current_wave_index + 1 < _waves.size()


func is_spawning() -> bool:
	return _spawning_wave_index >= 0


func is_wave_in_progress() -> bool:
	return is_spawning() or not _alive_by_wave.is_empty()


func get_alive_enemy_count() -> int:
	var total := 0
	for count: int in _alive_by_wave.values():
		total += count
	return total


## Được bắt đầu wave mới khi không còn wave nào đang spawn
## (địch của wave trước vẫn còn trên đường thì tính là gọi sớm).
func can_start_next_wave() -> bool:
	return GameManager.is_playing() and not is_spawning() and has_more_waves()


## Bắt đầu wave tiếp theo lúc này có phải là gọi sớm không (đang đếm ngược giữa wave).
func is_early_call() -> bool:
	return get_countdown() > 0.0


## Số giây còn lại tới khi wave sau tự bắt đầu (0 = không đếm ngược, vd trước wave 1).
func get_countdown() -> float:
	return _intermission_timer.time_left if _intermission_timer and not _intermission_timer.is_stopped() else 0.0


## Vàng thưởng nếu gọi sớm wave tiếp theo ngay bây giờ = số giây còn lại (làm tròn lên).
## (Main cũng giảm hồi chiêu kỹ năng đúng chừng ấy giây.)
func get_early_call_bonus() -> int:
	return ceili(get_countdown())


## Nhãn "wave kiểm tra" của wave số `wave_number` (rỗng nếu là wave thường).
func get_wave_label(wave_number: int) -> String:
	if endless or wave_number < 1 or wave_number > _waves.size():
		return ""
	return str(_waves[wave_number - 1].get("test", ""))


## Thưởng hết wave số `wave_number`: theo file wave, không ghi thì 15 + 3 × số wave.
func get_clear_bonus(wave_number: int) -> int:
	var wave: Dictionary = _waves[wave_number - 1]
	if wave.has("reward_bonus"):
		return int(wave.reward_bonus)
	return CLEAR_BONUS_BASE + CLEAR_BONUS_PER_WAVE * wave_number


## Thành phần của một wave (số thứ tự từ 1), gộp theo loại địch:
## [{ data: EnemyData, count: int }, ...] theo thứ tự xuất hiện.
func get_wave_composition(wave_number: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if endless and wave_number >= 1:
		_ensure_wave(wave_number - 1)
	if wave_number < 1 or wave_number > _waves.size():
		return result
	var by_type: Dictionary = {}
	for group: Dictionary in _waves[wave_number - 1].get("groups", []):
		var enemy_data := _resolve_enemy(str(group.get("enemy", "")))
		if enemy_data == null:
			continue
		if not by_type.has(enemy_data):
			by_type[enemy_data] = {"data": enemy_data, "count": 0}
			result.append(by_type[enemy_data])
		by_type[enemy_data].count += int(group.get("count", 1))
	return result


func get_enemy_type(id: StringName) -> EnemyData:
	return _enemy_types.get(id)


## Bắt đầu wave tiếp theo. Trả về false nếu chưa thể bắt đầu.
func start_next_wave() -> bool:
	if not can_start_next_wave():
		return false
	var early := is_early_call()
	var early_bonus := get_early_call_bonus()
	_intermission_timer.stop()
	_last_countdown_second = -1
	_current_wave_index += 1
	if endless:
		_ensure_wave(_current_wave_index)
	GameManager.set_current_wave(get_current_wave_number())
	_build_spawn_queue(_waves[_current_wave_index])
	_alive_by_wave[_current_wave_index] = 0
	_spawning_wave_index = _current_wave_index
	if early:
		GameManager.add_gold(early_bonus)
		wave_called_early.emit(get_current_wave_number(), early_bonus)
	wave_started.emit(get_current_wave_number())
	_process_spawn_queue()
	return true


func _process(_delta: float) -> void:
	# Báo đếm ngược mỗi khi sang giây mới (HUD cập nhật nút wave).
	var seconds := ceili(get_countdown())
	if seconds != _last_countdown_second:
		_last_countdown_second = seconds
		countdown_changed.emit(seconds)


func _on_intermission_timeout() -> void:
	if auto_start_waves:
		start_next_wave()


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
			if group.has("path") and (int(group.path) < 0 or int(group.path) >= paths.size()):
				errors.append("%s: \"path\" = %d nhưng bản đồ chỉ có %d làn (0 - %d)." \
						% [group_where, int(group.path), paths.size(), paths.size() - 1])
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
			var path_index: int
			if group.has("path"):
				path_index = clampi(int(group.path), 0, paths.size() - 1)
			else:
				path_index = _next_path_index
				_next_path_index = (_next_path_index + 1) % paths.size()
			_spawn_queue.append({
				"data": enemy_data,
				# Con đầu tiên của group chờ "delay", các con sau chờ "interval".
				"delay": delay if i == 0 else interval,
				"health_multiplier": float(group.get("health_multiplier", 1.0)),
				"speed_multiplier": float(group.get("speed_multiplier", 1.0)),
				"path_index": path_index,
			})


## Chế độ vô tận: sinh thêm wave cho tới khi có wave thứ index (tính từ 0).
func _ensure_wave(index: int) -> void:
	while _waves.size() <= index:
		_waves.append(WaveGenerator.generate(_waves.size() + 1, endless_seed, _enemy_types.keys()))


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
		var enemy_data: EnemyData = entry.data
		var lanes := air_paths if enemy_data.is_flying and not air_paths.is_empty() else paths
		_spawn_enemy(enemy_data, entry.health_multiplier, entry.speed_multiplier, 0.0,
				_spawning_wave_index, lanes[entry.path_index % lanes.size()])

	if not is_spawning():
		return
	var finished_wave := _spawning_wave_index
	_spawning_wave_index = -1
	if has_more_waves() and GameManager.is_playing():
		_intermission_timer.start(intermission_time)
	spawning_finished.emit(finished_wave + 1)
	_check_wave_completed(finished_wave)


## wave_index < 0 nghĩa là "wave hiện tại"; path = null nghĩa là làn đầu tiên phù hợp.
## spawned_by_enemy = true: quân sinh ra từ địch khác (tách đôi, Boss chết / gọi quân), không cho vàng
## để không "cày" được tiền. Còn lại: vàng tăng 3% mỗi wave (chậm hơn máu địch).
func _spawn_enemy(enemy_data: EnemyData, health_multiplier: float, speed_multiplier: float,
		start_progress: float = 0.0, wave_index: int = -1, path: Path2D = null,
		spawned_by_enemy: bool = false) -> Enemy:
	if wave_index < 0:
		wave_index = maxi(_current_wave_index, 0)
	if path == null:
		path = air_paths[0] if enemy_data.is_flying and not air_paths.is_empty() else paths[0]
	var enemy := enemy_data.scene.instantiate() as Enemy
	# Độ khó nhân máu địch (quân sinh từ địch khác đã kế thừa hệ số của địch mẹ).
	if not spawned_by_enemy:
		health_multiplier *= GameManager.get_hp_multiplier()
	enemy.setup(enemy_data, health_multiplier, speed_multiplier)
	enemy.wave_index = wave_index
	enemy.terrain_map = map
	enemy.reward_multiplier = 0.0 if spawned_by_enemy else 1.0 + REWARD_GROWTH_PER_WAVE * wave_index
	enemy.died.connect(_on_enemy_died)
	enemy.summon_requested.connect(_on_summon_requested)
	enemy.reached_end.connect(_on_enemy_reached_end)
	path.add_child(enemy)
	enemy.progress = start_progress
	_alive_by_wave[wave_index] = _alive_by_wave.get(wave_index, 0) + 1
	enemy_spawned.emit(enemy)
	return enemy


func _on_enemy_died(enemy: Enemy, reward: int) -> void:
	# Sinh địch con TRƯỚC khi giảm bộ đếm để wave không bị coi là đã xong.
	var child_data := enemy.data.spawn_on_death
	if child_data and child_data.scene:
		for i in enemy.data.spawn_on_death_count:
			# Con cùng kiểu di chuyển (bay / đi bộ) với mẹ thì xuất hiện ngay chỗ mẹ chết,
			# khác kiểu thì bắt đầu từ đầu làn phù hợp.
			var same_lane := child_data.is_flying == enemy.data.is_flying
			_spawn_enemy(child_data, enemy.health_multiplier, 1.0,
					maxf(enemy.progress - i * DEATH_SPAWN_SPACING, 0.0) if same_lane else 0.0,
					enemy.wave_index, enemy.get_parent() if same_lane else null, true)

	_alive_by_wave[enemy.wave_index] -= 1
	GameManager.add_gold(reward)
	_check_wave_completed(enemy.wave_index)


## Boss gọi quân: sinh ngay sau lưng Boss, cùng làn, cùng hệ số máu, không cho vàng.
func _on_summon_requested(enemy: Enemy, summon_data: EnemyData, count: int) -> void:
	if not enemy.is_alive() or summon_data.scene == null:
		return
	for i in count:
		_spawn_enemy(summon_data, enemy.health_multiplier, 1.0, maxf(enemy.progress - 24.0 - i * DEATH_SPAWN_SPACING, 0.0),
				enemy.wave_index, enemy.get_parent(), true)


func _on_enemy_reached_end(enemy: Enemy, damage: int) -> void:
	_alive_by_wave[enemy.wave_index] -= 1
	GameManager.lose_lives(damage)
	_check_wave_completed(enemy.wave_index)


## Wave hoàn thành khi đã spawn xong và địch của chính nó chết / đi hết.
func _check_wave_completed(wave_index: int) -> void:
	if not GameManager.is_playing() or not _alive_by_wave.has(wave_index):
		return
	if wave_index == _spawning_wave_index or _alive_by_wave[wave_index] > 0:
		return
	_alive_by_wave.erase(wave_index)
	var bonus := get_clear_bonus(wave_index + 1)
	GameManager.add_gold(bonus)
	wave_completed.emit(wave_index + 1, bonus)
	if not has_more_waves() and not is_wave_in_progress():
		all_waves_completed.emit()
		GameManager.win()
