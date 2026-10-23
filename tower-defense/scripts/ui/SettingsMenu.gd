class_name SettingsMenu
extends Control
## Bảng cài đặt: âm lượng, số sát thương, rung màn hình, toàn màn hình, xem lại hướng dẫn.
## Dùng chung cho menu chính và menu tạm dừng. Mọi thay đổi được lưu ngay qua SaveManager.
## Chạy cả khi game đang pause (process_mode = ALWAYS trong scene).

signal closed

@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var damage_numbers_check: CheckBox = %DamageNumbersCheck
@onready var screen_shake_check: CheckBox = %ScreenShakeCheck
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var tutorial_button: Button = %TutorialButton
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	volume_slider.value_changed.connect(_on_volume_changed)
	damage_numbers_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("damage_numbers", on))
	screen_shake_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("screen_shake", on))
	fullscreen_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("fullscreen", on))
	tutorial_button.pressed.connect(_on_tutorial_reset)
	close_button.pressed.connect(close)
	hide()


func open() -> void:
	# Đọc lại giá trị đã lưu mỗi lần mở (không phát signal để khỏi ghi file thừa).
	volume_slider.set_value_no_signal(float(SaveManager.get_setting("master_volume")) * 100.0)
	volume_value.text = "%d%%" % roundi(volume_slider.value)
	damage_numbers_check.set_pressed_no_signal(SaveManager.get_setting("damage_numbers"))
	screen_shake_check.set_pressed_no_signal(SaveManager.get_setting("screen_shake"))
	fullscreen_check.set_pressed_no_signal(SaveManager.get_setting("fullscreen"))
	tutorial_button.disabled = not SaveManager.get_flag(TutorialManager.DONE_FLAG)
	show()


func close() -> void:
	hide()
	closed.emit()


func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)
	SaveManager.set_setting("master_volume", value / 100.0)


func _on_tutorial_reset() -> void:
	SaveManager.set_flag(TutorialManager.DONE_FLAG, false)
	tutorial_button.disabled = true
	tutorial_button.text = "Hướng dẫn sẽ hiện ở màn 1"


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
