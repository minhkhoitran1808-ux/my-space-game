class_name UiFx
extends RefCounted
## Hiệu ứng UI dùng chung (tween), tách khỏi HUD để menu khác cũng dùng lại được.
##
## Mọi tween được tạo trên chính Control nhận hiệu ứng, nên tự chạy theo process_mode của
## Control đó (vd panel thắng / thua có process_mode = ALWAYS vẫn animate khi game đang pause).

const HOVER_SCALE := 1.05
const PRESS_SCALE := 0.96
const HOVER_TIME := 0.1


## Gắn hiệu ứng cho nút: phóng to nhẹ khi hover, lún khi nhấn, rung khi bấm vào nút đang khoá.
static func setup_button(button: BaseButton) -> void:
	if button.has_meta(&"ui_fx"):
		return
	button.set_meta(&"ui_fx", true)
	_keep_pivot_centered(button)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			tween_scale(button, HOVER_SCALE, HOVER_TIME))
	button.mouse_exited.connect(func() -> void: tween_scale(button, 1.0, HOVER_TIME))
	button.button_down.connect(func() -> void: tween_scale(button, PRESS_SCALE, 0.05))
	button.button_up.connect(func() -> void:
		tween_scale(button, HOVER_SCALE if button.is_hovered() else 1.0, HOVER_TIME))
	# Nút bị khoá không phát "pressed", nhưng vẫn nhận gui_input => rung nhẹ để báo "không bấm được".
	button.gui_input.connect(func(event: InputEvent) -> void:
		if button.disabled and event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			shake(button))


## Phóng to rồi thu về (dùng khi số liệu thay đổi).
static func pulse(control: Control, peak: float = 1.18, duration: float = 0.25) -> void:
	_keep_pivot_centered(control)
	var tween := _restart_tween(control, &"pulse")
	control.scale = Vector2.ONE * peak
	tween.tween_property(control, "scale", Vector2.ONE, duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Nhấp nháy một màu rồi trở về màu gốc (dùng modulate để không đụng màu chữ trong theme).
static func flash(control: CanvasItem, color: Color, duration: float = 0.5, times: int = 2) -> void:
	var tween := _restart_tween(control, &"flash")
	var step := duration / (times * 2.0)
	for i in times:
		tween.tween_property(control, "modulate", color, step)
		tween.tween_property(control, "modulate", Color.WHITE, step)


## Rung ngang 100ms (dùng khi bấm vào nút đang khoá).
static func shake(control: Control, strength: float = 5.0) -> void:
	# Đang rung dở thì giữ vị trí gốc cũ, tránh nút bị trôi khi bấm liên tục.
	var running: Tween = control.get_meta(&"ui_fx_tween_shake", null)
	var origin: float = control.get_meta(&"ui_fx_shake_origin") if running and running.is_running() \
			else control.position.x
	control.set_meta(&"ui_fx_shake_origin", origin)
	var tween := _restart_tween(control, &"shake")
	for offset in [strength, -strength, strength * 0.5, 0.0]:
		tween.tween_property(control, "position:x", origin + offset, 0.025)


static func tween_scale(control: Control, target: float, duration: float) -> void:
	var tween := _restart_tween(control, &"scale")
	tween.tween_property(control, "scale", Vector2.ONE * target, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Scale quanh tâm thay vì góc trên-trái (cập nhật lại mỗi khi Control đổi kích thước).
static func _keep_pivot_centered(control: Control) -> void:
	if control.has_meta(&"ui_fx_pivot"):
		return
	control.set_meta(&"ui_fx_pivot", true)
	control.pivot_offset = control.size * 0.5
	control.resized.connect(func() -> void: control.pivot_offset = control.size * 0.5)


## Mỗi loại hiệu ứng trên một Control chỉ có 1 tween chạy; tween cũ bị huỷ khi có tween mới.
static func _restart_tween(control: CanvasItem, key: StringName) -> Tween:
	var meta_key := StringName("ui_fx_tween_%s" % key)
	if control.has_meta(meta_key):
		var old: Tween = control.get_meta(meta_key)
		if old and old.is_valid():
			old.kill()
	var tween := control.create_tween()
	control.set_meta(meta_key, tween)
	return tween
