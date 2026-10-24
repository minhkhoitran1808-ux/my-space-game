class_name HealthBar
extends Node2D
## Thanh máu nổi trên đầu địch (component tái sử dụng: scenes/enemies/HealthBar.tscn).
##
## - Mảnh, có viền tối + nền tối nên đọc được trên mọi nền.
## - Màu đổi theo NGƯỠNG (không nội suy): > 50% xanh lá, 25–50% vàng, <= 25% đỏ.
##   Độ dài thanh mới là thông tin chính; khi máu thấp viền còn đổi sang trắng
##   để người khó phân biệt màu vẫn nhận ra.
## - "Vệt sát thương": phần máu vừa mất hiện màu trắng, giữ 0.4s rồi rút về,
##   để thấy rõ mỗi đòn lấy bao nhiêu. Phần máu thật thì tụt ngay lập tức.
## - Ẩn khi đầy máu, hiện từ cú trúng đầu tiên tới khi chết (địch tinh nhuệ: luôn hiện,
##   có vạch chia 25%).
## - Là node riêng nên KHÔNG bị nén/giãn theo hiệu ứng trúng đòn của thân địch,
##   và z_index cao để luôn nằm trên mọi địch khác.
##
## Tôn trọng cài đặt hiển thị: chế độ thanh máu (khi bị thương / luôn hiện / tắt),
## bảng màu cho người mù màu, giảm chuyển động (vệt sát thương biến mất ngay).
##
## Hiệu năng: chỉ vẽ lại khi máu đổi; _process chỉ chạy trong lúc đang fade / rút vệt
## (tự tắt khi xong), nên hàng trăm thanh máu đứng yên gần như không tốn gì.

const COLOR_HIGH := Color("4ADE50")
const COLOR_MID := Color("FACC15")
const COLOR_LOW := Color("EF4444")
## Bảng màu cho người mù màu đỏ - lục: xanh dương / vàng / cam đậm.
const COLOR_HIGH_COLORBLIND := Color("3B82F6")
const COLOR_LOW_COLORBLIND := Color("F97316")
const COLOR_TRAIL := Color(1.0, 1.0, 1.0, 0.85)
const COLOR_BACKGROUND := Color(0.102, 0.102, 0.102, 0.8)
const COLOR_BORDER := Color(0.0, 0.0, 0.0, 0.9)
## Viền khi máu thấp: đổi độ tương phản chứ không chỉ đổi màu.
const COLOR_BORDER_LOW := Color(1.0, 1.0, 1.0, 0.6)
const COLOR_HIGHLIGHT := Color(1.0, 1.0, 1.0, 0.25)
const COLOR_TICK := Color(0.0, 0.0, 0.0, 0.6)

const THRESHOLD_MID := 0.5
const THRESHOLD_LOW := 0.25

## Thời gian hiện (alpha 0 -> 1) và ẩn.
const FADE_IN_TIME := 0.08
const FADE_OUT_TIME := 0.15
## Vệt trắng giữ nguyên bao lâu trước khi rút.
const TRAIL_HOLD_TIME := 0.4
## Tốc độ rút vệt, tính theo tỉ lệ cả thanh mỗi giây (đòn lớn rút lâu hơn đòn nhỏ).
const TRAIL_DRAIN_PER_SECOND := 1.5
## Khoảng cách từ đỉnh thân địch tới mép dưới thanh.
const GAP_ABOVE_BODY := 7.0
## Độ cao thân địch bay được vẽ nhấc lên (khớp với Enemy._draw).
const FLYING_LIFT := 10.0

## Kích thước phần ruột thanh (chưa tính viền 1px).
@export var bar_size := Vector2(36, 5)
## true = luôn hiện kể cả khi đầy máu (địch tinh nhuệ / boss).
@export var always_visible := false
## Vẽ vạch chia ở 25 / 50 / 75%.
@export var show_ticks := false

## Tỉ lệ máu hiện tại (0..1) và vị trí vệt trắng (>= ratio).
var ratio := 1.0
var trail_ratio := 1.0

var _trail_hold := 0.0
var _alpha := 0.0


func _ready() -> void:
	set_process(false)
	_apply_alpha(_target_alpha())
	SaveManager.settings_changed.connect(_on_settings_changed)


## Gắn thanh máu vào một địch: tự tính kích thước / vị trí theo EnemyData
## và nghe signal health_changed. Enemy gọi hàm này trong _ready().
func track(enemy: Enemy) -> void:
	var data := enemy.data
	always_visible = data.elite
	show_ticks = data.elite
	# Rộng theo cỡ địch nhưng có trần / sàn, để không đè sang địch bên cạnh
	# và không quá ngắn tới mức khó đọc %.
	if data.elite:
		bar_size = Vector2(56, 6)
	else:
		bar_size = Vector2(clampf(roundf(data.radius * 2.6), 26.0, 40.0), 5.0 if data.radius >= 13.0 else 4.0)
	var body_top := data.radius + (FLYING_LIFT if data.is_flying else 0.0)
	# Làm tròn về pixel nguyên để thanh mảnh không bị nhoè.
	position = Vector2(0.0, -roundf(body_top + GAP_ABOVE_BODY + bar_size.y))
	enemy.health_changed.connect(set_health)
	set_health(enemy.health, enemy.max_health, false)
	_apply_alpha(_target_alpha())


## Cập nhật máu. animate = false: nhảy thẳng tới giá trị mới (không vệt, không fade).
func set_health(current: float, maximum: float, animate := true) -> void:
	var new_ratio := clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	if new_ratio < ratio and animate:
		# Đòn liên tiếp trong lúc vệt đang giữ: vệt ở lại mức cao nhất (thấy tổng cả chuỗi đòn).
		trail_ratio = maxf(trail_ratio, ratio)
		_trail_hold = TRAIL_HOLD_TIME
	ratio = new_ratio
	if not animate or VisualSettings.reduced_motion:
		trail_ratio = ratio
	trail_ratio = maxf(trail_ratio, ratio)
	queue_redraw()
	_wake()


## Thanh đang hiện (hoặc đang hiện dần) hay không.
func is_shown() -> bool:
	return _target_alpha() > 0.0


## Màu phần ruột theo tỉ lệ máu (đổi theo ngưỡng, theo bảng màu đang chọn).
static func color_for_ratio(value: float) -> Color:
	if value <= THRESHOLD_LOW:
		return COLOR_LOW_COLORBLIND if VisualSettings.colorblind else COLOR_LOW
	if value <= THRESHOLD_MID:
		return COLOR_MID
	return COLOR_HIGH_COLORBLIND if VisualSettings.colorblind else COLOR_HIGH


func _target_alpha() -> float:
	if always_visible:
		return 1.0 # Boss: luôn hiện, kể cả khi tắt thanh máu địch thường.
	match VisualSettings.health_bar_mode:
		VisualSettings.HealthBarMode.ALWAYS:
			return 1.0
		VisualSettings.HealthBarMode.OFF:
			return 0.0
		_:
			return 1.0 if ratio < 1.0 else 0.0


func _on_settings_changed(key: String, _value: Variant) -> void:
	if key in ["health_bar_mode", "colorblind", "reduced_motion"]:
		if VisualSettings.reduced_motion:
			trail_ratio = ratio
		queue_redraw()
		_wake()


## Bật _process nếu còn việc phải làm (fade hoặc rút vệt).
func _wake() -> void:
	set_process(not is_equal_approx(_alpha, _target_alpha()) or trail_ratio > ratio)


func _process(delta: float) -> void:
	var target := _target_alpha()
	if _alpha < target:
		_apply_alpha(minf(_alpha + delta / FADE_IN_TIME, target))
	elif _alpha > target:
		_apply_alpha(maxf(_alpha - delta / FADE_OUT_TIME, target))

	if trail_ratio > ratio:
		if _trail_hold > 0.0:
			_trail_hold -= delta
		else:
			trail_ratio = maxf(trail_ratio - TRAIL_DRAIN_PER_SECOND * delta, ratio)
			queue_redraw()
	_wake()


func _apply_alpha(value: float) -> void:
	_alpha = value
	modulate.a = value
	visible = value > 0.0


func _draw() -> void:
	var left := -bar_size.x * 0.5
	var inner := Rect2(left, 0.0, bar_size.x, bar_size.y)
	var is_low := ratio <= THRESHOLD_LOW

	# Viền 1px (vẽ hình chữ nhật lớn hơn 1px mỗi phía), rồi nền tối phủ lên trong.
	draw_rect(inner.grow(1.0), COLOR_BORDER_LOW if is_low else COLOR_BORDER)
	draw_rect(inner, COLOR_BACKGROUND)

	# Vệt sát thương nằm DƯỚI phần máu thật.
	if trail_ratio > ratio:
		draw_rect(Rect2(left, 0.0, bar_size.x * trail_ratio, bar_size.y), COLOR_TRAIL)

	if ratio > 0.0:
		# Luôn chừa ít nhất 1px để con sắp chết vẫn thấy được chút máu.
		var fill_width := maxf(roundf(bar_size.x * ratio), 1.0)
		draw_rect(Rect2(left, 0.0, fill_width, bar_size.y), color_for_ratio(ratio))
		# Một dòng sáng mảnh ở mép trên cho thanh "có khối" mà vẫn phẳng.
		draw_rect(Rect2(left, 0.0, fill_width, 1.0), COLOR_HIGHLIGHT)

	if show_ticks:
		for tick in [0.25, 0.5, 0.75]:
			var x := roundf(left + bar_size.x * tick)
			draw_rect(Rect2(x, 0.0, 1.0, bar_size.y), COLOR_TICK)
