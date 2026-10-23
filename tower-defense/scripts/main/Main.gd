extends Node2D
## Scene gốc: "bảng mạch" nối các hệ thống lại với nhau.
##
## Các hệ thống (WaveManager, BuildManager, SelectionManager, FxManager, HUD) không biết nhau;
## Main kết nối signal của chúng. Nhờ vậy có thể thay/thêm hệ thống mà ít phải sửa code cũ.
##
## Khi vào trận, Main lấy màn đang chọn (GameManager.get_current_level()), nạp scene bản đồ
## vào node "Map" rồi đưa các làn đường cho Ground / BuildManager / WaveManager.
##
## Phím tắt chung (Main nhận SAU CÙNG, chỉ khi không hệ thống nào khác dùng phím đó):
##   Space: bắt đầu / gọi sớm wave   F: đổi tốc độ   P / Esc: tạm dừng

@onready var ground: Node2D = $Ground
@onready var map_root: Node2D = $Map
@onready var wave_manager: WaveManager = $WaveManager
@onready var build_manager: BuildManager = $BuildManager
@onready var selection_manager: SelectionManager = $SelectionManager
@onready var fx_manager: FxManager = $FxManager
@onready var ability_manager: AbilityManager = $AbilityManager
@onready var tutorial: TutorialManager = $TutorialManager
@onready var range_display: TowerRangeDisplay = $TowerRangeDisplay
@onready var hud: HUD = $UI/HUD
@onready var tower_info_panel: TowerInfoPanel = hud.tower_info_panel
@onready var pause_menu: PauseMenu = hud.pause_menu

## Màn đang chơi và bản đồ đã nạp.
var level: LevelData
var map: GameMap


func _ready() -> void:
	_load_level(GameManager.get_current_level())
	GameManager.reset(wave_manager.get_total_waves(), level.starting_gold, level.starting_lives)

	# HUD -> hệ thống
	hud.setup_tower_buttons(build_manager.available_towers)
	hud.setup_ability_buttons(ability_manager.abilities)
	hud.ability_pressed.connect(ability_manager.request)
	hud.start_wave_pressed.connect(_start_next_wave)
	hud.tower_selected.connect(build_manager.select_tower)
	hud.restart_pressed.connect(GameManager.restart_level)
	hud.next_level_pressed.connect(_go_to_next_level)
	hud.level_select_pressed.connect(GameManager.go_to_level_select)
	hud.speed_pressed.connect(GameManager.cycle_game_speed)
	hud.pause_pressed.connect(set_paused.bind(true))
	pause_menu.resume_requested.connect(set_paused.bind(false))
	pause_menu.restart_requested.connect(GameManager.restart_level)
	pause_menu.level_select_requested.connect(GameManager.go_to_level_select)
	pause_menu.settings_requested.connect(_open_settings_from_pause)
	hud.settings_menu.closed.connect(_on_settings_closed)

	# Xây tháp
	build_manager.build_mode_changed.connect(_on_build_mode_changed)
	build_manager.placement_failed.connect(hud.show_message)
	build_manager.tower_placed.connect(_on_tower_placed)
	build_manager.tower_upgraded.connect(_on_tower_upgraded)
	build_manager.tower_sold.connect(_on_tower_sold)

	# Hiển thị tầm bắn + ghost tháp (chỉ nghe signal, không đổi logic đặt tháp)
	range_display.setup(build_manager, selection_manager)
	tower_info_panel.upgrade_hovered.connect(range_display.show_upgrade_preview)

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
	wave_manager.spawning_finished.connect(_refresh_wave_button.unbind(1))
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.wave_called_early.connect(_on_wave_called_early)

	# Kỹ năng
	ability_manager.targeting_changed.connect(_on_ability_targeting_changed)
	ability_manager.cooldown_changed.connect(hud.update_ability_cooldown)
	ability_manager.ability_failed.connect(hud.show_message)
	ability_manager.ability_cast.connect(_on_ability_cast)

	# Hiệu ứng
	wave_manager.enemy_spawned.connect(fx_manager.track_enemy)
	wave_manager.enemy_spawned.connect(func(enemy: Enemy) -> void:
		if enemy.data.elite:
			hud.boss_bar.track(enemy))
	wave_manager.enemy_spawned.connect(_announce_new_enemy)
	fx_manager.track_projectile_container(build_manager.projectile_container)

	GameManager.state_changed.connect(_on_game_state_changed)

	# Hướng dẫn: các hệ thống không biết tới nó, Main chỉ chuyển tiếp sự kiện.
	tutorial.step_changed.connect(hud.show_tutorial_step)
	hud.tutorial_skip_pressed.connect(tutorial.skip)
	build_manager.tower_placed.connect(tutorial.notify.bind(&"tower_placed").unbind(1))
	build_manager.tower_upgraded.connect(tutorial.notify.bind(&"tower_upgraded").unbind(1))
	wave_manager.wave_started.connect(tutorial.notify.bind(&"wave_started").unbind(1))
	ability_manager.ability_cast.connect(tutorial.notify.bind(&"ability_cast").unbind(2))
	selection_manager.selection_changed.connect(func(tower: Tower) -> void:
		if tower:
			tutorial.notify(&"tower_selected"))
	if not GameManager.endless_mode and GameManager.LEVEL_CATALOG.get_level_index(level) == 0:
		tutorial.start()

	# Chọn sẵn tháp đầu tiên để vào game là đặt được ngay.
	if not build_manager.available_towers.is_empty():
		build_manager.select_tower(build_manager.available_towers[0])
	_refresh_wave_button()
	var intro := "%s - Vô tận" % level.display_name if GameManager.endless_mode \
			else "%s - %d wave" % [level.display_name, wave_manager.get_total_waves()]
	hud.show_message(intro, Color(0.6, 0.85, 1.0))


## Nạp bản đồ của màn và giao các làn đường cho những hệ thống cần chúng.
func _load_level(p_level: LevelData) -> void:
	level = p_level
	map = level.map_scene.instantiate() as GameMap
	map_root.add_child(map)
	var paths := map.get_paths()
	ground.setup(paths)
	build_manager.paths = paths
	if GameManager.endless_mode:
		wave_manager.setup_endless(String(level.id), paths, map.get_air_paths())
	else:
		wave_manager.setup(level.waves_file, paths, map.get_air_paths())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_SPACE:
			_start_next_wave()
		KEY_F:
			GameManager.cycle_game_speed()
		KEY_P, KEY_ESCAPE:
			# Esc chỉ tới được đây khi không đang xây và không chọn tháp nào.
			set_paused(true)
		_:
			return
	get_viewport().set_input_as_handled()


## Mở / đóng menu tạm dừng.
func set_paused(paused: bool) -> void:
	if not GameManager.is_playing():
		return
	get_tree().paused = paused
	pause_menu.visible = paused


## Mở cài đặt từ menu tạm dừng: tạm ẩn menu tạm dừng để hai bảng không chồng lên nhau.
func _open_settings_from_pause() -> void:
	pause_menu.hide()
	hud.settings_menu.open()


func _on_settings_closed() -> void:
	if get_tree().paused and GameManager.is_playing():
		pause_menu.show()


func _start_next_wave() -> void:
	wave_manager.start_next_wave()


func _go_to_next_level() -> void:
	var next := GameManager.get_next_level()
	if next:
		GameManager.start_level(next)


func _refresh_wave_button() -> void:
	var next_wave := wave_manager.get_current_wave_number() + 1
	hud.update_wave_button(
			wave_manager.can_start_next_wave(),
			next_wave,
			wave_manager.has_more_waves(),
			wave_manager.is_early_call(),
			wave_manager.get_early_call_bonus())
	hud.set_next_wave_preview(next_wave, wave_manager.get_wave_composition(next_wave))


func _upgrade_selected_tower() -> void:
	if selection_manager.has_selection():
		build_manager.upgrade_tower(selection_manager.selected_tower)


func _sell_selected_tower() -> void:
	if selection_manager.has_selection():
		build_manager.sell_tower(selection_manager.selected_tower)


func _on_build_mode_changed(tower_data: TowerData) -> void:
	hud.set_selected_tower(tower_data)
	# Vào chế độ xây thì bỏ chọn tháp đang xem và thôi ngắm kỹ năng.
	if tower_data != null:
		selection_manager.deselect()
		ability_manager.cancel_targeting()


## Đang ngắm kỹ năng thì thoát chế độ xây / bỏ chọn tháp để click không bị nhầm.
func _on_ability_targeting_changed(ability: AbilityData) -> void:
	hud.set_targeting_ability(ability)
	if ability != null:
		build_manager.cancel_build()
		selection_manager.deselect()


## Lần đầu gặp một loại địch có mẹo (EnemyData.hint): hiện giới thiệu ngắn, chỉ một lần mỗi file save.
func _announce_new_enemy(enemy: Enemy) -> void:
	var data := enemy.data
	var flag := "seen_enemy_%s" % data.id
	if data.hint.is_empty() or SaveManager.get_flag(flag):
		return
	SaveManager.set_flag(flag, true)
	hud.show_message("Địch mới: %s - %s" % [data.display_name, data.hint], Color(1.0, 0.85, 0.4))


func _on_ability_cast(ability: AbilityData, cast_position: Vector2) -> void:
	fx_manager.play_ability(ability, cast_position)
	hud.show_message("%s!" % ability.display_name, ability.color)


func _on_tower_placed(tower: Tower) -> void:
	fx_manager.track_tower(tower)
	AudioManager.play(&"build")


func _on_tower_upgraded(tower: Tower) -> void:
	hud.show_message("%s lên cấp %d!" % [tower.data.display_name, tower.get_level()], Color(1.0, 0.85, 0.3))
	AudioManager.play(&"upgrade")


func _on_tower_sold(tower: Tower, refund: int) -> void:
	hud.show_message("Đã bán %s: +%d vàng" % [tower.data.display_name, refund], Color(1.0, 0.85, 0.3))
	AudioManager.play(&"sell")


func _on_wave_started(wave_number: int) -> void:
	hud.show_message("Wave %d bắt đầu!" % wave_number, Color(1.0, 0.8, 0.4))
	AudioManager.play(&"wave_start")
	_refresh_wave_button()


func _on_wave_called_early(wave_number: int, bonus: int) -> void:
	hud.show_message("Gọi sớm wave %d! +%d vàng" % [wave_number, bonus], Color(1.0, 0.85, 0.3))


func _on_wave_completed(wave_number: int, reward_bonus: int) -> void:
	if reward_bonus > 0:
		hud.show_message("Hoàn thành wave %d! +%d vàng" % [wave_number, reward_bonus], Color(0.5, 1.0, 0.5))
	AudioManager.play(&"wave_complete")
	_refresh_wave_button()


func _on_game_state_changed(state: GameManager.GameState) -> void:
	if state == GameManager.GameState.PLAYING:
		return
	var victory := state == GameManager.GameState.VICTORY
	var stars := GameManager.calculate_stars()
	if victory:
		SaveManager.record_result(level.id, stars)
	build_manager.cancel_build()
	selection_manager.deselect()
	ability_manager.cancel_targeting()
	pause_menu.hide()
	get_tree().paused = true
	if GameManager.endless_mode:
		var wave := wave_manager.get_current_wave_number()
		var new_record := SaveManager.record_endless(level.id, wave)
		hud.show_endless_over(wave, SaveManager.get_endless_best(level.id), new_record)
	else:
		hud.show_game_over(victory, stars, GameManager.lives, GameManager.starting_lives,
				victory and GameManager.get_next_level() != null)
	AudioManager.play(&"victory" if victory else &"defeat")
