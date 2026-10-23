extends Control
## Màn hình tiêu đề: Chơi / Cài đặt / Xoá tiến độ / Thoát.

@onready var play_button: Button = %PlayButton
@onready var reset_button: Button = %ResetButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_menu: SettingsMenu = %SettingsMenu
@onready var quit_button: Button = %QuitButton
@onready var stars_label: Label = %StarsLabel
@onready var reset_dialog: ConfirmationDialog = %ResetDialog


func _ready() -> void:
	play_button.pressed.connect(GameManager.go_to_level_select)
	settings_button.pressed.connect(settings_menu.open)
	reset_button.pressed.connect(reset_dialog.popup_centered)
	reset_dialog.confirmed.connect(SaveManager.reset_progress)
	quit_button.pressed.connect(AudioManager.quit_game)
	# Trên trình duyệt (bản Web) không thể tự thoát game, nên ẩn nút Thoát.
	quit_button.visible = not OS.has_feature("web")
	SaveManager.progress_changed.connect(_refresh)
	_refresh()
	play_button.grab_focus()


func _refresh() -> void:
	var max_stars := GameManager.LEVEL_CATALOG.levels.size() * 3
	stars_label.text = "Tổng số sao: %d / %d    ·    Cấp %d    ·    %d Xu" % [SaveManager.get_total_stars(), max_stars,
			ProgressionManager.get_level(), EconomyManager.get_amount(EconomyManager.COINS)]
