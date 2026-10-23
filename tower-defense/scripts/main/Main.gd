extends Node2D
## Scene gốc: "bảng mạch" nối các hệ thống lại với nhau.
##
## Các hệ thống (WaveManager, BuildManager, SelectionManager, HUD) không biết nhau;
## Main kết nối signal của chúng. Nhờ vậy có thể thay/thêm hệ thống mà ít phải sửa code cũ.

@onready var wave_manager: WaveManager = $WaveManager
@onready var build_manager: BuildManager = $BuildManager
@onready var selection_manager: SelectionManager = $SelectionManager
@onready var hud: HUD = $UI/HUD
@onready var tower_info_panel: TowerInfoPanel = hud.tower_info_panel


func _ready() -> void:
	GameManager.reset(wave_manager.get_total_waves())

	# HUD -> hệ thống
	hud.setup_tower_buttons(build_manager.available_towers)
	hud.start_wave_pressed.connect(_start_next_wave)
	hud.tower_selected.connect(build_manager.select_tower)
	hud.restart_pressed.connect(_restart)

	# Xây tháp
	build_manager.build_mode_changed.connect(_on_build_mode_changed)
	build_manager.placement_failed.connect(hud.show_message)
	build_manager.tower_upgraded.connect(_on_tower_upgraded)
	build_manager.tower_sold.connect(_on_tower_sold)

	# Chọn tháp + bảng thông tin
	selection_manager.selection_changed.connect(tower_info_panel.show_tower)
	selection_manager.upgrade_requested.connect(build_manager.upgrade_tower)
	selection_manager.sell_requested.connect(build_manager.sell_tower)
	tower_info_panel.upgrade_requested.connect(_upgrade_selected_tower)
	tower_info_panel.sell_requested.connect(_sell_selected_tower)
	tower_info_panel.target_mode_selected.connect(selection_manager.set_target_mode)
	tower_info_panel.close_requested.connect(selection_manager.deselect)

	# Wave
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)

	GameManager.state_changed.connect(_on_game_state_changed)

	# Chọn sẵn tháp đầu tiên để vào game là đặt được ngay.
	if not build_manager.available_towers.is_empty():
		build_manager.select_tower(build_manager.available_towers[0])
	_refresh_wave_button()


func _unhandled_input(event: InputEvent) -> void:
	# Phím Space: bắt đầu wave tiếp theo.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_start_next_wave()
		get_viewport().set_input_as_handled()


func _start_next_wave() -> void:
	wave_manager.start_next_wave()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _refresh_wave_button() -> void:
	hud.update_wave_button(
			wave_manager.can_start_next_wave(),
			wave_manager.get_current_wave_number() + 1,
			wave_manager.has_more_waves())


func _upgrade_selected_tower() -> void:
	if selection_manager.has_selection():
		build_manager.upgrade_tower(selection_manager.selected_tower)


func _sell_selected_tower() -> void:
	if selection_manager.has_selection():
		build_manager.sell_tower(selection_manager.selected_tower)


func _on_build_mode_changed(tower_data: TowerData) -> void:
	hud.set_selected_tower(tower_data)
	# Vào chế độ xây thì bỏ chọn tháp đang xem.
	if tower_data != null:
		selection_manager.deselect()


func _on_tower_upgraded(tower: Tower) -> void:
	hud.show_message("%s lên cấp %d!" % [tower.data.display_name, tower.get_level()], Color(1.0, 0.85, 0.3))


func _on_tower_sold(tower: Tower, refund: int) -> void:
	hud.show_message("Đã bán %s: +%d vàng" % [tower.data.display_name, refund], Color(1.0, 0.85, 0.3))


func _on_wave_started(wave_number: int) -> void:
	hud.show_message("Wave %d bắt đầu!" % wave_number, Color(1.0, 0.8, 0.4))
	_refresh_wave_button()


func _on_wave_completed(wave_number: int, reward_bonus: int) -> void:
	if reward_bonus > 0:
		hud.show_message("Hoàn thành wave %d! +%d vàng" % [wave_number, reward_bonus], Color(0.5, 1.0, 0.5))
	_refresh_wave_button()


func _on_game_state_changed(state: GameManager.GameState) -> void:
	if state == GameManager.GameState.PLAYING:
		return
	build_manager.cancel_build()
	selection_manager.deselect()
	get_tree().paused = true
	hud.show_game_over(state == GameManager.GameState.VICTORY)
