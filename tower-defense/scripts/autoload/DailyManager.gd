extends Node
## DailyManager (Autoload): lý do quay lại mỗi ngày mà KHÔNG gây áp lực.
##
## Nhiệm vụ ngày:
## - Mỗi ngày mới (theo ngày hệ thống) nhận 3 nhiệm vụ, mỗi cái vừa 1–2 ván.
## - Chưa làm thì giữ lại, tích luỹ tối đa 3 ngày (9 nhiệm vụ); cũ hơn mới bị bỏ.
## - Mỗi ngày được đổi MIỄN PHÍ 1 nhiệm vụ (không có cách trả tiền để đổi thêm).
## - Tiến độ = bộ đếm tăng thêm kể từ lúc nhận; hoàn thành thì bấm Nhận (idempotent).
## Quà đăng nhập 7 ngày:
## - Mỗi ngày mở game nhận được 1 quà, theo thứ tự ngày 1 -> 7 rồi lặp lại.
## - Bỏ lỡ ngày thì CHỈ TẠM DỪNG, không bị reset về ngày 1.

const QUESTS_FOLDER := "res://resources/quests"
const QUESTS_PER_DAY := 3
const MAX_DAYS_KEPT := 3
## Quà đăng nhập theo thứ tự: {"coins"|"dust"|id vật phẩm: số lượng}.
const LOGIN_REWARDS: Array[Dictionary] = [
	{"coins": 100}, {"dust": 50}, {"gold_pouch_small": 1}, {"coins": 200},
	{"brick_patch": 1}, {"dust": 120}, {"crystal": 1},
]

## id -> QuestDef
var defs: Dictionary = {}
## Test hook: ngày giả lập ("YYYY-MM-DD"); rỗng = ngày hệ thống.
var date_override := ""


func _ready() -> void:
	for file_name in ResourceLoader.list_directory(QUESTS_FOLDER):
		if file_name.ends_with(".tres"):
			var def := load(QUESTS_FOLDER.path_join(file_name)) as QuestDef
			if def and def.id != &"":
				defs[def.id] = def


func today() -> String:
	return date_override if not date_override.is_empty() else Time.get_date_string_from_system()


## Số ngày giữa hai chuỗi "YYYY-MM-DD" (b - a).
static func days_between(a: String, b: String) -> int:
	var seconds := Time.get_unix_time_from_datetime_string(b) - Time.get_unix_time_from_datetime_string(a)
	return int(round(seconds / 86400.0))


# --- Nhiệm vụ -------------------------------------------------------------------------

## Cập nhật theo ngày hiện tại: thêm nhiệm vụ cho mỗi ngày mới (tối đa 3 ngày), bỏ nhiệm vụ cũ.
func refresh_day() -> void:
	var state := _quests()
	var last: String = state.get("last_day", "")
	var now := today()
	if last == now:
		return
	# Lần đầu: 1 ngày. Lâu không mở: bù tối đa 3 ngày. (Đồng hồ bị lùi: không thêm gì.)
	var new_days := 1 if last.is_empty() else clampi(days_between(last, now), 0, MAX_DAYS_KEPT)
	var active: Array = state.get("active", [])
	# Bỏ nhiệm vụ đã nhận và nhiệm vụ cũ hơn 3 ngày.
	active = active.filter(func(quest: Dictionary) -> bool:
		return not quest.get("claimed", false) and days_between(quest.day, now) < MAX_DAYS_KEPT)
	for offset in range(new_days - 1, -1, -1):
		var day := Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(now) - offset * 86400)
		for id in _pick_quests(day, QUESTS_PER_DAY, active):
			active.append(_new_quest(id, day))
	state["active"] = active
	state["last_day"] = now
	SaveManager.request_save()
	Events.claimables_changed.emit()


## Nhiệm vụ đang có (mỗi phần tử: {id, base, day, claimed}).
func get_active() -> Array:
	refresh_day()
	return _quests().get("active", [])


func get_def(quest: Dictionary) -> QuestDef:
	return defs.get(StringName(quest.id))


## Tiến độ [đã làm, mục tiêu].
func get_progress(quest: Dictionary) -> Vector2i:
	var def := get_def(quest)
	if def == null:
		return Vector2i(0, 1)
	var done := StatsManager.get_stat(def.stat_key) - int(quest.base)
	return Vector2i(clampi(done, 0, def.target), def.target)


func is_complete(quest: Dictionary) -> bool:
	var progress := get_progress(quest)
	return progress.x >= progress.y


## Nhận thưởng nhiệm vụ thứ `index`. Trả về true nếu vừa nhận.
func claim_quest(index: int) -> bool:
	var active := get_active()
	if index < 0 or index >= active.size():
		return false
	var quest: Dictionary = active[index]
	if quest.get("claimed", false) or not is_complete(quest):
		return false
	quest["claimed"] = true
	var def := get_def(quest)
	EconomyManager.add(EconomyManager.COINS, def.reward_coins, "quest_%s" % def.id)
	ProgressionManager.add_exp(def.reward_exp, "quest_%s" % def.id)
	SaveManager.request_save()
	Events.claimables_changed.emit()
	return true


func can_reroll() -> bool:
	return _quests().get("reroll_day", "") != today()


## Đổi miễn phí nhiệm vụ thứ `index` (1 lần / ngày, chỉ nhiệm vụ chưa xong).
func reroll(index: int) -> bool:
	var active := get_active()
	if not can_reroll() or index < 0 or index >= active.size():
		return false
	var quest: Dictionary = active[index]
	if quest.get("claimed", false) or is_complete(quest):
		return false
	var choices := _pick_quests(today() + ":reroll:%d" % index, 1, active)
	if choices.is_empty():
		return false
	active[index] = _new_quest(choices[0], quest.day)
	_quests()["reroll_day"] = today()
	SaveManager.request_save()
	return true


## Số nhiệm vụ đã xong mà chưa nhận.
func get_claimable_quest_count() -> int:
	var count := 0
	for quest: Dictionary in get_active():
		if not quest.get("claimed", false) and is_complete(quest):
			count += 1
	return count


# --- Quà đăng nhập ---------------------------------------------------------------------

func can_claim_login() -> bool:
	return _login().get("last_day", "") != today()


## Vị trí quà kế tiếp trong chuỗi 7 ngày (0..6).
func get_login_index() -> int:
	return SaveManager.read_int(_login(), "claimed") % LOGIN_REWARDS.size()


func get_login_claimed_total() -> int:
	return SaveManager.read_int(_login(), "claimed")


## Nhận quà hôm nay. Trả về quà ({khoá: số lượng}) hoặc {} nếu hôm nay đã nhận.
func claim_login() -> Dictionary:
	if not can_claim_login():
		return {}
	var reward: Dictionary = LOGIN_REWARDS[get_login_index()]
	var login := _login()
	login["last_day"] = today()
	login["claimed"] = get_login_claimed_total() + 1
	for key: String in reward:
		if key == "coins" or key == "dust":
			EconomyManager.add(StringName(key), reward[key], "login")
		else:
			InventoryManager.grant(StringName(key), reward[key], "login")
	SaveManager.request_save()
	Events.claimables_changed.emit()
	return reward


## Tổng số thứ đang chờ nhận (cho chấm đỏ).
func get_claimable_count() -> int:
	return get_claimable_quest_count() + (1 if can_claim_login() else 0)


# --- Nội bộ ---------------------------------------------------------------------------

func _new_quest(id: StringName, day: String) -> Dictionary:
	var def: QuestDef = defs[id]
	return {"id": String(id), "base": StatsManager.get_stat(def.stat_key), "day": day, "claimed": false}


## Chọn `amount` mẫu nhiệm vụ khác với các nhiệm vụ đang có, cố định theo `seed_text`.
func _pick_quests(seed_text: String, amount: int, active: Array) -> Array[StringName]:
	var taken := active.map(func(quest: Dictionary) -> String: return quest.id)
	var pool: Array[StringName] = []
	for id: StringName in defs:
		if not String(id) in taken:
			pool.append(id)
	pool.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("quests:" + seed_text)
	var picked: Array[StringName] = []
	while picked.size() < amount and not pool.is_empty():
		picked.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return picked


func _quests() -> Dictionary:
	return SaveManager.section("quests")


func _login() -> Dictionary:
	return SaveManager.section("login")
