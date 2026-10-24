class_name SettingsMenu
extends Control
## Bảng cài đặt: âm lượng, số sát thương, rung màn hình, toàn màn hình, xem lại hướng dẫn,
## nhóm hiển thị / hỗ trợ (nháy khi trúng đòn, thanh máu, giảm chuyển động, màu mù màu)
## và đồ hoạ trận đấu (3D hình khối hoặc 2D, bóng đổ).
## Dùng chung cho menu chính và menu tạm dừng. Mọi thay đổi được lưu ngay qua SaveManager.
## Chạy cả khi game đang pause (process_mode = ALWAYS trong scene).

signal closed

@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var damage_numbers_check: CheckBox = %DamageNumbersCheck
@onready var screen_shake_check: CheckBox = %ScreenShakeCheck
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var hit_flash_option: OptionButton = %HitFlashOption
@onready var health_bar_option: OptionButton = %HealthBarOption
@onready var reduced_motion_check: CheckBox = %ReducedMotionCheck
@onready var colorblind_check: CheckBox = %ColorblindCheck
@onready var view_3d_check: CheckBox = %View3DCheck
@onready var shadows_3d_check: CheckBox = %Shadows3DCheck
@onready var tutorial_button: Button = %TutorialButton
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	volume_slider.value_changed.connect(_on_volume_changed)
	damage_numbers_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("damage_numbers", on))
	screen_shake_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("screen_shake", on))
	fullscreen_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("fullscreen", on))
	for item in VisualSettings.HIT_FLASH_NAMES:
		hit_flash_option.add_item(item)
	for item in VisualSettings.HEALTH_BAR_NAMES:
		health_bar_option.add_item(item)
	hit_flash_option.item_selected.connect(func(index: int) -> void: SaveManager.set_setting("hit_flash", index))
	health_bar_option.item_selected.connect(func(index: int) -> void: SaveManager.set_setting("health_bar_mode", index))
	reduced_motion_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("reduced_motion", on))
	colorblind_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("colorblind", on))
	view_3d_check.toggled.connect(func(on: bool) -> void:
		SaveManager.set_setting("view_3d", on)
		shadows_3d_check.disabled = not on)
	shadows_3d_check.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("shadows_3d", on))
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
	hit_flash_option.select(int(SaveManager.get_setting("hit_flash")))
	health_bar_option.select(int(SaveManager.get_setting("health_bar_mode")))
	reduced_motion_check.set_pressed_no_signal(SaveManager.get_setting("reduced_motion"))
	colorblind_check.set_pressed_no_signal(SaveManager.get_setting("colorblind"))
	view_3d_check.set_pressed_no_signal(SaveManager.get_setting("view_3d"))
	shadows_3d_check.set_pressed_no_signal(SaveManager.get_setting("shadows_3d"))
	shadows_3d_check.disabled = not view_3d_check.button_pressed
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
