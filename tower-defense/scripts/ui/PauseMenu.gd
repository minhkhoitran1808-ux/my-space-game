class_name PauseMenu
extends Control
## Menu tạm dừng. Chạy cả khi game đang pause (process_mode = ALWAYS trong scene).
##
## Menu chỉ phát signal; Main quyết định pause / chơi lại / thoát.
## Khi menu đang mở, phím P hoặc Esc sẽ đóng menu (tiếp tục chơi).

signal resume_requested
signal restart_requested
signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	resume_button.pressed.connect(resume_requested.emit)
	restart_button.pressed.connect(restart_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_P or event.keycode == KEY_ESCAPE):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
