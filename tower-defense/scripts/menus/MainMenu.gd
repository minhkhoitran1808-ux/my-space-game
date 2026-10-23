extends Control
## Màn hình tiêu đề: Chơi / Xoá tiến độ / Thoát.

@onready var play_button: Button = %PlayButton
@onready var reset_button: Button = %ResetButton
@onready var quit_button: Button = %QuitButton
@onready var stars_label: Label = %StarsLabel
@onready var reset_dialog: ConfirmationDialog = %ResetDialog


func _ready() -> void:
	play_button.pressed.connect(GameManager.go_to_level_select)
	reset_button.pressed.connect(reset_dialog.popup_centered)
	reset_dialog.confirmed.connect(SaveManager.reset_progress)
	quit_button.pressed.connect(get_tree().quit)
	SaveManager.progress_changed.connect(_refresh)
	_refresh()
	play_button.grab_focus()


func _refresh() -> void:
	var max_stars := GameManager.LEVEL_CATALOG.levels.size() * 3
	stars_label.text = "Tổng số sao: %d / %d" % [SaveManager.get_total_stars(), max_stars]
