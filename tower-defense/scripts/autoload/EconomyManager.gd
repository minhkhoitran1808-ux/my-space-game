extends Node
## EconomyManager (Autoload): tiền meta, tách hoàn toàn khỏi vàng trong ván (GameManager.gold).
##
## - COINS ("Xu"): tiền chính. Nguồn: thưởng cuối ván, thành tựu, nhiệm vụ, lên cấp.
##   Nơi tiêu: cửa hàng, thương nhân, nâng cấp vĩnh viễn.
## - DUST ("Bụi"): nguyên liệu, có được khi phân rã / nhận đồ trùng. Dùng ở thương nhân.
##
## MỌI thay đổi đi qua add() / spend() kèm "reason" và được ghi vào nhật ký ngắn trong hồ sơ.
## Sau này chuyển lên server chỉ cần thay phần thực thi của hai hàm này.

const COINS := &"coins"
const DUST := &"dust"
const CURRENCIES: Array[StringName] = [COINS, DUST]
const DISPLAY_NAMES := {COINS: "Xu", DUST: "Bụi"}
## Số dòng nhật ký giao dịch giữ lại trong hồ sơ.
const LOG_SIZE := 40


func get_amount(currency: StringName) -> int:
	return SaveManager.read_int(_wallet(), String(currency))


func can_afford(currency: StringName, amount: int) -> bool:
	return get_amount(currency) >= amount


## Cộng tiền (amount <= 0 thì bỏ qua).
func add(currency: StringName, amount: int, reason: String) -> void:
	if amount <= 0:
		return
	_set_amount(currency, get_amount(currency) + amount, amount, reason)


## Trừ tiền nếu đủ. Trả về true nếu giao dịch thành công.
func spend(currency: StringName, amount: int, reason: String) -> bool:
	if amount < 0 or not can_afford(currency, amount):
		return false
	if amount > 0:
		_set_amount(currency, get_amount(currency) - amount, -amount, reason)
	return true


## Nhật ký giao dịch gần nhất (mới nhất ở cuối): [{currency, delta, reason}].
func get_log() -> Array:
	return SaveManager.section("economy").get("log", [])


func _wallet() -> Dictionary:
	var economy := SaveManager.section("economy")
	if not economy.get("wallet") is Dictionary:
		economy["wallet"] = {}
	return economy["wallet"]


func _set_amount(currency: StringName, value: int, delta: int, reason: String) -> void:
	assert(currency in CURRENCIES, "Loại tiền không tồn tại: %s" % currency)
	_wallet()[String(currency)] = value
	var economy := SaveManager.section("economy")
	var log: Array = economy.get("log", [])
	log.append({"currency": String(currency), "delta": delta, "reason": reason})
	if log.size() > LOG_SIZE:
		log = log.slice(log.size() - LOG_SIZE)
	economy["log"] = log
	SaveManager.request_save()
	Events.currency_changed.emit(currency, value)
