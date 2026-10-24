extends Node
## StatsManager (Autoload): bộ đếm tích luỹ của người chơi qua mọi ván.
##
## Nghe Events (địch bị hạ, wave sống sót, xây / bán tháp...) và cộng dồn vào hồ sơ.
## Phát Events.stat_changed để thành tựu / nhiệm vụ tự kiểm tra.
## Không ghi đĩa sau mỗi lần hạ địch: chỉ yêu cầu lưu khi hết wave và khi kết thúc ván.

const ENEMIES_KILLED := &"enemies_killed"
const BOSSES_KILLED := &"bosses_killed"
const WAVES_SURVIVED := &"waves_survived"
const TOWERS_BUILT := &"towers_built"
const TOWERS_UPGRADED := &"towers_upgraded"
const TOWERS_SOLD := &"towers_sold"
const ABILITIES_USED := &"abilities_used"
const MATCHES_PLAYED := &"matches_played"
const WINS := &"wins"
const PERFECT_WINS := &"perfect_wins"
const ENDLESS_BEST_WAVE := &"endless_best_wave"
const ENEMY_TYPES_SEEN := &"enemy_types_seen"


func _ready() -> void:
	Events.enemy_killed.connect(func(_id: StringName) -> void: increment(ENEMIES_KILLED))
	Events.boss_killed.connect(func(_id: StringName, _seconds: float) -> void: increment(BOSSES_KILLED))
	Events.tower_built.connect(func(_id: StringName) -> void: increment(TOWERS_BUILT))
	Events.tower_upgraded.connect(func(_id: StringName) -> void: increment(TOWERS_UPGRADED))
	Events.tower_sold.connect(func(_id: StringName) -> void: increment(TOWERS_SOLD))
	Events.ability_used.connect(func(_id: StringName) -> void: increment(ABILITIES_USED))
	Events.enemy_seen.connect(_on_enemy_seen)
	Events.wave_survived.connect(_on_wave_survived)
	Events.match_ended.connect(_on_match_ended)


func get_stat(key: StringName) -> int:
	return SaveManager.read_int(SaveManager.section("stats"), String(key))


## Cộng thêm vào một bộ đếm.
func increment(key: StringName, by: int = 1) -> void:
	if by != 0:
		_set_stat(key, get_stat(key) + by)


## Ghi nhận giá trị lớn nhất (vd wave cao nhất ở vô tận).
func record_max(key: StringName, value: int) -> void:
	if value > get_stat(key):
		_set_stat(key, value)


## Loại địch đã gặp (cho Codex và thành tựu khám phá).
func has_seen_enemy(enemy_id: StringName) -> bool:
	return SaveManager.get_flag("seen_enemy_%s" % enemy_id)


func _set_stat(key: StringName, value: int) -> void:
	SaveManager.section("stats")[String(key)] = value
	Events.stat_changed.emit(key, value)


func _on_enemy_seen(enemy_id: StringName) -> void:
	var flag := "seen_enemy_%s" % enemy_id
	if SaveManager.get_flag(flag):
		return
	SaveManager.set_flag(flag, true)
	increment(ENEMY_TYPES_SEEN)
	Events.enemy_discovered.emit(enemy_id)


func _on_wave_survived(_wave_number: int) -> void:
	increment(WAVES_SURVIVED)
	SaveManager.request_save()


func _on_match_ended(result: Dictionary) -> void:
	increment(MATCHES_PLAYED)
	if result.won:
		increment(WINS)
		if result.lives_lost == 0:
			increment(PERFECT_WINS)
	if result.endless:
		record_max(ENDLESS_BEST_WAVE, result.waves_survived)
	SaveManager.request_save()
