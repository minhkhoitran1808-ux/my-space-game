class_name PauseMenu
extends Control
## Menu tạm dừng. Chạy cả khi game đang pause (process_mode = ALWAYS trong scene).
##
## Menu chỉ phát signal; Main quyết định pause / chơi lại / về màn chọn màn.
## Khi menu đang mở, phím P hoặc Esc sẽ đóng menu (tiếp tục chơi).

signal resume_requested
signal restart_requested
signal level_select_requested
signal settings_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	resume_button.pressed.connect(resume_requested.emit)
	restart_button.pressed.connect(restart_requested.emit)
	level_select_button.pressed.connect(level_select_requested.emit)
	settings_button.pressed.connect(settings_requested.emit)
	hide()


## SettingsMenu nằm sau PauseMenu trong HUD nên khi nó đang mở, nó nhận Esc trước.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_P or event.keycode == KEY_ESCAPE):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
