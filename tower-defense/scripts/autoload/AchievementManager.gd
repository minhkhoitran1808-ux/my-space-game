extends Node
## AchievementManager (Autoload): mở khoá và trao thưởng thành tựu.
##
## - Định nghĩa: mọi AchievementDef (.tres) trong ACHIEVEMENTS_FOLDER.
## - Trạng thái trong hồ sơ: achievements[id] = {"unlocked": bool, "claimed": bool}.
## - Thành tựu theo bộ đếm được đánh chỉ mục theo stat_key, nên mỗi lần bộ đếm đổi chỉ kiểm tra
##   vài thành tựu liên quan (quan trọng vì enemies_killed đổi hàng trăm lần mỗi wave).
## - Thành tựu thử thách kiểm tra khi kết thúc ván (Events.match_ended) hoặc sự kiện riêng.
## - Phần thưởng KHÔNG tự cộng: người chơi bấm "Nhận" (claim). unlock() và claim() đều
##   idempotent: gọi bao nhiêu lần cũng chỉ mở / thưởng một lần.

const ACHIEVEMENTS_FOLDER := "res://resources/achievements"
const ENEMIES_FOLDER := "res://resources/enemies"
## Hạ Boss trong chừng này giây kể từ lúc nó xuất hiện.
const BOSS_FAST_SECONDS := 10.0
## Thắng mà chỉ dùng tối đa chừng này tháp.
const MINIMALIST_MAX_TOWERS := 5

## Mã điều kiện đặc biệt mà AchievementDef.challenge có thể dùng.
const CHALLENGES: Array[StringName] = [&"perfect_clear", &"minimalist", &"one_type", &"no_upgrade",
		&"last_hp", &"boss_fast", &"all_stars", &"codex_all", &"hard_win", &"hard_all"]

## id -> AchievementDef
var defs: Dictionary = {}
## stat_key -> Array[AchievementDef]
var _by_stat: Dictionary = {}
var _enemy_type_count := 0


func _ready() -> void:
	_load_defs()
	for file_name in ResourceLoader.list_directory(ENEMIES_FOLDER):
		if file_name.ends_with(".tres"):
			_enemy_type_count += 1
	Events.stat_changed.connect(_on_stat_changed)
	Events.match_ended.connect(_on_match_ended)
	Events.boss_killed.connect(_on_boss_killed)
	SaveManager.progress_changed.connect(check_all_stats)


## Danh sách thành tựu đã sắp xếp (theo order rồi id).
func get_sorted() -> Array[AchievementDef]:
	var list: Array[AchievementDef] = []
	for def: AchievementDef in defs.values():
		list.append(def)
	list.sort_custom(func(a: AchievementDef, b: AchievementDef) -> bool:
		return a.order < b.order if a.order != b.order else String(a.id) < String(b.id))
	return list


func is_unlocked(id: StringName) -> bool:
	return bool(_state(id).get("unlocked", false))


func is_claimed(id: StringName) -> bool:
	return bool(_state(id).get("claimed", false))


func get_unlocked_count() -> int:
	var count := 0
	for id in defs:
		if is_unlocked(id):
			count += 1
	return count


## Số thành tựu đã mở mà chưa nhận thưởng (cho chấm đỏ trên menu).
func get_unclaimed_count() -> int:
	var count := 0
	for id in defs:
		if is_unlocked(id) and not is_claimed(id):
			count += 1
	return count


## Tiến độ hiện tại [đã đạt, mục tiêu] (thành tựu thử thách: [0 hoặc 1, 1]).
func get_progress(def: AchievementDef) -> Vector2i:
	if is_unlocked(def.id):
		return Vector2i(maxi(def.target, 1), maxi(def.target, 1))
	if def.stat_key != &"":
		return Vector2i(mini(StatsManager.get_stat(def.stat_key), def.target), def.target)
	if def.challenge == &"codex_all":
		return Vector2i(StatsManager.get_stat(StatsManager.ENEMY_TYPES_SEEN), _enemy_type_count)
	if def.challenge == &"hard_all":
		var won := 0
		for level in GameManager.LEVEL_CATALOG.levels:
			won += 1 if SaveManager.get_stars_for(level.id, GameManager.Difficulty.HARD) > 0 else 0
		return Vector2i(won, GameManager.LEVEL_CATALOG.levels.size())
	if def.challenge == &"all_stars":
		return Vector2i(SaveManager.get_total_stars(), GameManager.LEVEL_CATALOG.levels.size() * 3)
	return Vector2i(0, 1)


## Mở khoá (không trao thưởng). Trả về true nếu vừa mở lần đầu.
func unlock(id: StringName) -> bool:
	if not defs.has(id) or is_unlocked(id):
		return false
	_all_states()[String(id)] = {"unlocked": true, "claimed": false}
	SaveManager.request_save()
	Events.achievement_unlocked.emit(id)
	Events.claimables_changed.emit()
	return true


## Nhận thưởng của thành tựu đã mở. Trả về true nếu vừa nhận (lần đầu).
func claim(id: StringName) -> bool:
	if not is_unlocked(id) or is_claimed(id):
		return false
	_state(id)["claimed"] = true # Đánh dấu TRƯỚC khi thưởng: lỗi giữa chừng cũng không thưởng hai lần.
	var def: AchievementDef = defs[id]
	EconomyManager.add(EconomyManager.COINS, def.reward_coins, "achievement_%s" % id)
	if not def.reward_title.is_empty():
		ProgressionManager.grant_title(def.reward_title)
	if def.reward_item != &"":
		InventoryManager.grant(def.reward_item, 1, "achievement_%s" % id)
	SaveManager.request_save()
	Events.claimables_changed.emit()
	return true


## Nhận tất cả thưởng đang chờ. Trả về số thành tựu vừa nhận.
func claim_all() -> int:
	var count := 0
	for def in get_sorted():
		if claim(def.id):
			count += 1
	return count


## Kiểm tra lại mọi thành tựu theo bộ đếm (vd sau khi nạp hồ sơ).
func check_all_stats() -> void:
	for key in _by_stat:
		_on_stat_changed(key, StatsManager.get_stat(key))
	_check_codex()


# --- Kiểm tra điều kiện ------------------------------------------------------------

func _on_stat_changed(key: StringName, value: int) -> void:
	for def: AchievementDef in _by_stat.get(key, []):
		if value >= def.target:
			unlock(def.id)
	if key == StatsManager.ENEMY_TYPES_SEEN:
		_check_codex()


func _check_codex() -> void:
	if _enemy_type_count > 0 and StatsManager.get_stat(StatsManager.ENEMY_TYPES_SEEN) >= _enemy_type_count:
		_unlock_challenge(&"codex_all")


func _on_boss_killed(_enemy_id: StringName, seconds_alive: float) -> void:
	if seconds_alive <= BOSS_FAST_SECONDS:
		_unlock_challenge(&"boss_fast")


func _on_match_ended(result: Dictionary) -> void:
	if result.won and not result.endless:
		if result.lives_lost == 0:
			_unlock_challenge(&"perfect_clear")
		if result.towers_built <= MINIMALIST_MAX_TOWERS:
			_unlock_challenge(&"minimalist")
		if result.tower_types.size() == 1:
			_unlock_challenge(&"one_type")
		if result.upgrades == 0:
			_unlock_challenge(&"no_upgrade")
		if result.lives_left == 1:
			_unlock_challenge(&"last_hp")
	if SaveManager.get_total_stars() >= GameManager.LEVEL_CATALOG.levels.size() * 3:
		_unlock_challenge(&"all_stars")
	if result.won and not result.endless and result.get("difficulty", -1) == GameManager.Difficulty.HARD:
		_unlock_challenge(&"hard_win")
	if _won_every_level_on_hard():
		_unlock_challenge(&"hard_all")


func _won_every_level_on_hard() -> bool:
	for level in GameManager.LEVEL_CATALOG.levels:
		if SaveManager.get_stars_for(level.id, GameManager.Difficulty.HARD) == 0:
			return false
	return true


func _unlock_challenge(challenge: StringName) -> void:
	for def: AchievementDef in defs.values():
		if def.challenge == challenge:
			unlock(def.id)


# --- Dữ liệu ----------------------------------------------------------------------

func _load_defs() -> void:
	for file_name in ResourceLoader.list_directory(ACHIEVEMENTS_FOLDER):
		if not file_name.ends_with(".tres"):
			continue
		var def := load(ACHIEVEMENTS_FOLDER.path_join(file_name)) as AchievementDef
		if def == null or def.id == &"":
			push_warning("AchievementManager: bỏ qua '%s' (không phải AchievementDef hợp lệ)." % file_name)
			continue
		assert(not defs.has(def.id), "Trùng id thành tựu: %s" % def.id)
		assert(def.challenge == &"" or def.challenge in CHALLENGES, "Điều kiện lạ: %s" % def.challenge)
		defs[def.id] = def
		if def.stat_key != &"":
			if not _by_stat.has(def.stat_key):
				_by_stat[def.stat_key] = []
			_by_stat[def.stat_key].append(def)


func _all_states() -> Dictionary:
	return SaveManager.section("achievements")


func _state(id: StringName) -> Dictionary:
	var states := _all_states()
	var state: Variant = states.get(String(id))
	return state if state is Dictionary else {}
