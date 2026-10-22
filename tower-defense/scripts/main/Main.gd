extends Node2D
## Scene gốc: "bảng mạch" nối các hệ thống lại với nhau.
##
## Các hệ thống (WaveManager, BuildManager, HUD) không biết nhau; Main kết nối
## signal của chúng. Nhờ vậy có thể thay/thêm hệ thống mà ít phải sửa code cũ.

@onready var wave_manager: WaveManager = $WaveManager
@onready var build_manager: BuildManager = $BuildManager
@onready var hud: HUD = $UI/HUD


func _ready() -> void:
	GameManager.reset(wave_manager.get_total_waves())

	hud.setup_tower_buttons(build_manager.available_towers)
	hud.start_wave_pressed.connect(_start_next_wave)
	hud.tower_selected.connect(build_manager.select_tower)
	hud.restart_pressed.connect(_restart)

	build_manager.build_mode_changed.connect(hud.set_selected_tower)
	build_manager.placement_failed.connect(hud.show_message)

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
	get_tree().paused = true
	hud.show_game_over(state == GameManager.GameState.VICTORY)
