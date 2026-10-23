class_name HitFeedback
extends Node
## Hiệu ứng khi địch trúng đòn: nháy trắng ngắn + "giật" (nén/giãn) nhẹ.
##
## Component chỉ TÍNH giá trị (flash_amount, body_scale) từ signal Enemy.damaged;
## Enemy đọc hai giá trị này khi tự vẽ thân. Không đụng tới máu, tốc độ hay vị trí.
##
## Để không rối mắt khi tháp bắn nhanh:
## - Mỗi địch chỉ BẮT ĐẦU nháy mới sau ít nhất 0.33s (tối đa 3 lần / giây, theo ngưỡng
##   nhấp nháy an toàn WCAG 2.3.1). Đòn trong khoảng chặn vẫn trừ máu và cập nhật thanh máu.
## - Đang giật thì không giật lại từ đầu.
## - Sát thương theo thời gian (thiêu đốt) không gây nháy / giật.
## _process chỉ chạy trong ~0.33s sau mỗi lần nháy rồi tự tắt.

## Phát ra khi flash_amount / body_scale đổi (Enemy nối vào queue_redraw).
signal changed

const FLASH_TIME := 0.10
const FLASH_MIN_INTERVAL := 0.33
## Giai đoạn nén rồi hồi về, tổng 0.12s.
const SQUASH_IN_TIME := 0.04
const SQUASH_OUT_TIME := 0.08
const SQUASH_SCALE := Vector2(1.08, 0.92)
## Địch to (boss) giật ít hơn, giật mạnh trông rẻ tiền.
const SQUASH_SCALE_ELITE := Vector2(1.03, 0.97)

## 0 = màu gốc, 1 = trắng hoàn toàn.
var flash_amount := 0.0
## Tỉ lệ nén/giãn của thân (chỉ thân, không áp lên thanh máu).
var body_scale := Vector2.ONE
var squash_scale := SQUASH_SCALE

var _flash_age := INF
var _squash_age := INF


func _ready() -> void:
	set_process(false)


## Nghe signal damaged của địch. Enemy gọi trong _ready().
func track(enemy: Enemy) -> void:
	squash_scale = SQUASH_SCALE_ELITE if enemy.data.elite else SQUASH_SCALE
	enemy.damaged.connect(_on_damaged)


## Chạy hiệu ứng trúng đòn (tôn trọng giới hạn nhịp nháy).
func play() -> void:
	if _flash_age >= FLASH_MIN_INTERVAL:
		_flash_age = 0.0
	if _squash_age >= SQUASH_IN_TIME + SQUASH_OUT_TIME:
		_squash_age = 0.0
	_update_values()
	set_process(true)


func is_active() -> bool:
	return is_processing()


func _on_damaged(_enemy: Enemy, amount: float, info: DamageInfo) -> void:
	if amount <= 0.0 or info.is_periodic:
		return
	play()


func _process(delta: float) -> void:
	_flash_age += delta
	_squash_age += delta
	_update_values()
	# Giữ _process tới hết khoảng chặn nháy để đếm giờ đúng, sau đó nghỉ hẳn.
	if _flash_age >= FLASH_MIN_INTERVAL and _squash_age >= SQUASH_IN_TIME + SQUASH_OUT_TIME:
		set_process(false)


func _update_values() -> void:
	var old_flash := flash_amount
	var old_scale := body_scale

	# Nháy: 1 -> 0, ease-out (tắt nhanh lúc đầu, dịu ở cuối).
	var t := clampf(_flash_age / FLASH_TIME, 0.0, 1.0)
	flash_amount = (1.0 - t) * (1.0 - t)

	# Giật: 1 -> nén (ease-out) -> 1 (ease-out).
	if _squash_age < SQUASH_IN_TIME:
		body_scale = Vector2.ONE.lerp(squash_scale, _ease_out(_squash_age / SQUASH_IN_TIME))
	elif _squash_age < SQUASH_IN_TIME + SQUASH_OUT_TIME:
		body_scale = squash_scale.lerp(Vector2.ONE, _ease_out((_squash_age - SQUASH_IN_TIME) / SQUASH_OUT_TIME))
	else:
		body_scale = Vector2.ONE

	if flash_amount != old_flash or body_scale != old_scale:
		changed.emit()


static func _ease_out(x: float) -> float:
	return 1.0 - (1.0 - x) * (1.0 - x)
