extends Node
## Smoke test tự động: chứng minh game vẫn chơi được sau mỗi lần sửa code.
##
## Chạy (không cần mở editor):
##   godot --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn
## --fixed-fps 60 giúp mô phỏng chạy nhanh hết mức nhưng vẫn đúng như 60 FPS.
## Kết thúc với exit code 0 nếu tất cả đều đạt, 1 nếu có lỗi.
##
## Gồm các phần (mỗi phần dùng một bản Main mới):
##   1. Kiểm tra từng hệ thống (kháng sát thương, làm chậm, đặt tháp, dữ liệu wave,
##      nâng cấp / bán, chọn tháp bằng chuột và phím tắt...).
##      Nhịp trận: tốc độ game, tạm dừng, xem trước wave, gọi wave sớm, hiệu ứng, âm thanh.
##      Luồng màn: menu, chọn màn, khoá / mở màn, lưu sao.
##   2. Với MỖI màn: bot tự chọn ô có độ phủ đường đi tốt nhất, nâng cấp khi dư tiền,
##      và phải THẮNG. Bot không cần biết trước bản đồ nên áp dụng được cho màn mới.
##   3. Với MỖI màn: không đặt tháp nào thì phải THUA (đảm bảo game không quá dễ).
##
## Test dùng file save riêng và chặn việc đổi scene thật (GameManager.block_scene_changes).

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const LEVEL_SELECT_SCENE := preload("res://scenes/menus/LevelSelect.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/menus/MainMenu.tscn")
const TEST_SAVE_PATH := "user://smoke_test_save.cfg"
## Giới hạn số frame cho mỗi lượt chơi để test không bao giờ treo.
const MAX_FRAMES_PER_RUN := 60 * 60 * 40

## Thứ tự loại tháp bot mua (0 = Cung thủ, 1 = Pháo, 2 = Băng, 3 = Phép), lặp lại khi hết.
const BOT_TOWER_ROTATION := [0, 0, 2, 1, 3, 0, 1, 3, 2, 3, 1, 3]
## Bot xây tối đa chừng này tháp, sau đó dồn tiền nâng cấp.
const BOT_MAX_TOWERS := 18

var _failures := PackedStringArray()


func _ready() -> void:
	print("=== SMOKE TEST ===")
	GameManager.block_scene_changes = true
	SaveManager.save_path = TEST_SAVE_PATH
	SaveManager.reset_progress()

	await _test_systems()
	await _test_tower_management()
	await _test_match_flow()
	await _test_level_flow()
	for level in GameManager.LEVEL_CATALOG.levels:
		await _test_bot_playthrough(level)
	for level in GameManager.LEVEL_CATALOG.levels:
		await _test_defeat_without_towers(level)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	if _failures.is_empty():
		print("=== SMOKE TEST PASSED ===")
		get_tree().quit(0)
	else:
		print("=== SMOKE TEST FAILED (%d) ===" % _failures.size())
		for failure in _failures:
			print("  - ", failure)
		get_tree().quit(1)


# --- Phần 1: từng hệ thống ------------------------------------------------------

func _test_systems() -> void:
	print("[1] Kiểm tra hệ thống")
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var waves: WaveManager = main.wave_manager
	var path: Path2D = main.map.get_paths()[0]

	# Dữ liệu wave
	_check(waves.validate_waves().is_empty(), "file wave màn 1 hợp lệ: %s" % [waves.validate_waves()])
	_check(waves.get_total_waves() == 10, "có 10 wave (thực tế %d)" % waves.get_total_waves())
	for id in [&"basic", &"fast", &"armored", &"swarm", &"boss"]:
		_check(waves.get_enemy_type(id) != null, "có loại địch '%s'" % id)

	# Luật đặt tháp
	var archer: TowerData = build.available_towers[0]
	_check(build.available_towers.size() == 4, "có 4 loại tháp")
	_check(build.get_placement_error(Vector2i(3, 2), archer) != "", "không xây được trên đường")
	_check(build.get_placement_error(Vector2i(5, 0), archer) != "", "không xây được ở thanh UI trên")
	_check(build.get_placement_error(Vector2i(5, 10), archer) != "", "không xây được ở thanh UI dưới")
	_check(build.get_placement_error(Vector2i(4, 4), archer) == "", "xây được ở ô cỏ trống")

	# Kháng sát thương: Bọc thép giảm 60% vật lý, không giảm phép.
	var armored := _spawn_test_enemy(path, waves.get_enemy_type(&"armored"))
	var physical := armored.take_damage(DamageInfo.new(100.0, DamageInfo.Type.PHYSICAL))
	var magic := armored.take_damage(DamageInfo.new(10.0, DamageInfo.Type.MAGIC))
	_check(is_equal_approx(physical, 40.0), "giáp giảm sát thương vật lý (100 -> %.1f)" % physical)
	_check(is_equal_approx(magic, 10.0), "giáp không giảm sát thương phép (10 -> %.1f)" % magic)

	# Làm chậm: 40% trên địch thường, chỉ còn 20% trên Boss (kháng chậm 50%).
	var slow: StatusEffectData = load("res://resources/effects/slow.tres")
	armored.status_effects.apply(slow)
	_check(is_equal_approx(armored.status_effects.get_speed_multiplier(), 0.6), "làm chậm 40%")
	var boss := _spawn_test_enemy(path, waves.get_enemy_type(&"boss"))
	boss.status_effects.apply(slow)
	_check(is_equal_approx(boss.status_effects.get_speed_multiplier(), 0.8), "Boss kháng chậm 50%")

	# Thiêu đốt: sát thương chuẩn theo thời gian.
	var burn: StatusEffectData = load("res://resources/effects/burn.tres")
	var health_before := armored.health
	armored.status_effects.apply(burn)
	for i in 70: # ~1.2 giây
		await get_tree().process_frame
	_check(armored.health < health_before - 9.0, "thiêu đốt trừ máu theo thời gian (%.1f -> %.1f)" % [health_before, armored.health])
	armored.queue_free()
	boss.queue_free()
	await get_tree().process_frame

	# Boss chết thì sinh 8 Bầy chuột (spawn qua WaveManager để có signal thật).
	var enemies_before := get_tree().get_nodes_in_group(Enemy.GROUP).size()
	var real_boss: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"boss"), 1.0, 1.0, 400.0)
	real_boss.take_damage(DamageInfo.new(99999.0, DamageInfo.Type.TRUE))
	await get_tree().process_frame
	var swarm_count := get_tree().get_nodes_in_group(Enemy.GROUP).size() - enemies_before
	_check(swarm_count == 8, "Boss chết sinh ra 8 địch con (thực tế %d)" % swarm_count)

	await _free_main(main)


# --- Phần 1b: quản lý tháp (nâng cấp, bán, chọn) -------------------------------

func _test_tower_management() -> void:
	print("[1b] Quản lý tháp")
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var selection: SelectionManager = main.selection_manager
	var panel: TowerInfoPanel = main.tower_info_panel
	GameManager.add_gold(1000)

	# Xây + giá bán
	build.select_tower(build.available_towers[0]) if build.selected_tower_data != build.available_towers[0] else null
	var cell := Vector2i(4, 4)
	var tower := build.try_place_tower(cell)
	_check(tower != null and tower.get_level() == 1, "xây được tháp cấp 1")
	_check(tower.get_sell_value() == 35, "giá bán = 70%% giá xây (%d)" % tower.get_sell_value())

	# Click chuột vào tháp khi đang ở chế độ xây => chọn tháp, thoát chế độ xây.
	_click(GameConfig.cell_to_world(cell), MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	_check(selection.selected_tower == tower, "click vào tháp thì chọn tháp")
	_check(not build.is_building(), "chọn tháp thì thoát chế độ xây")
	_check(panel.visible, "bảng thông tin hiện khi chọn tháp")
	_check(tower.show_range, "tháp đang chọn hiện tầm bắn")

	# Phím U: nâng cấp; phím T: đổi mục tiêu.
	var gold_before := GameManager.gold
	_press_key(KEY_U)
	await get_tree().process_frame
	_check(tower.get_level() == 2 and GameManager.gold == gold_before - 60, "phím U nâng cấp lên cấp 2, trừ 60 vàng")
	_check(tower.data.damage > 18.0, "cấp 2 mạnh hơn cấp 1")
	_press_key(KEY_T)
	_check(tower.target_mode == Tower.TargetMode.LAST, "phím T đổi cách chọn mục tiêu")
	build.upgrade_tower(tower)
	_check(tower.get_level() == 3 and not tower.can_upgrade(), "nâng tối đa cấp 3")
	_check(not build.upgrade_tower(tower), "không nâng quá cấp tối đa")
	_check(tower.get_sell_value() == int((50 + 60 + 100) * 0.7), "giá bán tính cả tiền nâng cấp (%d)" % tower.get_sell_value())

	# Bán: hoàn tiền, giải phóng ô, tự bỏ chọn.
	gold_before = GameManager.gold
	var refund := build.sell_tower(tower)
	await get_tree().process_frame
	_check(GameManager.gold == gold_before + refund and refund == 147, "bán tháp hoàn 147 vàng")
	_check(build.get_tower_at(cell) == null, "bán xong ô trống lại")
	_check(not selection.has_selection() and not panel.visible, "bán xong thì bỏ chọn, ẩn bảng")
	build.select_tower(build.available_towers[1])
	_check(build.try_place_tower(cell) != null, "xây lại được ở ô vừa bán")

	# Chuột phải: bỏ chọn.
	build.cancel_build()
	selection.select(build.get_tower_at(cell))
	_click(Vector2(640, 400), MOUSE_BUTTON_RIGHT)
	await get_tree().process_frame
	_check(not selection.has_selection(), "chuột phải bỏ chọn tháp")

	# Tooltip nút xây có mô tả + chỉ số.
	var tooltip := TowerStats.tooltip(build.available_towers[2])
	_check(tooltip.contains("Làm chậm") and tooltip.contains("Tầm bắn"), "tooltip có hiệu ứng và chỉ số")
	await _free_main(main)


# --- Phần 1c: nhịp trận (tốc độ, tạm dừng, xem trước, gọi sớm, hiệu ứng) -------

func _test_match_flow() -> void:
	print("[1c] Nhịp trận")
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var waves: WaveManager = main.wave_manager
	var fx: FxManager = main.fx_manager
	build.cancel_build()

	# Tốc độ game: x1 -> x2 -> x3 -> x1.
	GameManager.cycle_game_speed()
	_check(is_equal_approx(Engine.time_scale, 2.0) and main.hud.speed_button.text.begins_with("x2"), "phím tốc độ chuyển sang x2")
	GameManager.cycle_game_speed()
	GameManager.cycle_game_speed()
	_check(is_equal_approx(Engine.time_scale, 1.0), "tốc độ quay vòng về x1")

	# Tạm dừng: Esc (khi không xây / không chọn) mở menu, P đóng menu.
	_press_key(KEY_ESCAPE)
	await get_tree().process_frame
	_check(get_tree().paused and main.pause_menu.visible, "Esc mở menu tạm dừng")
	_press_key(KEY_P)
	await get_tree().process_frame
	_check(not get_tree().paused and not main.pause_menu.visible, "P đóng menu tạm dừng")

	# Xem trước wave.
	var preview := waves.get_wave_composition(2)
	_check(preview.size() == 2 and preview[0].count == 10 and preview[1].data.id == &"fast", "xem trước wave 2: 10 Lính thường + 5 Trinh sát")
	_check(main.hud.next_wave_label.text.contains("Lính thường"), "HUD hiện wave sắp tới")

	# Gọi sớm: dựng vài tháp mạnh để không thua, chạy wave 1 tới khi spawn xong.
	GameManager.add_gold(2000)
	for order in [[3, Vector2i(4, 7)], [3, Vector2i(8, 7)], [1, Vector2i(4, 4)], [3, Vector2i(10, 4)], [1, Vector2i(2, 3)]]:
		build.select_tower(build.available_towers[order[0]]) if build.selected_tower_data != build.available_towers[order[0]] else null
		build.try_place_tower(order[1])
	build.cancel_build()
	var completed: Array[int] = []
	waves.wave_completed.connect(func(number: int, _bonus: int) -> void: completed.append(number))
	_check(waves.start_next_wave(), "bắt đầu wave 1")
	_check(not waves.can_start_next_wave(), "không gọi được wave mới khi đang spawn")
	var max_effects := 0
	while waves.is_spawning():
		max_effects = maxi(max_effects, fx.get_active_effect_count())
		await get_tree().process_frame
	_check(waves.is_wave_in_progress() and waves.can_start_next_wave(), "spawn xong mà địch còn => được gọi sớm")
	var gold_before := GameManager.gold
	var bonus := waves.get_early_call_bonus()
	waves.start_next_wave()
	_check(GameManager.gold == gold_before + bonus and bonus == 14, "gọi sớm wave 2 được thưởng %d vàng" % bonus)
	var frames := 0
	while waves.is_wave_in_progress() and frames < MAX_FRAMES_PER_RUN:
		max_effects = maxi(max_effects, fx.get_active_effect_count())
		await get_tree().process_frame
		frames += 1
	_check(completed == [1, 2], "2 wave chồng nhau đều báo hoàn thành đúng thứ tự (%s)" % [completed])
	_check(GameManager.is_playing(), "vẫn đang chơi sau 2 wave")
	_check(max_effects > 0, "có hiệu ứng số sát thương / vụ nổ (%d)" % max_effects)

	# Âm thanh: chưa có file thì im lặng, không lỗi.
	_check(not AudioManager.play(&"enemy_death"), "thiếu file âm thanh thì bỏ qua")
	await _free_main(main)


# --- Phần 1d: luồng màn (menu, chọn màn, khoá / mở, sao) ----------------------

func _test_level_flow() -> void:
	print("[1d] Luồng màn")
	var catalog := GameManager.LEVEL_CATALOG
	_check(catalog.levels.size() == 3, "có 3 màn chơi")

	var select := LEVEL_SELECT_SCENE.instantiate()
	add_child(select)
	await get_tree().process_frame
	_check(select.play_buttons.size() == 3, "màn chọn màn có 3 thẻ")
	_check(not select.play_buttons[0].disabled and select.play_buttons[1].disabled and select.play_buttons[2].disabled,
			"lúc đầu chỉ mở màn 1")
	select.play_buttons[0].pressed.emit()
	_check(GameManager.current_level == catalog.levels[0] and GameManager.last_requested_scene == GameManager.GAME_SCENE,
			"bấm Chơi màn 1 => vào trận màn 1")
	select.queue_free()

	# Qua màn 1 với 2 sao => mở màn 2, sao chỉ tăng không giảm.
	SaveManager.record_result(catalog.levels[0].id, 2)
	SaveManager.record_result(catalog.levels[0].id, 1)
	_check(SaveManager.get_stars(catalog.levels[0].id) == 2, "giữ số sao cao nhất")
	select = LEVEL_SELECT_SCENE.instantiate()
	add_child(select)
	await get_tree().process_frame
	_check(not select.play_buttons[1].disabled and select.play_buttons[2].disabled, "qua màn 1 thì mở màn 2")
	select.queue_free()

	var menu := MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame
	_check(menu.stars_label.text.contains("2 / 9"), "menu chính hiện tổng sao (%s)" % menu.stars_label.text)
	menu.play_button.pressed.emit()
	_check(GameManager.last_requested_scene == GameManager.LEVEL_SELECT_SCENE, "nút Chơi ở menu => màn chọn màn")
	menu.queue_free()

	# Sao theo máu còn lại.
	GameManager.reset(10, 200, 20)
	GameManager.lives = 17
	GameManager.win()
	_check(GameManager.calculate_stars() == 3, "còn 17/20 máu = 3 sao")
	GameManager.reset(10, 200, 20)
	GameManager.lives = 9
	GameManager.win()
	_check(GameManager.calculate_stars() == 2, "còn 9/20 máu = 2 sao")

	SaveManager.reset_progress()
	GameManager.current_level = null
	await get_tree().process_frame


# --- Phần 2: bot chơi hết từng màn ----------------------------------------------

func _test_bot_playthrough(level: LevelData) -> void:
	print("[2] Bot chơi màn \"%s\"" % level.display_name)
	GameManager.current_level = level
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var waves: WaveManager = main.wave_manager
	_check(waves.validate_waves().is_empty(), "%s: file wave hợp lệ %s" % [level.display_name, waves.validate_waves()])
	_check(GameManager.gold == level.starting_gold, "%s: vàng ban đầu = %d" % [level.display_name, level.starting_gold])

	# Đếm địch trên từng làn để chắc bản đồ nhiều làn được dùng đủ.
	var spawns_per_lane: Dictionary = {}
	waves.enemy_spawned.connect(func(enemy: Enemy) -> void:
		spawns_per_lane[enemy.get_parent()] = spawns_per_lane.get(enemy.get_parent(), 0) + 1)

	var samples := _path_samples(main.map.get_paths())
	var towers_built := 0
	var upgrades := 0
	var frames := 0
	while GameManager.is_playing() and frames < MAX_FRAMES_PER_RUN:
		if towers_built < BOT_MAX_TOWERS:
			var tower_data: TowerData = build.available_towers[BOT_TOWER_ROTATION[towers_built % BOT_TOWER_ROTATION.size()]]
			if GameManager.can_afford(tower_data.cost):
				var cell := _bot_best_cell(build, tower_data, samples)
				if cell.x >= 0:
					build.select_tower(tower_data) if build.selected_tower_data != tower_data else null
					build.try_place_tower(cell)
					towers_built += 1
		else:
			var cheapest: Tower = null
			for tower in build.get_towers():
				if tower.can_upgrade() and (cheapest == null or tower.get_upgrade_cost() < cheapest.get_upgrade_cost()):
					cheapest = tower
			if cheapest and GameManager.can_afford(cheapest.get_upgrade_cost()):
				build.upgrade_tower(cheapest)
				upgrades += 1

		# Bot chơi "bình thường": chỉ gọi wave mới khi wave trước đã xong hẳn.
		if waves.can_start_next_wave() and not waves.is_wave_in_progress():
			waves.start_next_wave()
		await get_tree().process_frame
		frames += 1

	var won := GameManager.state == GameManager.GameState.VICTORY
	print("    %s ở wave %d/%d, máu %d/%d, %d tháp, %d nâng cấp, %d sao" % ["THẮNG" if won else "THUA",
			waves.get_current_wave_number(), waves.get_total_waves(), GameManager.lives, level.starting_lives,
			towers_built, upgrades, GameManager.calculate_stars()])
	_check(won, "%s: bot thắng cả %d wave" % [level.display_name, waves.get_total_waves()])
	_check(spawns_per_lane.size() == main.map.get_paths().size(), "%s: địch đi đủ %d làn" % [level.display_name, main.map.get_paths().size()])
	if won:
		var has_next := GameManager.LEVEL_CATALOG.get_next_level(level) != null
		_check(main.hud.game_over_panel.visible and main.hud.result_stars.visible, "%s: bảng thắng có sao" % level.display_name)
		_check(main.hud.next_level_button.visible == has_next, "%s: nút Màn tiếp theo đúng" % level.display_name)
		_check(SaveManager.get_stars(level.id) == GameManager.calculate_stars(), "%s: đã lưu số sao" % level.display_name)
	if level == GameManager.LEVEL_CATALOG.levels[0]:
		var total_kills := 0
		for tower in build.get_towers():
			total_kills += tower.kills
		_check(total_kills > 100, "tháp ghi nhận số địch hạ (%d)" % total_kills)
	await _free_main(main)


## Các điểm mẫu dọc mọi làn (chỉ phần nằm trong màn hình), dùng để chấm điểm ô xây.
func _path_samples(paths: Array[Path2D]) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for path in paths:
		var baked := path.curve.get_baked_points()
		for i in range(0, baked.size(), 3):
			var point := path.to_global(baked[i])
			if point.x >= 0.0:
				samples.append(point)
	return samples


## Ô hợp lệ phủ được nhiều đoạn đường nhất trong tầm bắn của loại tháp này.
func _bot_best_cell(build: BuildManager, tower_data: TowerData, samples: PackedVector2Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := 0
	var range_squared := tower_data.attack_range * tower_data.attack_range
	var area := GameConfig.BUILD_AREA
	for y in range(int(area.position.y) / GameConfig.CELL_SIZE, int(area.end.y) / GameConfig.CELL_SIZE):
		for x in range(int(area.position.x) / GameConfig.CELL_SIZE, int(area.end.x) / GameConfig.CELL_SIZE):
			var cell := Vector2i(x, y)
			if build.get_placement_error(cell, tower_data) != "":
				continue
			var center := GameConfig.cell_to_world(cell)
			var score := 0
			for point in samples:
				if center.distance_squared_to(point) <= range_squared:
					score += 1
			if score > best_score:
				best_score = score
				best = cell
	return best


# --- Phần 3: không xây gì thì phải thua -----------------------------------------

func _test_defeat_without_towers(level: LevelData) -> void:
	print("[3] Không đặt tháp ở màn \"%s\"" % level.display_name)
	GameManager.current_level = level
	var main := await _new_main()
	var waves: WaveManager = main.wave_manager
	var frames := 0
	while GameManager.is_playing() and frames < MAX_FRAMES_PER_RUN:
		if waves.can_start_next_wave():
			waves.start_next_wave()
		await get_tree().process_frame
		frames += 1
	print("    thua ở wave %d" % waves.get_current_wave_number())
	_check(GameManager.state == GameManager.GameState.DEFEAT, "%s: không xây tháp thì thua" % level.display_name)
	_check(main.hud.game_over_panel.visible and not main.hud.next_level_button.visible, "%s: bảng thua không có nút màn sau" % level.display_name)
	await _free_main(main)


# --- Tiện ích -------------------------------------------------------------------

func _new_main() -> Node:
	get_tree().paused = false
	Engine.time_scale = 1.0
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	return main


func _free_main(main: Node) -> void:
	get_tree().paused = false
	main.queue_free()
	await get_tree().process_frame


## Giả lập click chuột tại một vị trí trong thế giới (toạ độ viewport).
func _click(position: Vector2, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = position
	event.global_position = position
	get_viewport().push_input(event, true)


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	get_viewport().push_input(event, true)


## Tạo địch trực tiếp (không qua WaveManager) để kiểm tra chỉ số.
func _spawn_test_enemy(path: Path2D, enemy_data: EnemyData) -> Enemy:
	var enemy := enemy_data.scene.instantiate() as Enemy
	enemy.setup(enemy_data)
	path.add_child(enemy)
	enemy.progress = 300.0
	enemy.base_speed = 0.0 # Đứng yên để không chạy tới nhà chính trong lúc test.
	return enemy


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  OK   ", description)
	else:
		print("  FAIL ", description)
		_failures.append(description)
