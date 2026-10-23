extends Control
## Màn hình tiêu đề: Chơi / Cài đặt / Xoá tiến độ / Thoát.

@onready var play_button: Button = %PlayButton
@onready var reset_button: Button = %ResetButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_menu: SettingsMenu = %SettingsMenu
@onready var quit_button: Button = %QuitButton
@onready var stars_label: Label = %StarsLabel
@onready var reset_dialog: ConfirmationDialog = %ResetDialog

## Màn hình meta (dựng bằng code) + nút mở + chấm đỏ báo thưởng chưa nhận.
var achievements_screen: AchievementsScreen
var achievements_button: Button
var _achievements_dot: NotificationDot
var _last_meta_button: Button


func _ready() -> void:
	play_button.pressed.connect(GameManager.go_to_level_select)
	settings_button.pressed.connect(settings_menu.open)
	reset_button.pressed.connect(reset_dialog.popup_centered)
	reset_dialog.confirmed.connect(SaveManager.reset_progress)
	quit_button.pressed.connect(AudioManager.quit_game)
	# Trên trình duyệt (bản Web) không thể tự thoát game, nên ẩn nút Thoát.
	quit_button.visible = not OS.has_feature("web")
	achievements_screen = AchievementsScreen.new()
	add_child(achievements_screen)
	achievements_button = _add_menu_button("Thành tựu", achievements_screen)
	_achievements_dot = NotificationDot.attach(achievements_button)

	SaveManager.progress_changed.connect(_refresh)
	Events.claimables_changed.connect(_refresh)
	Events.currency_changed.connect(_refresh.unbind(2))
	_refresh()
	play_button.grab_focus()


func _refresh() -> void:
	var max_stars := GameManager.LEVEL_CATALOG.levels.size() * 3
	_achievements_dot.count = AchievementManager.get_unclaimed_count()
	stars_label.text = "Tổng số sao: %d / %d    ·    Cấp %d    ·    %d Xu" % [SaveManager.get_total_stars(), max_stars,
			ProgressionManager.get_level(), EconomyManager.get_amount(EconomyManager.COINS)]


## Thêm một nút mở màn hình meta ngay dưới nút Chơi (theo thứ tự gọi).
func _add_menu_button(text: String, screen: MetaScreen) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = settings_button.custom_minimum_size
	var anchor: Control = _last_meta_button if _last_meta_button else play_button
	anchor.add_sibling(button)
	_last_meta_button = button
	button.pressed.connect(screen.open)
	screen.closed.connect(func() -> void:
		_refresh()
		button.grab_focus())
	UiFx.setup_button(button)
	return button
