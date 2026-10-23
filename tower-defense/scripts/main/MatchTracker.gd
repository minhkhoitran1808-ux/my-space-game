class_name MatchTracker
extends Node
## Theo dõi một ván để phục vụ meta-progression (thành tựu, nhiệm vụ, thưởng cuối ván).
##
## Chỉ NGHE signal của các hệ thống trong trận, rồi phát lại thành sự kiện chung trên Events
## (enemy_killed, wave_survived, tower_built...). Không đổi luật chơi. Main tạo node này
## và gọi build_result() khi ván kết thúc.

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

## Thời điểm (elapsed) từng Boss xuất hiện.
var _boss_spawn_time: Dictionary = {}


func setup(p_level: LevelData, p_endless: bool, p_starting_lives: int, waves: WaveManager,
		build: BuildManager, abilities: AbilityManager) -> void:
	level = p_level
	endless = p_endless
	starting_lives = p_starting_lives
	waves.enemy_spawned.connect(_on_enemy_spawned)
	waves.wave_completed.connect(_on_wave_completed)
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
	Events.tower_sold.emit(tower.data.id)


func _on_ability_cast(ability: AbilityData, _position: Vector2) -> void:
	abilities_used += 1
	Events.ability_used.emit(ability.id)
