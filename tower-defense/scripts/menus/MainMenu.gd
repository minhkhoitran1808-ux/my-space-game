extends Control
## Menu chính (hub meta): thẻ hồ sơ (cấp, danh hiệu, KN, Xu, Bụi) ở góc trên trái,
## nút Chơi lớn, lưới các màn hình meta (Thành tựu / Kho đồ / Cửa hàng / Nhiệm vụ / Codex /
## Cài đặt) có chấm đỏ khi có thứ để nhận, rồi Xoá tiến độ / Thoát.
## Các màn hình meta dựng bằng code (MetaScreen) và mở chồng lên menu.

@onready var play_button: Button = %PlayButton
@onready var reset_button: Button = %ResetButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_menu: SettingsMenu = %SettingsMenu
@onready var quit_button: Button = %QuitButton
@onready var stars_label: Label = %StarsLabel
@onready var reset_dialog: ConfirmationDialog = %ResetDialog

var profile_chip: ProfileChip
var achievements_screen: AchievementsScreen
var inventory_screen: InventoryScreen
var shop_screen: ShopScreen
var quests_screen: QuestsScreen
var codex_screen: CodexScreen
var achievements_button: Button
var inventory_button: Button
var shop_button: Button
var quests_button: Button
var codex_button: Button

var _achievements_dot: NotificationDot
var _inventory_dot: NotificationDot
var _quests_dot: NotificationDot
var _meta_grid: GridContainer


func _ready() -> void:
	play_button.pressed.connect(GameManager.go_to_level_select)
	settings_button.pressed.connect(settings_menu.open)
	reset_button.pressed.connect(reset_dialog.popup_centered)
	reset_dialog.confirmed.connect(SaveManager.reset_progress)
	quit_button.pressed.connect(AudioManager.quit_game)
	# Trên trình duyệt (bản Web) không thể tự thoát game, nên ẩn nút Thoát.
	quit_button.visible = not OS.has_feature("web")
	DailyManager.refresh_day()

	profile_chip = ProfileChip.new()
	profile_chip.position = Vector2(20, 20)
	add_child(profile_chip)

	# Lưới 2 cột các màn hình meta, nằm ngay dưới nút Chơi; nút Cài đặt cũng chuyển vào lưới.
	_meta_grid = GridContainer.new()
	_meta_grid.columns = 2
	_meta_grid.add_theme_constant_override("h_separation", 10)
	_meta_grid.add_theme_constant_override("v_separation", 10)
	play_button.add_sibling(_meta_grid)
	achievements_screen = AchievementsScreen.new()
	achievements_button = _add_meta_button("Thành tựu", achievements_screen)
	_achievements_dot = NotificationDot.attach(achievements_button)
	inventory_screen = InventoryScreen.new()
	inventory_button = _add_meta_button("Kho đồ", inventory_screen)
	_inventory_dot = NotificationDot.attach(inventory_button)
	shop_screen = ShopScreen.new()
	shop_button = _add_meta_button("Cửa hàng", shop_screen)
	quests_screen = QuestsScreen.new()
	quests_button = _add_meta_button("Nhiệm vụ", quests_screen)
	_quests_dot = NotificationDot.attach(quests_button)
	codex_screen = CodexScreen.new()
	codex_button = _add_meta_button("Codex", codex_screen)
	settings_button.reparent(_meta_grid)
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.custom_minimum_size.x = 170

	SaveManager.progress_changed.connect(_refresh)
	Events.claimables_changed.connect(_refresh)
	Events.currency_changed.connect(_refresh.unbind(2))
	_refresh()
	play_button.grab_focus()


func _refresh() -> void:
	var max_stars := GameManager.LEVEL_CATALOG.levels.size() * 3
	stars_label.text = "Tổng số sao: %d / %d" % [SaveManager.get_total_stars(), max_stars]
	profile_chip.refresh()
	_achievements_dot.count = AchievementManager.get_unclaimed_count()
	_inventory_dot.count = InventoryManager.get_new_count()
	_quests_dot.count = DailyManager.get_claimable_count()


func _add_meta_button(text: String, screen: MetaScreen) -> Button:
	add_child(screen)
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(170, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_meta_grid.add_child(button)
	button.pressed.connect(screen.open)
	screen.closed.connect(func() -> void:
		_refresh()
		button.grab_focus())
	UiFx.setup_button(button)
	return button
