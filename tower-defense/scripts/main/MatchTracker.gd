class_name MatchTracker
extends Node
## Theo dõi một ván để phục vụ meta-progression (thành tựu, nhiệm vụ, thưởng cuối ván).
##
## Chỉ NGHE signal của các hệ thống trong trận, rồi phát lại thành sự kiện chung trên Events
## (enemy_killed, wave_survived, tower_built...). Không đổi luật chơi. Main tạo node này
## và gọi build_result() khi ván kết thúc.
##
## write_log() ghi thêm một file JSON chi tiết cho việc cân bằng (sát thương / số hạ theo loại
## tháp, địch lọt theo loại, vàng cuối mỗi wave...) vào log_dir, giữ MAX_LOGS file mới nhất.
## Không ghi trên bản Web (không có thư mục để mở file ra xem).

const MAX_LOGS := 20

## Thư mục log. Test đổi sang thư mục riêng; chuỗi rỗng = không ghi.
static var log_dir := "user://match_logs"
## Số thứ tự file log trong phiên (thêm vào tên file để hai ván kết thúc cùng mili-giây không đè nhau).
static var _log_sequence := 0

var level: LevelData
var endless := false
var starting_lives := 0
## Thời gian chơi (giây, theo thời gian game: tính cả tốc độ x2/x3, không tính lúc pause).
var elapsed := 0.0
var waves_survived := 0
var kills := 0
var bosses_killed := 0
var towers_built := 0
var upgrades := 0
var towers_sold := 0
var abilities_used := 0
## Vàng nhận từ Mỏ vàng trong ván.
var gold_from_mines := 0
## Các loại tháp đã từng xây trong ván (id -> true).
var tower_types: Dictionary = {}
## Boss nhanh nhất bị hạ (giây kể từ lúc xuất hiện; INF = chưa hạ Boss nào).
var fastest_boss_kill := INF

## Số lần gọi wave sớm.
var early_calls := 0
## id kỹ năng -> số lần dùng.
var skill_uses: Dictionary = {}
## id địch -> số con lọt tới nhà chính.
var leaks_by_enemy_type: Dictionary = {}
## Vàng đang có lúc mỗi wave hoàn thành (theo thứ tự wave).
var gold_per_wave: Array[int] = []

## Thời điểm (elapsed) từng Boss xuất hiện.
var _boss_spawn_time: Dictionary = {}
## Sát thương / số hạ của các tháp đã bán (id tháp -> giá trị), để log không mất phần đó.
var _sold_damage: Dictionary = {}
var _sold_kills: Dictionary = {}


func setup(p_level: LevelData, p_endless: bool, p_starting_lives: int, waves: WaveManager,
		build: BuildManager, abilities: AbilityManager) -> void:
	level = p_level
	endless = p_endless
	starting_lives = p_starting_lives
	waves.enemy_spawned.connect(_on_enemy_spawned)
	waves.wave_completed.connect(_on_wave_completed)
	waves.wave_called_early.connect(func(_wave: int, _bonus: int) -> void: early_calls += 1)
	build.tower_placed.connect(_on_tower_placed)
	build.tower_upgraded.connect(_on_tower_upgraded)
	build.tower_sold.connect(_on_tower_sold)
	abilities.ability_cast.connect(_on_ability_cast)


func _process(delta: float) -> void:
	if GameManager.is_playing():
		elapsed += delta


## Tổng kết ván. Gọi một lần khi ván kết thúc.
func build_result(victory: bool, stars: int) -> Dictionary:
	return {
		"won": victory,
		"level_id": level.id,
		"endless": endless,
		"difficulty": GameManager.difficulty,
		"stars": stars,
		"waves_survived": waves_survived,
		"total_waves": GameManager.total_waves,
		"lives_left": GameManager.lives,
		"starting_lives": starting_lives,
		"lives_lost": maxi(starting_lives - GameManager.lives, 0),
		"kills": kills,
		"bosses_killed": bosses_killed,
		"towers_built": towers_built,
		"tower_types": tower_types.keys(),
		"upgrades": upgrades,
		"towers_sold": towers_sold,
		"abilities_used": abilities_used,
		"gold_from_mines": gold_from_mines,
		"fastest_boss_kill": fastest_boss_kill,
		"duration": elapsed,
	}


func _on_enemy_spawned(enemy: Enemy) -> void:
	Events.enemy_seen.emit(enemy.data.id)
	if enemy.data.elite:
		_boss_spawn_time[enemy.get_instance_id()] = elapsed
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(func(leaked: Enemy, _damage: int) -> void:
		leaks_by_enemy_type[leaked.data.id] = leaks_by_enemy_type.get(leaked.data.id, 0) + 1)


func _on_enemy_died(enemy: Enemy, _reward: int) -> void:
	kills += 1
	Events.enemy_killed.emit(enemy.data.id)
	var key := enemy.get_instance_id()
	if _boss_spawn_time.has(key):
		var alive: float = elapsed - _boss_spawn_time[key]
		_boss_spawn_time.erase(key)
		bosses_killed += 1
		fastest_boss_kill = minf(fastest_boss_kill, alive)
		Events.boss_killed.emit(enemy.data.id, alive)


func _on_wave_completed(wave_number: int, _bonus: int) -> void:
	waves_survived = maxi(waves_survived, wave_number)
	gold_per_wave.append(GameManager.gold)
	Events.wave_survived.emit(wave_number)


func _on_tower_placed(tower: Tower) -> void:
	towers_built += 1
	tower_types[tower.data.id] = true
	Events.tower_built.emit(tower.data.id)


func _on_tower_upgraded(tower: Tower) -> void:
	upgrades += 1
	Events.tower_upgraded.emit(tower.data.id)


func _on_tower_sold(tower: Tower, _refund: int) -> void:
	towers_sold += 1
	_sold_damage[tower.data.id] = _sold_damage.get(tower.data.id, 0.0) + tower.damage_dealt
	_sold_kills[tower.data.id] = _sold_kills.get(tower.data.id, 0) + tower.kills
	Events.tower_sold.emit(tower.data.id)


func _on_ability_cast(ability: AbilityData, _position: Vector2) -> void:
	abilities_used += 1
	skill_uses[ability.id] = skill_uses.get(ability.id, 0) + 1
	Events.ability_used.emit(ability.id)


## Ghi log JSON của ván (kết quả build_result + số liệu cân bằng). Trả về đường dẫn file,
## hoặc "" nếu không ghi (Web, log_dir rỗng, lỗi ghi file).
func write_log(result: Dictionary) -> String:
	if log_dir.is_empty() or OS.has_feature("web"):
		return ""
	var damage := _sold_damage.duplicate()
	var tower_kills := _sold_kills.duplicate()
	for tower: Tower in get_tree().get_nodes_in_group(Tower.GROUP):
		damage[tower.data.id] = damage.get(tower.data.id, 0.0) + tower.damage_dealt
		tower_kills[tower.data.id] = tower_kills.get(tower.data.id, 0) + tower.kills
	for id: StringName in damage:
		damage[id] = roundi(damage[id])
	var entry := result.duplicate()
	entry.merge({
		"time": Time.get_datetime_string_from_system(),
		"damage_by_tower_type": damage,
		"kills_by_tower_type": tower_kills,
		"leaks_by_enemy_type": leaks_by_enemy_type,
		"gold_per_wave": gold_per_wave,
		"early_calls": early_calls,
		"skill_uses": skill_uses,
	}, true)
	# JSON không có Infinity: chưa hạ Boss nào thì ghi null.
	if is_inf(entry.fastest_boss_kill):
		entry.fastest_boss_kill = null
	DirAccess.make_dir_recursive_absolute(log_dir)
	_log_sequence += 1
	var path := log_dir.path_join("%s_%09d_%03d_%s.json" % [Time.get_datetime_string_from_system().replace(":", "-"),
			Time.get_ticks_msec(), _log_sequence % 1000, level.id])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(entry, "\t"))
	file.close()
	_prune_logs()
	return path


## Chỉ giữ MAX_LOGS file log mới nhất (tên file bắt đầu bằng thời gian nên sắp xếp được).
func _prune_logs() -> void:
	var files := Array(DirAccess.get_files_at(log_dir)).filter(func(f: String) -> bool: return f.ends_with(".json"))
	files.sort()
	for i in maxi(files.size() - MAX_LOGS, 0):
		DirAccess.remove_absolute(log_dir.path_join(files[i]))
