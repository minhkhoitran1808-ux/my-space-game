extends Node
## ProgressionManager (Autoload): cấp tài khoản, kinh nghiệm (KN) và thưởng cuối ván.
##
## - Thưởng cuối ván (kể cả khi THUA, để thất bại vẫn là tiến bộ):
##     xu = coin_reward của màn × (wave đã qua / tổng wave)^1.3, thắng thêm 40%
##     KN = 20 + 2 × wave đã qua
##   Chế độ vô tận: tỉ lệ = wave đã qua / 10 (không giới hạn trên), không có thưởng thắng.
## - Cấp: cần 100 + 40 × cấp hiện tại KN để lên cấp tiếp. Mỗi lần lên cấp thưởng 50 × cấp mới xu.

const WIN_BONUS := 0.4
const COIN_EXPONENT := 1.3
const ENDLESS_WAVES_PER_LEVEL_REWARD := 10.0
const LEVEL_UP_COINS_PER_LEVEL := 50


func get_level() -> int:
	return maxi(SaveManager.read_int(_player(), "level", 1), 1)


## KN hiện có trong cấp hiện tại.
func get_exp() -> int:
	return SaveManager.read_int(_player(), "exp")


## KN cần để lên từ cấp `level` lên cấp kế.
static func exp_to_next(level: int) -> int:
	return 100 + 40 * level


## Cộng KN (tự lên nhiều cấp nếu đủ). Trả về số cấp vừa lên.
func add_exp(amount: int, _reason: String) -> int:
	if amount <= 0:
		return 0
	var player := _player()
	var level := get_level()
	var exp := get_exp() + amount
	var gained := 0
	while exp >= exp_to_next(level):
		exp -= exp_to_next(level)
		level += 1
		gained += 1
	player["level"] = level
	player["exp"] = exp
	SaveManager.request_save()
	for i in gained:
		var new_level := level - gained + i + 1
		EconomyManager.add(EconomyManager.COINS, LEVEL_UP_COINS_PER_LEVEL * new_level, "level_up_%d" % new_level)
		Events.level_up.emit(new_level)
	return gained


## Xu + KN của một ván (chưa cộng). result: MatchTracker.build_result().
static func calculate_match_rewards(result: Dictionary, coin_reward: int) -> Dictionary:
	var waves: int = result.waves_survived
	if result.won:
		waves = maxi(waves, result.total_waves)
	var ratio: float
	if result.endless:
		ratio = waves / ENDLESS_WAVES_PER_LEVEL_REWARD
	else:
		ratio = clampf(float(waves) / maxf(result.total_waves, 1.0), 0.0, 1.0)
	var coins := float(coin_reward) * pow(ratio, COIN_EXPONENT)
	if result.won and not result.endless:
		coins *= 1.0 + WIN_BONUS
	return {"coins": roundi(coins), "exp": 20 + 2 * waves}


## Tính và cộng thưởng cuối ván. Trả về chi tiết để bảng kết quả hiển thị:
## {coins, exp, level_before, exp_before, level_after, exp_after, levels_gained}.
func grant_match_rewards(result: Dictionary, coin_reward: int) -> Dictionary:
	var rewards := calculate_match_rewards(result, coin_reward)
	rewards["level_before"] = get_level()
	rewards["exp_before"] = get_exp()
	EconomyManager.add(EconomyManager.COINS, rewards.coins, "match_%s" % result.level_id)
	rewards["levels_gained"] = add_exp(rewards.exp, "match_%s" % result.level_id)
	rewards["level_after"] = get_level()
	rewards["exp_after"] = get_exp()
	return rewards


# --- Danh hiệu ----------------------------------------------------------------------

## Các danh hiệu đã có (theo thứ tự nhận).
func get_titles() -> Array:
	var titles: Variant = _player().get("titles", [])
	return titles if titles is Array else []


func grant_title(title: String) -> void:
	var titles := get_titles()
	if title in titles:
		return
	titles.append(title)
	_player()["titles"] = titles
	if get_active_title().is_empty():
		set_active_title(title)
	SaveManager.request_save()


## Danh hiệu đang đeo (hiện cạnh cấp ở menu chính).
func get_active_title() -> String:
	return str(_player().get("active_title", ""))


func set_active_title(title: String) -> void:
	if title.is_empty() or title in get_titles():
		_player()["active_title"] = title
		SaveManager.request_save()
		SaveManager.progress_changed.emit()


func _player() -> Dictionary:
	return SaveManager.section("player")
