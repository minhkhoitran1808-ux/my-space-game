class_name WaveGenerator
extends RefCounted
## Sinh wave cho chế độ vô tận, cùng định dạng Dictionary với file JSON:
##   { "reward_bonus": int, "groups": [ { enemy, count, interval, delay, health_multiplier }, ... ] }
##
## Mỗi wave có một "ngân sách độ khó" tăng dần; mỗi loại địch tốn một lượng ngân sách
## (THREAT). Loại địch mới mở dần theo wave (UNLOCK_WAVE) và cứ BOSS_EVERY wave có Boss.
## Dùng seed cố định theo (màn, số wave) nên cùng một màn luôn ra cùng chuỗi wave:
## kỷ lục giữa các lần chơi là công bằng và test có thể lặp lại.

## Ngân sách mỗi loại địch tiêu tốn (xấp xỉ độ nguy hiểm).
const THREAT := {&"basic": 1.0, &"fast": 1.0, &"swarm": 0.4, &"armored": 2.5, &"bat": 1.2, &"healer": 2.2, &"wisp": 1.6, &"splitter": 2.6}
## Wave đầu tiên loại địch được phép xuất hiện.
const UNLOCK_WAVE := {&"basic": 1, &"fast": 2, &"swarm": 3, &"armored": 4, &"bat": 5, &"healer": 7, &"wisp": 6, &"splitter": 8}
## Khoảng cách spawn gợi ý theo loại địch (giây, ở wave 1).
const BASE_INTERVAL := {&"basic": 0.8, &"fast": 0.45, &"swarm": 0.2, &"armored": 1.2, &"bat": 0.6, &"healer": 1.4, &"wisp": 0.6, &"splitter": 1.2}
const BOSS_ID := &"boss"
const BOSS_EVERY := 10


## Sinh wave số wave_number (bắt đầu từ 1). available_ids: các id địch có thật trong game.
static func generate(wave_number: int, seed_key: String, available_ids: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s#%d" % [seed_key, wave_number])

	var budget := 8.0 + wave_number * 3.2
	var health_multiplier := snappedf(1.0 + 0.1 * (wave_number - 1) + 0.004 * wave_number * wave_number, 0.01)
	var interval_scale := maxf(0.5, 1.0 - wave_number * 0.015)

	var unlocked: Array[StringName] = []
	for id: StringName in THREAT:
		if id in available_ids and wave_number >= UNLOCK_WAVE[id]:
			unlocked.append(id)

	# Chọn 1-3 loại địch cho wave này, chia đều ngân sách.
	var type_count := mini(unlocked.size(), rng.randi_range(1, 3))
	var chosen: Array[StringName] = []
	while chosen.size() < type_count:
		var pick: StringName = unlocked[rng.randi_range(0, unlocked.size() - 1)]
		if not pick in chosen:
			chosen.append(pick)

	var groups: Array = []
	for i in chosen.size():
		var id := chosen[i]
		var count := maxi(1, roundi(budget / chosen.size() / THREAT[id]))
		var group := {
			"enemy": String(id),
			"count": count,
			"interval": snappedf(BASE_INTERVAL[id] * interval_scale, 0.01),
			"health_multiplier": health_multiplier,
		}
		if i > 0:
			group["delay"] = 1.5
		groups.append(group)

	if wave_number % BOSS_EVERY == 0 and BOSS_ID in available_ids:
		groups.append({
			"enemy": String(BOSS_ID),
			"count": wave_number / BOSS_EVERY,
			"interval": 4.0,
			"delay": 2.0,
			"health_multiplier": snappedf(0.6 + 0.04 * wave_number, 0.01),
		})

	return {"reward_bonus": 20 + 3 * wave_number, "groups": groups}
