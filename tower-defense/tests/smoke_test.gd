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
##      Kỹ năng chủ động, địch bay, chế độ vô tận. Cài đặt, hướng dẫn chơi lần đầu.
##      Hiển thị tầm bắn + ghost tháp (trạng thái, bán kính, phản hồi đặt đúng / sai).
##      Thanh máu địch (ẩn / hiện, màu theo ngưỡng, vệt sát thương) + nháy trắng khi trúng đòn.
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
	await _test_abilities_and_flying()
	await _test_endless()
	await _test_settings_and_tutorial()
	await _test_range_display()
	await _test_enemy_feedback()
	await _test_meta_foundation()
	await _test_achievements()
	for level in GameManager.LEVEL_CATALOG.levels:
		await _test_bot_playthrough(level)
	for level in GameManager.LEVEL_CATALOG.levels:
		await _test_defeat_without_towers(level)

	for path in [TEST_SAVE_PATH, SaveManager.profile_path, SaveManager.profile_path + ".bak",
			SaveManager.profile_path + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if _failures.is_empty():
		print("=== SMOKE TEST PASSED ===")
		AudioManager.quit_game(0)
	else:
		print("=== SMOKE TEST FAILED (%d) ===" % _failures.size())
		for failure in _failures:
			print("  - ", failure)
		AudioManager.quit_game(1)


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
	for id in [&"basic", &"fast", &"armored", &"swarm", &"boss", &"healer"]:
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

	# Âm thanh: đủ file cho mọi tên game gọi; phát dày thì bị chặn; thiếu file thì im lặng, không lỗi.
	var missing := AudioManager.SOUND_NAMES.filter(func(sound: String) -> bool: return not AudioManager.has_sound(StringName(sound)))
	_check(missing.is_empty(), "có file cho mọi âm thanh (thiếu: %s)" % [missing])
	_check(AudioManager.play(&"sell") and not AudioManager.play(&"sell"), "cùng một âm phát liên tục bị chặn")
	_check(not AudioManager.play(&"khong_co_file_nay"), "thiếu file âm thanh thì bỏ qua")
	AudioManager.enabled = false # Phần còn lại chạy siêu tốc, không cần tiếng.
	await _free_main(main)


# --- Phần 1d: luồng màn (menu, chọn màn, khoá / mở, sao) ----------------------

func _test_level_flow() -> void:
	print("[1d] Luồng màn")
	var catalog := GameManager.LEVEL_CATALOG
	_check(catalog.levels.size() == 4, "có 4 màn chơi")

	var select := LEVEL_SELECT_SCENE.instantiate()
	add_child(select)
	await get_tree().process_frame
	_check(select.play_buttons.size() == 4, "màn chọn màn có 4 thẻ")
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
	_check(not select.endless_buttons[0].disabled and select.endless_buttons[1].disabled, "qua màn 1 thì mở vô tận màn 1")
	select.endless_buttons[0].pressed.emit()
	_check(GameManager.endless_mode and GameManager.current_level == catalog.levels[0], "bấm Vô tận => vào chế độ vô tận")
	GameManager.endless_mode = false
	select.queue_free()

	var menu := MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame
	_check(menu.stars_label.text.contains("2 / 12"), "menu chính hiện tổng sao (%s)" % menu.stars_label.text)
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


# --- Phần 1e: kỹ năng chủ động + địch bay --------------------------------------

func _test_abilities_and_flying() -> void:
	print("[1e] Kỹ năng + địch bay")
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var waves: WaveManager = main.wave_manager
	var abilities: AbilityManager = main.ability_manager
	var path: Path2D = main.map.get_paths()[0]
	build.cancel_build()
	var meteor: AbilityData = abilities.abilities[0]
	var freeze: AbilityData = abilities.abilities[1]

	# Thiên thạch: phím Q để ngắm, click chuột để thả. 120 sát thương chuẩn (bỏ qua giáp).
	var armored := _spawn_test_enemy(path, waves.get_enemy_type(&"armored"))
	_press_key(KEY_Q)
	_check(abilities.targeting == meteor, "phím Q vào chế độ ngắm Thiên thạch")
	_click(armored.global_position, MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	_check(is_equal_approx(armored.health, 30.0) or armored.health < 30.0, "Thiên thạch gây 120 sát thương chuẩn lên Bọc thép (còn %.0f)" % armored.health)
	_check(armored.status_effects.has_effect(&"burn"), "Thiên thạch gây thiêu đốt")
	_check(abilities.targeting == null and not abilities.is_ready(meteor), "dùng xong thì hồi chiêu")
	var failures := []
	abilities.ability_failed.connect(func(reason: String) -> void: failures.append(reason))
	abilities.request(meteor)
	_check(failures.size() == 1 and abilities.targeting == null, "không dùng được khi đang hồi chiêu")

	# Băng giá: dùng ngay, làm chậm toàn bộ địch.
	var basic := _spawn_test_enemy(path, waves.get_enemy_type(&"basic"))
	abilities.request(freeze)
	_check(is_equal_approx(basic.status_effects.get_speed_multiplier(), 0.1), "Băng giá làm chậm 90% mọi địch")

	# Địch bay: đi làn trên không, Pháo không bắn được, Cung thủ bắn được.
	var bat: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"bat"), 1.0, 1.0, 500.0)
	bat.base_speed = 0.0
	_check(bat.get_parent() == main.map.get_air_paths()[0], "địch bay đi làn trên không")
	_check(not main.map.get_paths().has(bat.get_parent()), "làn trên không không phải làn mặt đất")
	armored.queue_free()
	basic.queue_free()
	await get_tree().process_frame
	GameManager.add_gold(500)
	var near := GameConfig.world_to_cell(bat.global_position) + Vector2i(0, 1)
	build.select_tower(build.available_towers[1])
	var cannon := build.try_place_tower(near)
	build.select_tower(build.available_towers[0])
	var archer := build.try_place_tower(near + Vector2i(1, 0))
	_check(cannon != null and cannon._find_target() == null, "Pháo không nhắm địch bay")
	_check(archer != null and archer._find_target() == bat, "Cung thủ nhắm được địch bay")
	var ground_splash := DamageInfo.new(50.0, DamageInfo.Type.TRUE)
	ground_splash.hits_air = false
	Combat.apply_hit(null, bat.global_position, ground_splash, 80.0, get_tree())
	_check(is_equal_approx(bat.health, bat.max_health), "nổ lan mặt đất không trúng địch bay")
	_check(TowerStats.describe(build.available_towers[1]).contains("Chỉ mặt đất"), "bảng chỉ số ghi rõ Pháo chỉ bắn mặt đất")
	await _free_main(main)


# --- Phần 1f: chế độ vô tận ---------------------------------------------------

func _test_endless() -> void:
	print("[1f] Chế độ vô tận")
	var level: LevelData = GameManager.LEVEL_CATALOG.levels[0]
	var ids := [&"basic", &"fast", &"swarm", &"armored", &"bat", &"boss"]
	_check(WaveGenerator.generate(7, "x", ids) == WaveGenerator.generate(7, "x", ids), "sinh wave lặp lại được (cùng seed)")
	var boss_waves := 0
	for n in range(1, 31):
		var wave := WaveGenerator.generate(n, String(level.id), ids)
		for group: Dictionary in wave.groups:
			if group.enemy == "boss":
				boss_waves += 1
	_check(boss_waves == 3, "Boss xuất hiện ở wave 10, 20, 30 (%d wave có Boss)" % boss_waves)

	GameManager.current_level = level
	GameManager.endless_mode = true
	var main := await _new_main()
	var waves: WaveManager = main.wave_manager
	_check(waves.endless and waves.get_total_waves() == 0 and waves.has_more_waves(), "WaveManager ở chế độ vô tận")
	_check(main.hud.wave_label.text.contains("vô tận"), "HUD ghi chế độ vô tận")
	_check(waves.validate_waves().is_empty(), "wave sinh ra hợp lệ")
	var frames := 0
	while GameManager.is_playing() and frames < MAX_FRAMES_PER_RUN:
		if waves.can_start_next_wave() and not waves.is_wave_in_progress():
			waves.start_next_wave()
		await get_tree().process_frame
		frames += 1
	print("    không xây tháp: trụ tới wave %d" % waves.get_current_wave_number())
	_check(GameManager.state == GameManager.GameState.DEFEAT, "vô tận không xây tháp thì thua")
	_check(SaveManager.get_endless_best(level.id) == waves.get_current_wave_number(), "lưu kỷ lục vô tận")
	_check(main.hud.game_over_panel.visible and main.hud.result_detail.text.contains("Kỷ lục"), "bảng kết thúc vô tận hiện kỷ lục")
	await _free_main(main)
	GameManager.endless_mode = false
	SaveManager.reset_progress()


# --- Phần 1g: cài đặt + hướng dẫn --------------------------------------------

func _test_settings_and_tutorial() -> void:
	print("[1g] Cài đặt + hướng dẫn")
	# Cài đặt áp dụng ngay, được lưu, và không bị "Xoá tiến độ" xoá mất.
	SaveManager.set_setting("master_volume", 0.5)
	_check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.5)), "âm lượng áp dụng vào Audio bus")
	SaveManager.set_setting("damage_numbers", false)
	SaveManager.reset_progress()
	SaveManager.save_path = TEST_SAVE_PATH # Đọc lại từ file.
	_check(is_equal_approx(float(SaveManager.get_setting("master_volume")), 0.5), "cài đặt được lưu và giữ sau Xoá tiến độ")

	var menu := MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame
	menu.settings_button.pressed.emit()
	_check(menu.settings_menu.visible and is_equal_approx(menu.settings_menu.volume_slider.value, 50.0), "menu chính mở bảng cài đặt với giá trị đã lưu")
	_press_key(KEY_ESCAPE)
	_check(not menu.settings_menu.visible, "Esc đóng bảng cài đặt")
	menu.queue_free()

	# Hướng dẫn: màn 1, chưa xem lần nào.
	GameManager.current_level = GameManager.LEVEL_CATALOG.levels[0]
	var main := await _new_main()
	var tutorial: TutorialManager = main.tutorial
	var build: BuildManager = main.build_manager
	_check(not main.fx_manager.show_damage_numbers, "tắt số sát thương trong cài đặt thì FxManager tắt theo")
	_check(tutorial.current_step == 0 and main.hud.tutorial_panel.visible, "hướng dẫn bắt đầu ở bước 1")
	GameManager.add_gold(1000)
	var tower := build.try_place_tower(Vector2i(4, 7))
	_check(tutorial.current_step == 1, "xây tháp => bước 2")
	main.wave_manager.start_next_wave()
	_check(tutorial.current_step == 2, "gọi wave => bước 3")
	main.selection_manager.select(tower)
	_check(tutorial.current_step == 3, "chọn tháp => bước 4")
	build.upgrade_tower(tower)
	_check(tutorial.current_step == 4, "nâng cấp => bước 5")
	main.ability_manager.request(main.ability_manager.abilities[1])
	_check(tutorial.current_step == 5, "dùng kỹ năng => bước cuối")
	for i in 60 * 7:
		await get_tree().process_frame
	_check(not tutorial.is_active() and not main.hud.tutorial_panel.visible, "bước cuối tự đóng sau vài giây")
	_check(SaveManager.get_flag(TutorialManager.DONE_FLAG), "đánh dấu đã xem hướng dẫn")
	await _free_main(main)
	main = await _new_main()
	_check(not main.tutorial.is_active(), "lần sau không hiện lại hướng dẫn")

	# Tạm dừng -> Cài đặt -> Esc quay lại menu tạm dừng -> P chơi tiếp.
	main.set_paused(true)
	main.pause_menu.settings_requested.emit()
	_check(main.hud.settings_menu.visible and not main.pause_menu.visible, "mở cài đặt từ menu tạm dừng")
	_press_key(KEY_ESCAPE)
	_check(not main.hud.settings_menu.visible and main.pause_menu.visible, "đóng cài đặt thì quay lại menu tạm dừng")
	_press_key(KEY_P)
	_check(not get_tree().paused, "P tiếp tục chơi")
	await _free_main(main)

	SaveManager.set_setting("damage_numbers", true)
	SaveManager.set_setting("master_volume", 0.8)
	SaveManager.reset_progress()
	GameManager.current_level = null


# --- Phần 1h: tầm bắn + ghost tháp -----------------------------------------------

func _test_range_display() -> void:
	print("[1h] Tầm bắn + ghost tháp")
	SaveManager.set_flag(TutorialManager.DONE_FLAG, true)
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var display: TowerRangeDisplay = main.range_display
	var State := RangeIndicator.State

	# Chế độ xây (Cung thủ chọn sẵn) + rê chuột vào ô trống => VALID, đúng bán kính.
	var free_cell := Vector2i(4, 4)
	_move_mouse(GameConfig.cell_to_world(free_cell))
	await get_tree().process_frame
	_check(display.is_ghost_visible() and display.get_placement_state() == State.VALID, "ô trống: ghost + vòng VALID")
	_check(is_equal_approx(display.get_placement_radius(), build.selected_tower_data.attack_range), "bán kính = tầm bắn Cung thủ")

	# Đổi loại tháp => bán kính đổi theo.
	for index in build.available_towers.size():
		var data: TowerData = build.available_towers[index]
		if build.selected_tower_data != data:
			build.select_tower(data)
		await get_tree().process_frame
		_check(is_equal_approx(display.get_placement_radius(), data.attack_range),
				"bán kính vòng đặt %s = %d" % [data.display_name, data.attack_range])
	build.select_tower(build.available_towers[0])

	# Trên đường đi => INVALID, và trùng khớp với hàm kiểm tra của lệnh đặt thật.
	var path_cell := Vector2i(3, 2)
	_move_mouse(GameConfig.cell_to_world(path_cell))
	await get_tree().process_frame
	_check(display.get_placement_state() == State.INVALID, "trên đường đi: vòng INVALID (đứt nét)")
	_check((display.get_placement_state() == State.VALID) == build.get_placement_error(path_cell, build.selected_tower_data).is_empty(),
			"ghost và lệnh đặt thật dùng chung một kết quả kiểm tra")

	# Click vào chỗ sai: không đặt, ghost rung + hiện lý do.
	var effects_before := display.get_effect_count()
	_click(GameConfig.cell_to_world(path_cell), MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	_check(build.get_tower_at(path_cell) == null and display.get_effect_count() > effects_before, "đặt sai: không xây, có lý do nổi lên")

	# Đặt thành công bằng chuột: hiệu ứng xuất hiện, ghost ẩn ở ô vừa đặt cho tới khi rời ô.
	_move_mouse(GameConfig.cell_to_world(free_cell))
	await get_tree().process_frame
	_click(GameConfig.cell_to_world(free_cell), MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	var tower := build.get_tower_at(free_cell)
	_check(tower != null and display.get_effect_count() > 0, "đặt đúng: có sóng vòng / bụi / -giá")
	_check(not display.is_ghost_visible(), "vừa đặt xong: ẩn ghost ở ô đó (không chớp đỏ)")
	_move_mouse(GameConfig.cell_to_world(free_cell + Vector2i(1, 0)))
	await get_tree().process_frame
	_check(display.is_ghost_visible(), "rời sang ô khác: ghost hiện lại")

	# Thiếu vàng => INVALID.
	var gold := GameManager.gold
	GameManager.spend_gold(gold)
	await get_tree().process_frame
	_check(display.get_placement_state() == State.INVALID, "thiếu vàng: vòng chuyển INVALID")
	GameManager.add_gold(1000)

	# Click vào tháp đã xây: vòng SELECTED đúng bán kính; xem trước nâng cấp; nâng cấp thì vòng nở ra.
	_click(GameConfig.cell_to_world(free_cell), MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	var ring := display.get_selection_ring()
	_check(ring.state == State.SELECTED and is_equal_approx(ring.radius, tower.data.attack_range), "chọn tháp: vòng SELECTED đúng tầm bắn")
	_check(display.get_placement_state() == State.HIDDEN, "chọn tháp thì ẩn ghost / vòng đặt")
	display.show_upgrade_preview(true)
	_check(display.get_upgrade_ring().state == State.UPGRADE_PREVIEW
			and is_equal_approx(display.get_upgrade_ring().radius, tower.data.next_level.attack_range), "xem trước tầm bắn sau nâng cấp")
	build.upgrade_tower(tower)
	for i in 20:
		await get_tree().process_frame
	_check(is_equal_approx(ring.radius, tower.data.attack_range), "nâng cấp: vòng SELECTED nở theo tầm mới")
	main.selection_manager.deselect()
	_check(not ring.is_shown() and not display.get_upgrade_ring().is_shown(), "bỏ chọn: ẩn vòng")
	await _free_main(main)
	SaveManager.reset_progress()


# --- Phần 1i: thanh máu địch + hiệu ứng trúng đòn -------------------------------

func _test_enemy_feedback() -> void:
	print("[1i] Thanh máu địch + hiệu ứng trúng đòn")
	var main := await _new_main()
	var waves: WaveManager = main.wave_manager
	var path: Path2D = main.map.get_paths()[0]
	var enemy := _spawn_test_enemy(path, waves.get_enemy_type(&"basic"))
	var bar := enemy.health_bar
	var hit := enemy.hit_feedback
	await get_tree().process_frame

	_check(not bar.visible and not bar.is_shown(), "đầy máu: ẩn thanh máu")
	_check(not hit.is_active() and hit.flash_amount == 0.0, "chưa trúng đòn: không nháy")
	_check(bar.z_index > 0 and bar.global_rotation == 0.0, "thanh máu nằm trên địch và không xoay")
	_check(bar.position.y < -enemy.data.radius, "thanh máu nằm trên đầu địch")

	# Trúng 30%: thanh hiện, xanh lá, có vệt trắng giữ ở mức cũ.
	enemy.take_damage(DamageInfo.new(enemy.max_health * 0.3, DamageInfo.Type.TRUE))
	_check(hit.flash_amount > 0.9 and hit.is_active(), "trúng đòn: nháy trắng ngay")
	_check(is_equal_approx(bar.ratio, 0.7) and is_equal_approx(bar.trail_ratio, 1.0), "máu tụt ngay, vệt giữ mức cũ")
	_check(HealthBar.color_for_ratio(bar.ratio) == HealthBar.COLOR_HIGH, "máu > 50%: xanh lá")
	for i in 9: # 0.15s: hết nháy (0.1s) nhưng vẫn trong khoảng chặn 0.33s
		await get_tree().process_frame
	_check(bar.visible and is_equal_approx(bar.modulate.a, 1.0), "thanh máu hiện sau cú trúng đầu tiên")
	_check(hit.flash_amount == 0.0 and hit.body_scale == Vector2.ONE, "nháy + giật kết thúc sau ~0.1s")

	# Đòn thứ hai trong khoảng chặn 0.33s: vẫn trừ máu nhưng không nháy lại.
	enemy.take_damage(DamageInfo.new(enemy.max_health * 0.3, DamageInfo.Type.TRUE))
	_check(is_equal_approx(bar.ratio, 0.4), "đòn liên tiếp vẫn trừ máu đúng")
	_check(hit.flash_amount == 0.0, "không nháy quá 3 lần / giây")
	_check(HealthBar.color_for_ratio(bar.ratio) == HealthBar.COLOR_MID, "máu 25-50%: vàng")
	_check(is_equal_approx(bar.trail_ratio, 1.0), "vệt giữ đỉnh của cả chuỗi đòn")
	for i in 60:
		await get_tree().process_frame
	_check(is_equal_approx(bar.trail_ratio, bar.ratio), "vệt sát thương rút về máu hiện tại")
	_check(not bar.is_processing() and not hit.is_active(), "hết hiệu ứng: tắt _process (không tốn hiệu năng)")

	# Sát thương theo thời gian không làm nháy.
	var tick := DamageInfo.new(1.0, DamageInfo.Type.TRUE)
	tick.is_periodic = true
	enemy.take_damage(tick)
	_check(hit.flash_amount == 0.0, "thiêu đốt không gây nháy")
	enemy.take_damage(DamageInfo.new(enemy.max_health * 0.2, DamageInfo.Type.TRUE))
	_check(HealthBar.color_for_ratio(bar.ratio) == HealthBar.COLOR_LOW, "máu <= 25%: đỏ")
	_check(hit.flash_amount > 0.9, "hết khoảng chặn: nháy lại bình thường")

	# Boss (tinh nhuệ): luôn hiện, thanh to hơn, có vạch chia.
	var boss := _spawn_test_enemy(path, waves.get_enemy_type(&"boss"))
	await get_tree().process_frame
	_check(boss.health_bar.visible and boss.health_bar.show_ticks, "Boss: thanh máu luôn hiện, có vạch chia")
	_check(boss.health_bar.bar_size.x > bar.bar_size.x, "Boss: thanh máu rộng hơn địch thường")
	var swarm := _spawn_test_enemy(path, waves.get_enemy_type(&"swarm"))
	_check(swarm.health_bar.bar_size.x < bar.bar_size.x, "địch nhỏ: thanh máu ngắn hơn")
	var bat := _spawn_test_enemy(path, waves.get_enemy_type(&"bat"))
	_check(bat.health_bar.position.y < -bat.data.radius - HealthBar.FLYING_LIFT, "địch bay: thanh máu trên thân đang bay")

	# Chết vẫn phát died đúng như cũ.
	var died := [false]
	enemy.died.connect(func(_e: Enemy, _r: int) -> void: died[0] = true)
	enemy.take_damage(DamageInfo.new(99999.0, DamageInfo.Type.TRUE))
	_check(died[0] and not enemy.is_alive(), "hết máu: vẫn phát died")

	# Thanh máu Boss trên HUD: hiện khi Boss xuất hiện, theo máu, ẩn khi Boss chết.
	var boss_bar: BossBar = main.hud.boss_bar
	_check(not boss_bar.visible, "chưa có Boss: ẩn thanh Boss")
	var real_boss: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"boss"), 1.0, 0.0, 300.0)
	await get_tree().process_frame
	_check(boss_bar.visible and boss_bar.get_current_boss() == real_boss, "Boss xuất hiện: hiện thanh Boss trên HUD")
	real_boss.take_damage(DamageInfo.new(real_boss.max_health * 0.6, DamageInfo.Type.TRUE))
	_check(is_equal_approx(boss_bar.get_health_bar().ratio, 0.4), "thanh Boss theo máu Boss")
	real_boss.take_damage(DamageInfo.new(99999.0, DamageInfo.Type.TRUE))
	for i in 20:
		await get_tree().process_frame
	_check(not boss_bar.visible and boss_bar.get_current_boss() == null, "Boss chết: ẩn thanh Boss")

	# Tia lửa: có khi trúng đòn, nhưng có trần dù trúng dồn dập.
	var fx: FxManager = main.fx_manager
	var punching_bag := _spawn_test_enemy(path, waves.get_enemy_type(&"armored"))
	punching_bag.max_health = 1e9
	punching_bag.health = 1e9
	fx.track_enemy(punching_bag)
	var effects_before := fx.get_active_effect_count()
	punching_bag.take_damage(DamageInfo.new(5.0, DamageInfo.Type.MAGIC))
	_check(fx.get_active_effect_count() > effects_before, "trúng đòn: có tia lửa")
	for i in 200:
		punching_bag.take_damage(DamageInfo.new(5.0, DamageInfo.Type.MAGIC))
	_check(fx._spark_count <= FxManager.MAX_SPARKS, "tia lửa có trần (%d <= %d)" % [fx._spark_count, FxManager.MAX_SPARKS])
	punching_bag.queue_free()

	# Gặp loại địch mới lần đầu: hiện mẹo một lần duy nhất.
	SaveManager.set_flag("seen_enemy_fast", false)
	main.hud.message_label.text = ""
	var scout: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"fast"), 1.0, 0.0, 200.0)
	_check(main.hud.message_label.text.contains("Trinh sát") and SaveManager.get_flag("seen_enemy_fast"), "địch mới lần đầu: hiện mẹo (%s)" % main.hud.message_label.text)
	main.hud.message_label.text = ""
	var scout2: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"fast"), 1.0, 0.0, 220.0)
	_check(main.hud.message_label.text.is_empty(), "lần sau không hiện lại mẹo")
	scout.queue_free()
	scout2.queue_free()

	# Thầy lang: hồi máu cho địch khác trong bán kính, không tự hồi, không vượt máu tối đa.
	var healer := _spawn_test_enemy(path, waves.get_enemy_type(&"healer"))
	var patient := _spawn_test_enemy(path, waves.get_enemy_type(&"armored"))
	var far_away := _spawn_test_enemy(path, waves.get_enemy_type(&"armored"))
	patient.progress = healer.progress + 30.0
	far_away.progress = healer.progress + 400.0
	await get_tree().process_frame
	var aura: HealerAura = healer.get_node("HealerAura")
	var heals := [0.0]
	patient.healed.connect(func(_e: Enemy, amount: float) -> void: heals[0] += amount)
	for e in [healer, patient, far_away]:
		e.take_damage(DamageInfo.new(50.0, DamageInfo.Type.TRUE))
	var healer_hp := healer.health
	var patient_hp := patient.health
	aura.heal_nearby()
	_check(patient.health > patient_hp and is_equal_approx(heals[0], patient.health - patient_hp), "Thầy lang hồi máu địch ở gần (+%d)" % roundi(patient.health - patient_hp))
	_check(far_away.health < far_away.max_health and healer.health == healer_hp, "không hồi địch ở xa, không tự hồi")
	_check(is_equal_approx(patient.health_bar.ratio, patient.health / patient.max_health), "thanh máu tăng theo khi được hồi")
	for i in 20:
		aura.heal_nearby()
	_check(patient.health == patient.max_health, "hồi không vượt quá máu tối đa")
	_check(patient.heal(10.0) == 0.0, "đầy máu thì heal() trả về 0")
	for e in [healer, patient, far_away]:
		e.queue_free()

	# Cài đặt hiển thị / hỗ trợ (đổi qua chính menu Cài đặt như người chơi).
	var settings: SettingsMenu = main.hud.settings_menu
	settings.open()
	settings.hit_flash_option.item_selected.emit(VisualSettings.HitFlash.OFF)
	_check(int(SaveManager.get_setting("hit_flash")) == VisualSettings.HitFlash.OFF, "menu Cài đặt lưu tuỳ chọn nháy")
	var target := _spawn_test_enemy(path, waves.get_enemy_type(&"armored"))
	await get_tree().process_frame
	target.take_damage(DamageInfo.new(10.0, DamageInfo.Type.TRUE))
	_check(target.hit_feedback.flash_amount == 0.0, "tắt nháy: trúng đòn không nháy")
	settings.hit_flash_option.item_selected.emit(VisualSettings.HitFlash.REDUCED)
	for i in 30:
		await get_tree().process_frame
	target.take_damage(DamageInfo.new(10.0, DamageInfo.Type.TRUE))
	_check(target.hit_feedback.flash_amount > 0.0 and target.hit_feedback.flash_amount <= 0.35, "nháy nhẹ: tối đa 35%")

	settings.reduced_motion_check.toggled.emit(true)
	for i in 30:
		await get_tree().process_frame
	target.take_damage(DamageInfo.new(10.0, DamageInfo.Type.TRUE))
	await get_tree().process_frame
	await get_tree().process_frame
	_check(target.hit_feedback.body_scale == Vector2.ONE, "giảm chuyển động: không giật")
	_check(is_equal_approx(target.health_bar.trail_ratio, target.health_bar.ratio), "giảm chuyển động: không có vệt rút dần")

	settings.health_bar_option.item_selected.emit(VisualSettings.HealthBarMode.ALWAYS)
	var fresh := _spawn_test_enemy(path, waves.get_enemy_type(&"basic"))
	for i in 6:
		await get_tree().process_frame
	_check(fresh.health_bar.visible, "thanh máu 'Luôn hiện': hiện cả khi đầy máu")
	settings.health_bar_option.item_selected.emit(VisualSettings.HealthBarMode.OFF)
	for i in 12:
		await get_tree().process_frame
	_check(not target.health_bar.visible and boss.health_bar.visible, "thanh máu 'Tắt': ẩn (trừ Boss)")

	settings.colorblind_check.toggled.emit(true)
	_check(HealthBar.color_for_ratio(0.9) == HealthBar.COLOR_HIGH_COLORBLIND \
			and HealthBar.color_for_ratio(0.1) == HealthBar.COLOR_LOW_COLORBLIND, "bảng màu mù màu: xanh dương / cam")
	settings.close()
	for key in ["hit_flash", "health_bar_mode", "reduced_motion", "colorblind"]:
		SaveManager.set_setting(key, SaveManager.DEFAULT_SETTINGS[key])
	_check(not VisualSettings.reduced_motion and VisualSettings.hit_flash == VisualSettings.HitFlash.ON, "trả cài đặt về mặc định")
	await _free_main(main)


# --- Phần 1j: nền móng meta (save JSON, ví tiền, thưởng cuối ván, cấp) --------------

func _test_meta_foundation() -> void:
	print("[1j] Nền móng meta")
	SaveManager.reset_progress()

	# Ví tiền: mọi thay đổi có lý do; không tiêu quá số đang có.
	EconomyManager.add(EconomyManager.COINS, 120, "test")
	_check(EconomyManager.get_amount(EconomyManager.COINS) == 120, "cộng xu")
	_check(not EconomyManager.spend(EconomyManager.COINS, 500, "test") and EconomyManager.get_amount(EconomyManager.COINS) == 120, "không đủ xu thì không trừ")
	_check(EconomyManager.spend(EconomyManager.COINS, 20, "test") and EconomyManager.get_amount(EconomyManager.COINS) == 100, "trừ xu")
	_check(EconomyManager.get_log().back().reason == "test", "giao dịch được ghi lý do")

	# Lưu rồi đọc lại: số nguyên giữ nguyên kiểu (JSON trả float).
	StatsManager.increment(StatsManager.ENEMIES_KILLED, 7)
	SaveManager.record_result(&"level_01", 2)
	SaveManager.flush()
	SaveManager.save_path = TEST_SAVE_PATH # Đọc lại từ đĩa.
	_check(EconomyManager.get_amount(EconomyManager.COINS) == 100 and typeof(EconomyManager.get_amount(EconomyManager.COINS)) == TYPE_INT, "đọc lại: xu là số nguyên")
	_check(StatsManager.get_stat(StatsManager.ENEMIES_KILLED) == 7 and SaveManager.get_stars(&"level_01") == 2, "đọc lại: thống kê + sao giữ nguyên")

	# File chính hỏng -> khôi phục từ bản dự phòng (.bak = lần lưu trước đó).
	EconomyManager.add(EconomyManager.COINS, 1, "test")
	SaveManager.flush()
	var broken := FileAccess.open(SaveManager.profile_path, FileAccess.WRITE)
	broken.store_string("{ hỏng")
	broken.close()
	SaveManager.save_path = TEST_SAVE_PATH
	_check(EconomyManager.get_amount(EconomyManager.COINS) == 100, "save hỏng: khôi phục từ bản dự phòng")
	_check(SaveManager._read_json(SaveManager.profile_path) != null and SaveManager._read_json(SaveManager.profile_path + ".bak") != null,
			"sau khi khôi phục: file chính được ghi lại, bản dự phòng còn nguyên")

	# Save kiểu cũ (tiến độ nằm trong .cfg) được chuyển sang hồ sơ JSON.
	var legacy_path := "user://smoke_test_legacy.cfg"
	var legacy := ConfigFile.new()
	legacy.set_value("stars", "level_02", 3)
	legacy.set_value("endless_best_wave", "level_01", 17)
	legacy.set_value("flags", "tutorial_done", true)
	legacy.set_value("settings", "master_volume", 0.8)
	legacy.save(legacy_path)
	SaveManager.save_path = legacy_path
	_check(SaveManager.get_stars(&"level_02") == 3 and SaveManager.get_endless_best(&"level_01") == 17 \
			and SaveManager.get_flag("tutorial_done"), "chuyển tiến độ từ save.cfg cũ sang JSON")
	_check(FileAccess.file_exists(SaveManager.profile_path), "đã tạo hồ sơ JSON từ save cũ")
	for path in [legacy_path, SaveManager.profile_path, SaveManager.profile_path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	SaveManager.save_path = TEST_SAVE_PATH

	# Công thức thưởng cuối ván.
	var lost := {"won": false, "endless": false, "waves_survived": 5, "total_waves": 10}
	var won := {"won": true, "endless": false, "waves_survived": 10, "total_waves": 10}
	var endless := {"won": false, "endless": true, "waves_survived": 20, "total_waves": 0}
	_check(ProgressionManager.calculate_match_rewards(lost, 150) == {"coins": 61, "exp": 30}, "thua ở wave 5/10: 61 xu + 30 KN (%s)" % ProgressionManager.calculate_match_rewards(lost, 150))
	_check(ProgressionManager.calculate_match_rewards(won, 150) == {"coins": 210, "exp": 40}, "thắng 10/10: 210 xu + 40 KN")
	_check(ProgressionManager.calculate_match_rewards(endless, 150).coins == roundi(150 * pow(2.0, 1.3)), "vô tận wave 20: thưởng theo số wave")

	# Lên cấp: KN dư chuyển sang cấp sau, mỗi cấp mới thưởng xu.
	SaveManager.reset_progress()
	var levels := [0]
	var on_level := func(_new_level: int) -> void: levels[0] += 1
	Events.level_up.connect(on_level)
	var gained := ProgressionManager.add_exp(ProgressionManager.exp_to_next(1) + ProgressionManager.exp_to_next(2) + 5, "test")
	Events.level_up.disconnect(on_level)
	_check(gained == 2 and levels[0] == 2 and ProgressionManager.get_level() == 3 and ProgressionManager.get_exp() == 5, "lên 2 cấp, dư 5 KN")
	_check(EconomyManager.get_amount(EconomyManager.COINS) == 50 * 2 + 50 * 3, "thưởng lên cấp: 100 + 150 xu")
	SaveManager.reset_progress()
	_check(ProgressionManager.get_level() == 1 and EconomyManager.get_amount(EconomyManager.COINS) == 0, "xoá tiến độ: về cấp 1, 0 xu")


# --- Phần 1k: thành tựu, danh hiệu, thông báo, màn hình Thành tựu --------------------

func _test_achievements() -> void:
	print("[1k] Thành tựu")
	SaveManager.reset_progress()
	ToastLayer.clear()
	var defs := AchievementManager.defs
	_check(defs.size() >= 15, "có %d thành tựu" % defs.size())
	var categories := {}
	for def: AchievementDef in defs.values():
		categories[def.category] = true
		_check(def.stat_key != &"" or def.challenge != &"", "'%s' có điều kiện" % def.id)
	_check(categories.size() == 4, "đủ 4 loại thành tựu (cột mốc / thử thách / khám phá / ẩn)")

	# Theo bộ đếm: mở khoá + thông báo, chưa tự cộng thưởng.
	StatsManager.increment(StatsManager.WINS)
	_check(AchievementManager.is_unlocked(&"first_victory") and not AchievementManager.is_claimed(&"first_victory"), "thắng lần đầu => mở 'Phòng tuyến đầu tiên'")
	_check(ToastLayer.is_showing(), "mở thành tựu => hiện thông báo")
	_check(EconomyManager.get_amount(EconomyManager.COINS) == 0, "chưa bấm Nhận thì chưa cộng xu")
	_check(AchievementManager.get_unclaimed_count() == 1, "1 thưởng đang chờ nhận")

	# Nhận thưởng idempotent.
	_check(AchievementManager.claim(&"first_victory"), "nhận thưởng")
	_check(not AchievementManager.claim(&"first_victory") and not AchievementManager.unlock(&"first_victory"), "nhận / mở lần hai không có tác dụng")
	_check(EconomyManager.get_amount(EconomyManager.COINS) == 100, "chỉ cộng 100 xu đúng một lần")
	_check(not AchievementManager.claim(&"kills_1k"), "chưa mở thì không nhận được")

	# Thử thách: kiểm tra khi kết thúc ván.
	Events.match_ended.emit({"won": true, "endless": false, "lives_lost": 0, "lives_left": 20, "towers_built": 3,
			"tower_types": [&"archer"], "upgrades": 0, "waves_survived": 10, "total_waves": 10})
	for id in [&"perfect_clear", &"minimalist", &"one_type", &"no_upgrade"]:
		_check(AchievementManager.is_unlocked(id), "thử thách '%s' mở khi đạt điều kiện" % id)
	_check(not AchievementManager.is_unlocked(&"last_hp"), "'Sát nút' (ẩn) chưa mở khi còn 20 máu")
	Events.boss_killed.emit(&"boss", 25.0)
	_check(not AchievementManager.is_unlocked(&"boss_fast"), "hạ Boss sau 25s: chưa đạt 'Đồ tể'")
	Events.boss_killed.emit(&"boss", 6.0)
	_check(AchievementManager.is_unlocked(&"boss_fast"), "hạ Boss trong 6s: đạt 'Đồ tể'")

	# Danh hiệu.
	AchievementManager.claim(&"minimalist")
	_check("Tối Giản" in ProgressionManager.get_titles() and ProgressionManager.get_active_title() == "Tối Giản", "nhận danh hiệu và tự đeo danh hiệu đầu tiên")

	# Lưu / đọc lại giữ trạng thái mở / đã nhận.
	SaveManager.flush()
	SaveManager.save_path = TEST_SAVE_PATH
	_check(AchievementManager.is_claimed(&"minimalist") and AchievementManager.is_unlocked(&"boss_fast")
			and not AchievementManager.is_claimed(&"boss_fast"), "đọc lại hồ sơ: giữ trạng thái thành tựu")

	# Màn hình Thành tựu trong menu chính.
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame
	_check(menu._achievements_dot.visible and menu._achievements_dot.count == AchievementManager.get_unclaimed_count(), "chấm đỏ đếm thưởng chưa nhận (%d)" % menu._achievements_dot.count)
	menu.achievements_button.pressed.emit()
	var screen: AchievementsScreen = menu.achievements_screen
	_check(screen.visible and screen.claim_buttons.size() == defs.size(), "mở màn hình Thành tựu, đủ %d thẻ" % defs.size())
	var coins_before := EconomyManager.get_amount(EconomyManager.COINS)
	screen.claim_buttons[&"boss_fast"].pressed.emit()
	_check(AchievementManager.is_claimed(&"boss_fast") and EconomyManager.get_amount(EconomyManager.COINS) == coins_before + 300, "bấm Nhận trên thẻ: +300 xu")
	screen.filter = AchievementsScreen.Filter.HIDDEN
	screen.refresh()
	var hidden_count := 0
	for def: AchievementDef in defs.values():
		if def.is_hidden():
			hidden_count += 1
	_check(screen.claim_buttons.size() == hidden_count and screen.claim_buttons[&"last_hp"].text == "Chưa xong", "tab Ẩn: chỉ thành tựu ẩn, chưa mở thì 'Chưa xong'")
	screen.claim_all_button.pressed.emit()
	_check(AchievementManager.get_unclaimed_count() == 0, "Nhận tất cả")
	_press_key(KEY_ESCAPE)
	_check(not screen.visible and not menu._achievements_dot.visible, "Esc đóng màn hình; hết thưởng thì ẩn chấm đỏ")
	menu.queue_free()
	await get_tree().process_frame
	ToastLayer.clear()
	SaveManager.reset_progress()


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
	var expected := ProgressionManager.calculate_match_rewards(main.tracker.build_result(won, GameManager.calculate_stars()), level.coin_reward)
	_check(main.last_rewards.get("coins", -1) == expected.coins and expected.coins >= roundi(level.coin_reward * 1.4) - 1,
			"%s: thắng nhận %d xu (gồm thưởng thắng 40%%)" % [level.display_name, main.last_rewards.get("coins", -1)])
	_check(main.hud.reward_summary.visible, "%s: bảng kết quả hiện phần thưởng" % level.display_name)
	_check(AchievementManager.is_unlocked(&"first_victory"), "%s: thắng thật => mở thành tựu 'Phòng tuyến đầu tiên'" % level.display_name)
	var ground_lanes_used := 0
	for lane in main.map.get_paths():
		if spawns_per_lane.has(lane):
			ground_lanes_used += 1
	_check(ground_lanes_used == main.map.get_paths().size(), "%s: địch đi đủ %d làn mặt đất" % [level.display_name, main.map.get_paths().size()])
	_check(spawns_per_lane.has(main.map.get_air_paths()[0]), "%s: có địch bay trên làn trên không" % level.display_name)
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
	print("    thua ở wave %d, nhận %d xu + %d KN" % [waves.get_current_wave_number(),
			main.last_rewards.get("coins", 0), main.last_rewards.get("exp", 0)])
	_check(main.last_rewards.get("exp", 0) > 0, "%s: thua vẫn nhận KN" % level.display_name)
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


func _move_mouse(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
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
