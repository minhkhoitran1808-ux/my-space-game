class_name RangeIndicator
extends Node2D
## Vòng tầm bắn: fill rất nhạt + viền 2px rõ nét + halo tối 1px, có nhiều trạng thái.
##
## Mỗi trạng thái khác nhau ở CẢ màu lẫn hình dạng (không chỉ dựa vào màu, để người mù màu
## vẫn phân biệt được): VALID viền liền xanh, INVALID viền đứt nét cam đỏ (+ ✕ do ghost vẽ),
## SELECTED viền trắng, UPGRADE_PREVIEW viền trắng đứt nét không fill.
##
## Thứ tự vẽ: phần FILL vẽ trên chính node này (đặt dưới địch trong cây node), còn VIỀN
## nằm ở node con "_stroke" có z_index = 1 nên luôn nổi trên địch / đạn. Nhờ vậy fill
## không làm mờ địch mà ranh giới thì không bao giờ bị che.
##
## Giảm chuyển động (VisualSettings.reduced_motion): bỏ phóng to khi xuất hiện, bỏ nhịp sáng
## và bỏ xoay viền đứt nét; trạng thái vẫn phân biệt bằng màu + kiểu nét như thường.
##
## Chỉ vẽ lại khi có thay đổi (đổi trạng thái / bán kính / đang chạy animation),
## không vẽ lại mỗi frame khi đứng yên.

enum State { HIDDEN, VALID, INVALID, SELECTED, UPGRADE_PREVIEW, NEIGHBOR }

## Toàn bộ thông số hiển thị đặt ở một chỗ để chỉnh tập trung (bảng màu Okabe-Ito).
const STYLE := {
	State.VALID: {"stroke": Color("#56B4E9"), "stroke_alpha": 0.9, "fill_alpha": 0.15, "dashed": false, "width": 2.0},
	State.INVALID: {"stroke": Color("#D55E00"), "stroke_alpha": 0.9, "fill_alpha": 0.15, "dashed": true, "width": 2.0},
	State.SELECTED: {"stroke": Color("#FFFFFF"), "stroke_alpha": 0.9, "fill_alpha": 0.10, "dashed": false, "width": 2.0},
	State.UPGRADE_PREVIEW: {"stroke": Color("#FFFFFF"), "stroke_alpha": 0.6, "fill_alpha": 0.0, "dashed": true, "width": 2.0},
	State.NEIGHBOR: {"stroke": Color("#FFFFFF"), "stroke_alpha": 0.25, "fill_alpha": 0.0, "dashed": false, "width": 1.0},
}
const HALO_COLOR := Color(0.043, 0.071, 0.125, 0.5) # #0B1220
const HALO_WIDTH := 1.0
## Số điểm cho vòng tròn mịn.
const POINT_COUNT := 128
## Viền đứt nét: độ dài nét và khoảng hở (pixel, đo theo chu vi).
const DASH_LENGTH := 10.0
const DASH_GAP := 6.0
## Viền đứt nét xoay rất chậm (độ / giây) để báo "trạng thái tạm".
const DASH_SPIN_DEG := 20.0

const APPEAR_TIME := 0.15
const DISAPPEAR_TIME := 0.10
const COLOR_BLEND_TIME := 0.08
## Pulse chỉ cho SELECTED: alpha viền 0.75 <-> 1.0, chu kỳ 1.6s.
const PULSE_PERIOD := 1.6

## Bán kính hiện tại (pixel). Đổi bán kính có animation nhỏ: dùng set_radius().
var radius: float = 100.0
var state: State = State.HIDDEN

# Màu đang vẽ = lerp(_from, _to, _blend) để đổi VALID <-> INVALID mượt trong 0.08s.
var _from_style: Dictionary = STYLE[State.VALID]
var _to_style: Dictionary = STYLE[State.VALID]
var _blend := 1.0
var _pulse := 1.0
var _dash_offset := 0.0
var _stroke: Node2D
var _appear_tween: Tween
var _blend_tween: Tween
var _pulse_tween: Tween
var _radius_tween: Tween


func _ready() -> void:
	_stroke = Node2D.new()
	_stroke.name = "Stroke"
	_stroke.z_index = 1
	_stroke.draw.connect(_draw_stroke)
	add_child(_stroke)
	visible = false
	set_process(false)


## Hiện vòng ở trạng thái mới. Nếu đang ẩn thì chạy animation xuất hiện (0.15s).
func show_ring(new_state: State, new_radius: float) -> void:
	var was_hidden := state == State.HIDDEN or not visible
	_set_radius_now(new_radius)
	set_state(new_state, not was_hidden)
	if was_hidden:
		visible = true
		_kill(_appear_tween)
		_appear_tween = create_tween().set_parallel()
		scale = Vector2.ONE
		if not VisualSettings.reduced_motion:
			_appear_tween.tween_property(self, "scale", Vector2.ONE, APPEAR_TIME).from(Vector2.ONE * 0.85) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_appear_tween.tween_property(self, "modulate:a", 1.0, APPEAR_TIME).from(0.0)


## Ẩn vòng (fade 0.10s).
func hide_ring() -> void:
	if state == State.HIDDEN:
		return
	state = State.HIDDEN
	_kill(_pulse_tween)
	set_process(false)
	_kill(_appear_tween)
	_appear_tween = create_tween()
	_appear_tween.tween_property(self, "modulate:a", 0.0, DISAPPEAR_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_appear_tween.tween_callback(hide)


## Đổi trạng thái; animate = true thì lerp màu trong 0.08s.
func set_state(new_state: State, animate: bool = true) -> void:
	if new_state == State.HIDDEN:
		hide_ring()
		return
	if new_state == state and visible:
		return
	state = new_state
	_from_style = _current_style()
	_to_style = STYLE[new_state]
	_kill(_blend_tween)
	if animate:
		_blend = 0.0
		_blend_tween = create_tween()
		_blend_tween.tween_method(_set_blend, 0.0, 1.0, COLOR_BLEND_TIME)
	else:
		_set_blend(1.0)

	# Pulse rất nhẹ chỉ cho SELECTED; viền đứt nét thì xoay chậm.
	_kill(_pulse_tween)
	_pulse = 1.0
	if new_state == State.SELECTED and not VisualSettings.reduced_motion:
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_method(_set_pulse, 1.0, 0.75, PULSE_PERIOD * 0.5).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_method(_set_pulse, 0.75, 1.0, PULSE_PERIOD * 0.5).set_trans(Tween.TRANS_SINE)
	set_process(_to_style.dashed and not VisualSettings.reduced_motion)
	_redraw()


## Đổi bán kính (vd tháp vừa nâng cấp) với animation ngắn.
func set_radius(new_radius: float) -> void:
	_kill(_radius_tween)
	_radius_tween = create_tween()
	_radius_tween.tween_method(_set_radius_now, radius, new_radius, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_shown() -> bool:
	return state != State.HIDDEN


func _process(delta: float) -> void:
	_dash_offset = wrapf(_dash_offset + deg_to_rad(DASH_SPIN_DEG) * delta, 0.0, TAU)
	_stroke.queue_redraw()


# --- Vẽ ---------------------------------------------------------------------------

## Fill (nằm dưới địch).
func _draw() -> void:
	var style := _current_style()
	if style.fill_alpha > 0.0:
		draw_circle(Vector2.ZERO, radius, Color(style.stroke, style.fill_alpha), true, -1.0, true)


## Halo + viền (node con z_index = 1, nằm trên địch).
func _draw_stroke() -> void:
	var style := _current_style()
	var width: float = style.width
	var color := Color(style.stroke, style.stroke_alpha * _pulse)
	# Halo tối ngay ngoài viền chính: giúp vòng nổi trên cả nền sáng lẫn tối.
	var halo_radius := radius + width * 0.5 + HALO_WIDTH * 0.5
	if _to_style.dashed:
		_draw_dashed(_stroke, halo_radius, HALO_COLOR, HALO_WIDTH)
		_draw_dashed(_stroke, radius, color, width)
	else:
		_stroke.draw_arc(Vector2.ZERO, halo_radius, 0.0, TAU, POINT_COUNT, HALO_COLOR, HALO_WIDTH, true)
		_stroke.draw_arc(Vector2.ZERO, radius, 0.0, TAU, POINT_COUNT, color, width, true)


func _draw_dashed(canvas: CanvasItem, ring_radius: float, color: Color, width: float) -> void:
	var step := (DASH_LENGTH + DASH_GAP) / ring_radius
	var dash := DASH_LENGTH / ring_radius
	var count := maxi(8, floori(TAU / step))
	step = TAU / count # Chia đều để nét cuối không bị chồng nét đầu.
	for i in count:
		var start := _dash_offset + i * step
		canvas.draw_arc(Vector2.ZERO, ring_radius, start, start + dash, 6, color, width, true)


# --- Tiện ích -------------------------------------------------------------------

func _current_style() -> Dictionary:
	if _blend >= 1.0:
		return _to_style
	return {
		"stroke": (_from_style.stroke as Color).lerp(_to_style.stroke, _blend),
		"stroke_alpha": lerpf(_from_style.stroke_alpha, _to_style.stroke_alpha, _blend),
		"fill_alpha": lerpf(_from_style.fill_alpha, _to_style.fill_alpha, _blend),
		"dashed": _to_style.dashed,
		"width": lerpf(_from_style.width, _to_style.width, _blend),
	}


func _set_blend(value: float) -> void:
	_blend = value
	_redraw()


func _set_pulse(value: float) -> void:
	_pulse = value
	_stroke.queue_redraw()


func _set_radius_now(value: float) -> void:
	radius = value
	_redraw()


func _redraw() -> void:
	queue_redraw()
	if _stroke:
		_stroke.queue_redraw()


func _kill(tween: Tween) -> void:
	if tween and tween.is_valid():
		tween.kill()
