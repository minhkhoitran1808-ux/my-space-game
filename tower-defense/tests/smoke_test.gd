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
	GameManager.unlock_all_towers = true # Phần [1s] tắt để kiểm tra mở khoá theo chiến dịch.
	SaveManager.save_path = TEST_SAVE_PATH
	SaveManager.reset_progress()

	await _test_systems()
	await _test_tower_management()
	await _test_tower_mechanics()
	await _test_new_enemies()
	await _test_wave_pacing()
	await _test_difficulty()
	await _test_terrain_and_unlocks()
	await _test_match_flow()
	await _test_level_flow()
	await _test_abilities_and_flying()
	await _test_endless()
	await _test_settings_and_tutorial()
	await _test_range_display()
	await _test_enemy_feedback()
	await _test_meta_foundation()
	await _test_achievements()
	await _test_inventory()
	await _test_shop()
	await _test_daily_and_codex()
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
	_check(build.available_towers.size() == 6, "có 6 loại tháp")
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
	_check(tower.get_sell_value() == 50 and tower.is_refundable_in_full(), "vừa xây (chưa sang wave mới): bán hoàn 100%% = hoàn tác (%d)" % tower.get_sell_value())
	GameManager.set_current_wave(GameManager.current_wave + 1) # Giả lập một wave mới bắt đầu.
	_check(tower.get_sell_value() == 35, "sang wave mới: giá bán = 70%% giá xây (%d)" % tower.get_sell_value())

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
	_check(tower.get_sell_value() == 35 + 60, "nâng cấp trong wave này: phần mới hoàn 100%%, phần cũ 70%% (%d)" % tower.get_sell_value())
	build.upgrade_tower(tower)
	_check(tower.get_level() == 3 and tower.can_upgrade() and tower.data.branches.size() == 2, "cấp 3: rẽ 2 nhánh cấp 4")
	panel.show_tower(tower)
	_check(panel.branch_b_button.visible and panel.upgrade_button.text.contains("Xạ thủ") and panel.branch_b_button.text.contains("Liên xạ"),
			"bảng tháp hiện 2 nút nhánh")
	_press_key(KEY_U, true) # Shift+U = nhánh B
	await get_tree().process_frame
	_check(tower.get_level() == 4 and tower.data.branch_name == "Liên xạ" and not tower.can_upgrade(), "Shift+U: lên nhánh B (Liên xạ), hết nâng cấp")
	_check(not build.upgrade_tower(tower), "không nâng quá cấp tối đa")
	GameManager.set_current_wave(GameManager.current_wave + 1)
	var invested := 50 + 60 + 100 + 145
	_check(tower.get_sell_value() == int(invested * 0.7), "giá bán tính cả tiền nâng cấp (%d)" % tower.get_sell_value())

	# Bán: hoàn tiền, giải phóng ô, tự bỏ chọn.
	gold_before = GameManager.gold
	var refund := build.sell_tower(tower)
	await get_tree().process_frame
	_check(GameManager.gold == gold_before + refund and refund == int(invested * 0.7), "bán tháp hoàn %d vàng" % refund)
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


# --- Phần 1o: cơ chế tháp mới (xuyên giáp, nhắm, Cờ hiệu, Mỏ vàng, nhánh, sóng toả) -----

func _test_tower_mechanics() -> void:
	print("[1o] Cơ chế tháp")
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var waves: WaveManager = main.wave_manager
	var path: Path2D = main.map.get_paths()[0]
	GameManager.add_gold(5000)
	var archer_data: TowerData = build.available_towers[0]
	var banner_data: TowerData = build.available_towers[4]
	var mine_data: TowerData = build.available_towers[5]
	_check(banner_data.id == &"banner" and mine_data.id == &"mine" and main.hud._buttons_by_tower.size() == 6, "có Cờ hiệu, Mỏ vàng và 6 nút tháp")

	# Xuyên giáp + sát thương tối thiểu.
	var armored := _spawn_test_enemy(path, waves.get_enemy_type(&"armored"))
	var hit := DamageInfo.new(28.0, DamageInfo.Type.PHYSICAL)
	hit.armor_pen = 0.5
	_check(is_equal_approx(armored.take_damage(hit), 28.0 * (1.0 - 0.6 * 0.5)), "xuyên giáp 50%%: 28 => 19.6 lên giáp 60%%")
	_check(is_equal_approx(armored.take_damage(DamageInfo.new(1.0, DamageInfo.Type.PHYSICAL)), 1.0), "mỗi đòn gây ít nhất 1 sát thương")
	_check(waves.get_enemy_type(&"basic") != null and build.available_towers[1].armor_pen == 0.5, "Pháo xuyên giáp 50%")

	# Nhắm: Đầu đoàn theo quãng đường CÒN LẠI; Yếu nhất / Mạnh nhất theo máu.
	_choose(build, archer_data)
	var archer := build.try_place_tower(Vector2i(4, 4))
	var near_base := _spawn_test_enemy(path, waves.get_enemy_type(&"basic"))
	var far_away := _spawn_test_enemy(path, waves.get_enemy_type(&"armored"))
	near_base.progress = 600.0
	far_away.progress = 200.0
	archer.target_mode = Tower.TargetMode.FIRST
	_check(archer._score_target(near_base) > archer._score_target(far_away), "Đầu đoàn: ưu tiên con còn ít đường hơn")
	archer.target_mode = Tower.TargetMode.WEAKEST
	_check(archer._score_target(near_base) > archer._score_target(far_away), "Yếu nhất: ưu tiên con ít máu hơn")
	archer.target_mode = Tower.TargetMode.STRONGEST
	_check(archer._score_target(far_away) > archer._score_target(near_base), "Mạnh nhất: ưu tiên con nhiều máu hơn")
	for enemy in [armored, near_base, far_away]:
		enemy.queue_free()

	# Cờ hiệu: buff tháp trong hào quang, không cộng dồn, bán thì mất buff.
	_choose(build, banner_data)
	var banner := build.try_place_tower(Vector2i(5, 4))
	_check(banner != null and not banner.data.is_attacker(), "Cờ hiệu không tự bắn")
	_check(is_equal_approx(archer.get_damage_multiplier(), 1.2), "tháp cạnh Cờ hiệu: +20%% sát thương (%.2f)" % archer.get_damage_multiplier())
	var banner2 := build.try_place_tower(Vector2i(5, 5))
	_check(is_equal_approx(archer.get_damage_multiplier(), 1.2), "2 Cờ hiệu không cộng dồn")
	build.upgrade_tower(banner2)
	_check(is_equal_approx(archer.get_damage_multiplier(), 1.25), "lấy Cờ hiệu mạnh nhất (cấp 2: +25%%)")
	_check(is_equal_approx(banner.get_damage_multiplier(), 1.0), "Cờ hiệu không tự buff nhau")
	build.sell_tower(banner)
	build.sell_tower(banner2)
	await get_tree().process_frame
	_check(is_equal_approx(archer.get_damage_multiplier(), 1.0), "bán hết Cờ hiệu: mất buff")

	# Mỏ vàng: +vàng mỗi wave; bán chỉ hoàn 50%.
	_choose(build, mine_data)
	var mine := build.try_place_tower(Vector2i(6, 4))
	var gold_before := GameManager.gold
	main._on_wave_completed(1, 0)
	_check(GameManager.gold == gold_before + 20 and main.tracker.gold_from_mines == 20, "hết wave: Mỏ vàng +20 vàng")
	GameManager.set_current_wave(GameManager.current_wave + 1)
	_check(mine.get_sell_value() == int(125 * 0.5), "Mỏ vàng bán hoàn 50%% (%d)" % mine.get_sell_value())

	# Nhánh cấp 4 + xem trước tầm bắn theo nhánh.
	build.upgrade_tower(archer)
	build.upgrade_tower(archer)
	main.selection_manager.select(archer)
	main.tower_info_panel.upgrade_hovered.emit(true, 0)
	var preview: RangeIndicator = main.range_display.get_upgrade_ring()
	_check(preview.is_shown() and is_equal_approx(preview.radius, archer_data.next_level.next_level.branches[0].attack_range), "rê chuột nhánh A: xem trước tầm 260")
	main.tower_info_panel.upgrade_hovered.emit(true, 1)
	_check(is_equal_approx(preview.radius, 180.0), "rê chuột nhánh B: xem trước tầm 180")
	main.tower_info_panel.upgrade_requested.emit(0)
	_check(archer.data.branch_name == "Xạ thủ" and archer.target_mode == Tower.TargetMode.STRONGEST, "lên Xạ thủ: tự đổi sang nhắm Mạnh nhất")
	for i in 20: # Vòng tầm bắn nở tới bán kính mới trong 0.2s.
		await get_tree().process_frame
	_check(is_equal_approx(archer.get_range(), 260.0) and is_equal_approx(main.range_display.get_selection_ring().radius, 260.0),
			"vòng tầm bắn theo nhánh mới (%.0f)" % main.range_display.get_selection_ring().radius)
	main.selection_manager.deselect()

	# Sóng toả (Băng nhánh B): trúng mọi địch trong tầm cùng lúc.
	var frost_data: TowerData = build.available_towers[2]
	_choose(build, frost_data)
	var frost := build.try_place_tower(Vector2i(4, 5))
	build.upgrade_tower(frost)
	build.upgrade_tower(frost)
	build.upgrade_tower(frost, 1)
	_check(frost.data.attack_type == TowerData.AttackType.PULSE, "Băng nhánh B là sóng toả")
	var victims: Array[Enemy] = []
	for p in [380.0, 410.0, 440.0]:
		var victim := _spawn_test_enemy(path, waves.get_enemy_type(&"basic"))
		victim.progress = p
		victims.append(victim)
	await get_tree().process_frame
	var in_range := victims.filter(func(enemy: Enemy) -> bool: return frost.is_in_range(enemy))
	frost._shoot(victims[0])
	_check(in_range.size() >= 2 and in_range.all(func(enemy: Enemy) -> bool:
			return enemy.health < enemy.max_health and enemy.status_effects.has_effect(&"slow")), "sóng toả: %d địch trong tầm đều trúng + chậm" % in_range.size())
	await _free_main(main)


# --- Phần 1p: địch mới + chống cày tiền -----------------------------------------------

func _test_new_enemies() -> void:
	print("[1p] Địch mới + chống cày tiền")
	var main := await _new_main()
	var waves: WaveManager = main.wave_manager
	var path: Path2D = main.map.get_paths()[0]
	for id in [&"wisp", &"splitter", &"splitling"]:
		_check(waves.get_enemy_type(id) != null, "có loại địch '%s'" % id)

	# Hồn ma kháng phép 60%.
	var wisp := _spawn_test_enemy(path, waves.get_enemy_type(&"wisp"))
	_check(is_equal_approx(wisp.take_damage(DamageInfo.new(100.0, DamageInfo.Type.MAGIC)), 40.0), "Hồn ma: phép 100 => 40")
	wisp.queue_free()

	# Vàng tăng 3% mỗi wave; quân sinh từ địch khác không cho vàng.
	var early: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"basic"), 1.0, 0.0, 300.0, 0)
	var late: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"basic"), 1.0, 0.0, 300.0, 9)
	_check(early.get_reward() == 8 and late.get_reward() == roundi(8 * 1.27), "vàng hạ địch: wave 1 = 8, wave 10 = %d" % late.get_reward())
	var gold_before := GameManager.gold
	var splitter: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"splitter"), 1.0, 0.0, 300.0)
	splitter.take_damage(DamageInfo.new(9999.0, DamageInfo.Type.TRUE))
	await get_tree().process_frame
	var spawned := get_tree().get_nodes_in_group(Enemy.GROUP).filter(func(node: Node) -> bool: return node.data.id == &"splitling")
	_check(spawned.size() == 3 and GameManager.gold == gold_before + 10, "Kẻ tách đôi chết: 3 mảnh tách, chỉ +10 vàng của con mẹ")
	gold_before = GameManager.gold
	for piece: Enemy in spawned:
		piece.take_damage(DamageInfo.new(9999.0, DamageInfo.Type.TRUE))
	_check(GameManager.gold == gold_before, "hạ mảnh tách: không cho vàng")

	# Boss gọi 2 lính mỗi 8 giây (không cho vàng); làm chậm bị giới hạn.
	var boss: Enemy = waves._spawn_enemy(waves.get_enemy_type(&"boss"), 1.0, 0.0, 500.0)
	await get_tree().process_frame
	var basics_before := get_tree().get_nodes_in_group(Enemy.GROUP).filter(func(node: Node) -> bool: return node.data.id == &"basic").size()
	boss.get_node("SummonerAura").summon()
	await get_tree().process_frame
	var summoned := get_tree().get_nodes_in_group(Enemy.GROUP).filter(func(node: Node) -> bool: return node.data.id == &"basic")
	_check(summoned.size() == basics_before + 2, "Boss gọi 2 lính")
	_check(summoned.all(func(node: Enemy) -> bool: return node == early or node == late or node.get_reward() == 0), "lính Boss gọi không cho vàng")
	var freeze: StatusEffectData = load("res://resources/effects/freeze.tres")
	boss.status_effects.apply(freeze)
	_check(is_equal_approx(boss.status_effects.get_speed_multiplier(), 1.0 - 0.4 * 0.5), "Boss: Băng giá chỉ làm chậm tối đa 20%% (%.2f)" % boss.status_effects.get_speed_multiplier())
	var boss_children_gold := GameManager.gold
	boss.take_damage(DamageInfo.new(999999.0, DamageInfo.Type.TRUE))
	await get_tree().process_frame
	var swarm_kids := get_tree().get_nodes_in_group(Enemy.GROUP).filter(func(node: Node) -> bool: return node.data.id == &"swarm")
	_check(swarm_kids.size() == 8 and swarm_kids.all(func(node: Enemy) -> bool: return node.get_reward() == 0), "con của Boss không cho vàng")
	_check(GameManager.gold > boss_children_gold, "hạ Boss vẫn cho vàng")
	await _free_main(main)


# --- Phần 1q: nhịp wave (nghỉ giữa wave, gọi sớm, thưởng hết wave, wave kiểm tra) -----

func _test_wave_pacing() -> void:
	print("[1q] Nhịp wave")
	var main := await _new_main()
	var waves: WaveManager = main.wave_manager
	var build: BuildManager = main.build_manager
	waves.auto_start_waves = true
	GameManager.add_gold(3000)
	for order in [[3, Vector2i(4, 4)], [3, Vector2i(4, 7)], [0, Vector2i(5, 3)]]:
		_choose(build, build.available_towers[order[0]])
		build.try_place_tower(order[1])
	build.cancel_build()

	# Trước wave 1: không đếm ngược, chờ người chơi bấm.
	for i in 120:
		await get_tree().process_frame
	_check(waves.get_current_wave_number() == 0 and waves.get_countdown() == 0.0, "wave 1 chờ người chơi bấm Start")
	waves.start_next_wave()
	while waves.is_spawning():
		await get_tree().process_frame
	_check(is_equal_approx(waves.get_countdown(), 20.0) or waves.get_countdown() > 19.9, "sinh xong wave 1: đếm ngược 20 giây")
	await get_tree().process_frame
	_check(main.hud.start_wave_button.text.contains("Wave 2 sau"), "nút wave hiện đếm ngược (%s)" % main.hud.start_wave_button.text)
	var frames := 0
	while waves.get_current_wave_number() == 1 and frames < 60 * 25:
		await get_tree().process_frame
		frames += 1
	_check(waves.get_current_wave_number() == 2 and frames > 60 * 19, "hết 20 giây: wave 2 tự bắt đầu (%.1fs)" % (frames / 60.0))

	# Gọi sớm: +vàng = số giây còn lại, kỹ năng hồi nhanh đúng chừng ấy.
	var abilities: AbilityManager = main.ability_manager
	var meteor: AbilityData = abilities.abilities[0]
	abilities.cast(meteor, Vector2(640, 360))
	while waves.is_spawning():
		await get_tree().process_frame
	for i in 60 * 5:
		await get_tree().process_frame
	var left := waves.get_countdown()
	var gold_before := GameManager.gold
	var cooldown_before := abilities.get_cooldown_remaining(meteor)
	var bonus := waves.get_early_call_bonus()
	waves.start_next_wave()
	_check(bonus == ceili(left) and bonus >= 14 and bonus <= 16 and GameManager.gold >= gold_before + bonus, "gọi sớm còn %.1fs: +%d vàng" % [left, bonus])
	_check(is_equal_approx(abilities.get_cooldown_remaining(meteor), cooldown_before - bonus), "gọi sớm: hồi chiêu kỹ năng giảm %d giây" % bonus)
	_check(waves.get_countdown() == 0.0, "gọi xong thì dừng đếm ngược")

	# Thưởng hết wave: file không ghi thì 15 + 3 × số wave.
	waves._waves[4].erase("reward_bonus")
	_check(waves.get_clear_bonus(5) == 30 and waves.get_clear_bonus(1) == int(waves._waves[0].reward_bonus), "thưởng hết wave: theo file, thiếu thì 15 + 3w")

	# Wave kiểm tra được báo trước một wave.
	waves._waves[5]["test"] = "Wave giáp nặng"
	main._on_wave_completed(5, 0)
	_check(main.hud.message_label.text == "Wave sau: Wave giáp nặng!", "báo trước wave kiểm tra (%s)" % main.hud.message_label.text)
	main.hud.set_next_wave_preview(6, waves.get_wave_composition(6), waves.get_wave_label(6))
	_check(main.hud.next_wave_label.text.begins_with("Wave giáp nặng:"), "xem trước wave tô nhãn kiểm tra")
	await _free_main(main)


# --- Phần 1r: độ khó Dễ / Thường / Khó ----------------------------------------------

func _test_difficulty() -> void:
	print("[1r] Độ khó")
	SaveManager.reset_progress()
	SaveManager.set_flag(TutorialManager.DONE_FLAG, true)
	GameManager.current_level = GameManager.LEVEL_CATALOG.levels[0]
	var expected_lives := [30, 20, 10]
	var expected_hp := [48.0, 60.0, 78.0]
	for difficulty in GameManager.Difficulty.size():
		GameManager.difficulty = difficulty
		var main := await _new_main()
		var enemy: Enemy = main.wave_manager._spawn_enemy(main.wave_manager.get_enemy_type(&"basic"), 1.0, 0.0, 300.0)
		_check(GameManager.lives == expected_lives[difficulty] and is_equal_approx(enemy.max_health, expected_hp[difficulty]),
				"%s: máu nhà %d, Lính thường %d máu" % [GameManager.DIFFICULTY_NAMES[difficulty], GameManager.lives, roundi(enemy.max_health)])
		await _free_main(main)

	# Thưởng meta nhân theo độ khó.
	var won := {"won": true, "endless": false, "waves_survived": 10, "total_waves": 10, "difficulty": GameManager.Difficulty.HARD}
	_check(ProgressionManager.calculate_match_rewards(won, 150) == {"coins": roundi(210 * 1.7), "exp": 68}, "thưởng ở Khó ×1.7 (%s)" % ProgressionManager.calculate_match_rewards(won, 150))

	# Sao lưu riêng từng độ khó; mở màn sau theo sao tốt nhất.
	SaveManager.record_result(&"level_01", 3, GameManager.Difficulty.EASY)
	SaveManager.record_result(&"level_01", 1, GameManager.Difficulty.HARD)
	_check(SaveManager.get_stars_for(&"level_01", GameManager.Difficulty.EASY) == 3 and SaveManager.get_stars_for(&"level_01", GameManager.Difficulty.HARD) == 1
			and SaveManager.get_stars_for(&"level_01", GameManager.Difficulty.NORMAL) == 0, "sao lưu riêng theo độ khó")
	_check(SaveManager.get_stars(&"level_01") == 3 and SaveManager.get_total_stars() == 3, "tổng sao lấy mức tốt nhất mỗi màn")

	# Hồ sơ phiên bản 1 (sao chưa có độ khó) được chuyển sang phiên bản 2 = Thường.
	var old_profile := {"save_version": 1, "stars": {"level_02": 2}}
	var migrated: Dictionary = SaveManager._migrate(old_profile)
	_check(migrated.save_version == 2 and migrated.stars == {"level_02:1": 2}, "nâng save v1 -> v2: sao cũ thành độ khó Thường")

	# Thành tựu độ khó Khó.
	Events.match_ended.emit({"won": true, "endless": false, "difficulty": GameManager.Difficulty.HARD, "lives_lost": 3, "lives_left": 7,
			"towers_built": 9, "tower_types": [&"archer", &"mage"], "upgrades": 4})
	_check(AchievementManager.is_unlocked(&"hard_win") and not AchievementManager.is_unlocked(&"hard_all"), "thắng 1 màn ở Khó: 'Không nao núng'")

	# Màn chọn màn: đổi độ khó, nhớ lựa chọn, thẻ hiện sao của độ khó đó.
	var select := LEVEL_SELECT_SCENE.instantiate()
	add_child(select)
	await get_tree().process_frame
	select.set_difficulty(GameManager.Difficulty.EASY)
	await get_tree().process_frame
	_check(GameManager.difficulty == GameManager.Difficulty.EASY and SaveManager.read_int(SaveManager.section("player"), "difficulty") == 0,
			"chọn Dễ: nhớ vào hồ sơ")
	_check(select.difficulty_buttons.size() == 3 and select.play_buttons[0].text == "Chơi lại", "thẻ màn 1 ở Dễ đã có sao")
	select.queue_free()
	await get_tree().process_frame
	GameManager.difficulty = GameManager.Difficulty.NORMAL
	GameManager.current_level = null
	ToastLayer.clear()
	SaveManager.reset_progress()


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
	_check(GameManager.gold == gold_before + bonus and bonus == 20, "gọi sớm ngay khi bắt đầu nghỉ: +20 vàng (%d)" % bonus)
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


# --- Phần 1s: địa hình (bùn / đồi) và mở tháp theo chiến dịch ---------------------

func _test_terrain_and_unlocks() -> void:
	print("[1s] Địa hình và mở khoá tháp")
	SaveManager.reset_progress()
	SaveManager.set_flag(TutorialManager.DONE_FLAG, true)
	GameManager.difficulty = GameManager.Difficulty.NORMAL
	var catalog := GameManager.LEVEL_CATALOG
	GameManager.current_level = catalog.levels[6] # Đầm lầy: có cả bùn lẫn đồi.
	var main := await _new_main()
	var map: GameMap = main.map
	_check(not map.get_terrain_polygons(GameMap.TERRAIN_MUD).is_empty() and not map.get_terrain_polygons(GameMap.TERRAIN_HILL).is_empty(),
			"màn Đầm lầy có vùng bùn và đồi")

	# Bùn: tìm một điểm trên đường nằm trong bùn, đặt địch đứng đó.
	var path: Path2D = map.get_paths()[0]
	var mud_progress := -1.0
	var step := 0.0
	while step < path.curve.get_baked_length():
		if map.get_terrain_at(path.to_global(path.curve.sample_baked(step))) == GameMap.TERRAIN_MUD:
			mud_progress = step + 12.0
			break
		step += 8.0
	_check(mud_progress > 0.0, "đường đi qua bùn")
	var basic: EnemyData = main.wave_manager.get_enemy_type(&"basic")
	var walker: Enemy = main.wave_manager._spawn_enemy(basic, 1.0, 0.0, mud_progress)
	var dry: Enemy = main.wave_manager._spawn_enemy(basic, 1.0, 0.0, 10.0)
	walker.base_speed = 0.001
	dry.base_speed = 0.001
	for i in 20:
		await get_tree().physics_frame
	_check(is_equal_approx(walker.status_effects.get_speed_multiplier(), 1.0 - GameMap.MUD_SLOW)
			and is_equal_approx(dry.status_effects.get_speed_multiplier(), 1.0),
			"lội bùn chậm 20%%, đất khô không chậm (%.2f / %.2f)" % [walker.status_effects.get_speed_multiplier(), dry.status_effects.get_speed_multiplier()])
	walker.queue_free()
	dry.queue_free()

	# Đồi: tháp xây trên ô đồi được +15% tầm, vòng tầm bắn vẽ đúng bán kính mới.
	var build: BuildManager = main.build_manager
	var archer: TowerData = build.available_towers[0]
	GameManager.add_gold(5000)
	var hill_cell := Vector2i(-1, -1)
	var flat_cell := Vector2i(-1, -1)
	for x in 20:
		for y in 12:
			var cell := Vector2i(x, y)
			if not build.get_placement_error(cell, archer).is_empty():
				continue
			if build.get_range_multiplier(cell) > 1.0:
				hill_cell = cell
			else:
				flat_cell = cell
	_check(hill_cell.x >= 0 and flat_cell.x >= 0, "có ô đồi và ô thường để xây")
	_choose(build, archer)
	var hill_tower := build.try_place_tower(hill_cell)
	_choose(build, archer)
	var flat_tower := build.try_place_tower(flat_cell)
	_check(hill_tower != null and is_equal_approx(hill_tower.get_range(), archer.attack_range * 1.15)
			and is_equal_approx(flat_tower.get_range(), archer.attack_range),
			"tháp trên đồi +15%% tầm (%d so với %d)" % [roundi(hill_tower.get_range()), roundi(flat_tower.get_range())])
	await _free_main(main)

	# Tháp mới khoá cho tới khi qua màn mở khoá.
	GameManager.unlock_all_towers = false
	var banner: TowerData = load("res://resources/towers/banner_tower.tres")
	var mine: TowerData = load("res://resources/towers/mine_tower.tres")
	_check(GameManager.get_unlock_level(banner) == catalog.levels[2] and GameManager.get_unlock_level(mine) == catalog.levels[4],
			"Cờ hiệu mở sau màn 3, Mỏ vàng sau màn 5")
	GameManager.current_level = catalog.levels[0]
	main = await _new_main()
	build = main.build_manager
	build.select_tower(banner)
	var banner_button: Button = main.hud._buttons_by_tower[banner]
	_check(build.selected_tower_data != banner and banner_button.disabled and banner_button.text.contains("Khoá"),
			"tháp chưa mở: không chọn được, nút bị khoá")
	_check(not main.hud._buttons_by_tower[build.available_towers[0]].disabled, "tháp cũ luôn mở")
	await _free_main(main)

	# Thắng màn 3 lần đầu: mở Cờ hiệu và hiện thông báo tháp mới.
	GameManager.current_level = catalog.levels[2]
	main = await _new_main()
	var toasts_before := ToastLayer.get_queue_size() + (1 if ToastLayer.is_showing() else 0)
	GameManager.win()
	await get_tree().process_frame
	_check(GameManager.is_tower_unlocked(banner) and not GameManager.is_tower_unlocked(mine), "thắng màn 3 => mở Cờ hiệu")
	_check(ToastLayer.get_queue_size() + (1 if ToastLayer.is_showing() else 0) > toasts_before, "hiện thông báo THÁP MỚI")
	await _free_main(main)
	GameManager.unlock_all_towers = true
	SaveManager.reset_progress()
	GameManager.current_level = null


# --- Phần 1d: luồng màn (menu, chọn màn, khoá / mở, sao) ----------------------

func _test_level_flow() -> void:
	print("[1d] Luồng màn")
	var catalog := GameManager.LEVEL_CATALOG
	_check(catalog.levels.size() == 8, "có 8 màn chơi")

	var select := LEVEL_SELECT_SCENE.instantiate()
	add_child(select)
	await get_tree().process_frame
	_check(select.play_buttons.size() == 8, "màn chọn màn có 8 thẻ")
	_check(select.cards_container.columns == 4, "thẻ màn xếp lưới 4 cột")
	var view: Rect2 = select.get_viewport_rect()
	var last_card: Control = select.cards_container.get_child(select.cards_container.get_child_count() - 1)
	_check(view.encloses(last_card.get_global_rect()) and view.encloses(select.back_button.get_global_rect()),
			"8 thẻ và nút Quay lại nằm gọn trong màn hình (%s)" % last_card.get_global_rect())
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
	_check(menu.stars_label.text.contains("2 / 24"), "menu chính hiện tổng sao (%s)" % menu.stars_label.text)
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


# --- Phần 1l: vật phẩm, kho đồ, skin, đồ tiêu hao, đồ rơi ----------------------------

func _test_inventory() -> void:
	print("[1l] Vật phẩm + kho đồ")
	SaveManager.reset_progress()
	var defs := InventoryManager.defs
	var tiers := {}
	for def: ItemDef in defs.values():
		tiers[def.rarity] = true
		if def.kind == ItemDef.Kind.SKIN:
			_check(ItemSlot.get_tower_data(def.tower_id) != null, "skin '%s' trỏ tới tháp có thật" % def.id)
		_check(not def.tradeable_p2p, "'%s' không trao đổi giữa người chơi" % def.id)
	_check(defs.size() >= 12 and tiers.size() == 5, "có %d vật phẩm, đủ 5 độ hiếm" % defs.size())

	# Nhận / bớt / trùng / phân rã.
	InventoryManager.grant(&"steel_shard", 3, "test")
	_check(InventoryManager.count(&"steel_shard") == 3 and InventoryManager.is_new(&"steel_shard"), "nhận 3 Mảnh thép (đánh dấu NEW)")
	_check(InventoryManager.consume(&"steel_shard", 2, "test") and InventoryManager.count(&"steel_shard") == 1, "dùng 2 còn 1")
	_check(not InventoryManager.consume(&"steel_shard", 5, "test"), "không đủ thì không bớt")
	var first := InventoryManager.grant(&"skin_frost_crystal", 1, "test")
	var dup := InventoryManager.grant(&"skin_frost_crystal", 1, "test")
	_check(not first.duplicate and dup.duplicate and dup.dust == Rarity.DUST_VALUES[Rarity.Tier.UNCOMMON]
			and InventoryManager.count(&"skin_frost_crystal") == 1, "skin trùng tự đổi thành %d Bụi" % dup.dust)
	_check(InventoryManager.salvage(&"steel_shard") == Rarity.DUST_VALUES[Rarity.Tier.COMMON] and not InventoryManager.owns(&"steel_shard"), "phân rã thành Bụi")
	_check(EconomyManager.get_amount(EconomyManager.DUST) == 15 + 5, "tổng Bụi = 20")

	# Đồ rơi: theo trọng số độ hiếm, không rơi đồ độc quyền thành tựu.
	InventoryManager.rng.seed = 1808
	var counts := [0, 0, 0, 0, 0]
	var exclusive_dropped := false
	for i in 2000:
		var drop := InventoryManager.roll_drop()
		counts[drop.rarity] += 1
		exclusive_dropped = exclusive_dropped or not drop.droppable
	_check(counts[0] > counts[1] and counts[1] > counts[2] and counts[2] > counts[3] and counts[0] > 1000, "tỉ lệ rơi giảm dần theo độ hiếm %s" % [counts])
	_check(not exclusive_dropped, "không rơi đồ độc quyền thành tựu")
	var won := {"won": true, "endless": false, "waves_survived": 10, "total_waves": 10}
	var lost_early := {"won": false, "endless": false, "waves_survived": 0, "total_waves": 10}
	_check(InventoryManager.grant_match_drops(won).size() == 2, "thắng: rơi 2 món")
	_check(InventoryManager.grant_match_drops(lost_early).is_empty(), "thua trắng (0 wave): không rơi đồ")

	# Thành tựu tặng skin độc quyền.
	AchievementManager.unlock(&"perfect_clear")
	AchievementManager.claim(&"perfect_clear")
	_check(InventoryManager.owns(&"skin_archer_silver"), "thành tựu 'Không một vết xước' tặng skin Thép Bạc")

	# Skin: trang bị rồi xây tháp => tháp dùng skin; ghost cũng vẽ được.
	_check(InventoryManager.equip_skin(&"skin_archer_silver") and InventoryManager.is_equipped(&"skin_archer_silver"), "trang bị skin")
	_check(not InventoryManager.equip_skin(&"skin_mage_void"), "không trang bị skin chưa có")

	# Đồ tiêu hao: chuẩn bị ở kho, dùng khi vào ván.
	InventoryManager.grant(&"gold_pouch_small", 1, "test")
	InventoryManager.grant(&"brick_patch", 1, "test")
	InventoryManager.grant(&"guardian_charm", 1, "test")
	# (Đồ rơi ngẫu nhiên ở trên có thể trùng các món này, nên so sánh theo số lượng trước / sau.)
	var pouches_before := InventoryManager.count(&"gold_pouch_small")
	var charms := InventoryManager.count(&"guardian_charm")
	_check(InventoryManager.toggle_prepared(&"gold_pouch_small") and InventoryManager.toggle_prepared(&"brick_patch"), "chuẩn bị 2 món")
	_check(not InventoryManager.toggle_prepared(&"guardian_charm"), "tối đa %d món mỗi ván" % InventoryManager.MAX_PREPARED)
	SaveManager.set_flag(TutorialManager.DONE_FLAG, true)
	GameManager.current_level = GameManager.LEVEL_CATALOG.levels[0]
	var main := await _new_main()
	var level: LevelData = main.level
	_check(GameManager.gold == level.starting_gold + roundi(level.starting_gold * 0.1) and GameManager.lives == level.starting_lives + 2,
			"vào ván: +10%% vàng (%d) và +2 máu (%d)" % [GameManager.gold, GameManager.lives])
	_check(InventoryManager.count(&"gold_pouch_small") == pouches_before - 1, "đồ tiêu hao đã dùng thì trừ đi 1")
	var tower: Tower = main.build_manager.try_place_tower(Vector2i(4, 4))
	_check(tower != null and tower.skin != null and tower.skin.id == &"skin_archer_silver", "tháp mới xây dùng skin đã trang bị")
	await _free_main(main)
	GameManager.current_level = null

	# Lưu / đọc lại.
	SaveManager.flush()
	SaveManager.save_path = TEST_SAVE_PATH
	_check(InventoryManager.count(&"guardian_charm") == charms and typeof(InventoryManager.count(&"guardian_charm")) == TYPE_INT
			and InventoryManager.is_equipped(&"skin_archer_silver"), "đọc lại: giữ kho đồ + skin đang dùng")

	# Màn hình Kho đồ.
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame
	_check(menu._inventory_dot.count == InventoryManager.get_new_count() and menu._inventory_dot.count > 0, "chấm đỏ đếm đồ mới")
	menu.inventory_button.pressed.emit()
	var screen: InventoryScreen = menu.inventory_screen
	_check(screen.visible and screen.slots.size() == InventoryManager.get_owned().size(), "Kho đồ hiện %d ô" % screen.slots.size())
	screen.slots[&"skin_frost_crystal"].pressed.emit()
	_check(screen.selected_item.id == &"skin_frost_crystal" and not InventoryManager.is_new(&"skin_frost_crystal"), "chọn ô: xem chi tiết, bỏ NEW")
	screen.equip_button.pressed.emit()
	_check(InventoryManager.is_equipped(&"skin_frost_crystal"), "bấm Trang bị")
	screen.slots[&"guardian_charm"].pressed.emit()
	screen.prepare_button.pressed.emit()
	_check(InventoryManager.is_prepared(&"guardian_charm"), "bấm Dùng ở ván sau")
	var dust_before := EconomyManager.get_amount(EconomyManager.DUST)
	screen.salvage_button.pressed.emit()
	_check(InventoryManager.count(&"guardian_charm") == charms - 1 and EconomyManager.get_amount(EconomyManager.DUST) == dust_before + 150, "bấm Phân rã: +150 Bụi")
	screen.close()
	menu.queue_free()
	await get_tree().process_frame
	ToastLayer.clear()
	SaveManager.reset_progress()


# --- Phần 1m: thương nhân, ghép đồ, cửa hàng ngày, nâng cấp vĩnh viễn -----------------

func _test_shop() -> void:
	print("[1m] Cửa hàng + thương nhân")
	SaveManager.reset_progress()
	_check(ShopManager.recipes.size() >= 4, "thương nhân có %d công thức" % ShopManager.recipes.size())

	# Thương nhân: thiếu đồ thì báo lý do; đủ thì đổi đúng tỉ giá.
	var shards: MerchantRecipe = ShopManager.recipes[&"steel_to_crystal"]
	_check(ShopManager.get_trade_error(shards) == "Thiếu 5 Mảnh thép", "thiếu đồ: \"%s\"" % ShopManager.get_trade_error(shards))
	_check(ShopManager.trade(shards).is_empty(), "thiếu đồ thì không đổi được")
	InventoryManager.grant(&"steel_shard", 6, "test")
	ShopManager.trade(shards)
	_check(InventoryManager.count(&"steel_shard") == 1 and InventoryManager.count(&"crystal") == 1, "5 Mảnh thép => 1 Tinh thể")
	InventoryManager.grant(&"crystal", 2, "test")
	EconomyManager.add(EconomyManager.DUST, 300, "test")
	var skin_result := ShopManager.trade(ShopManager.recipes[&"crystals_to_skin"])
	_check(skin_result.size() == 1 and skin_result[0].item.kind == ItemDef.Kind.SKIN and skin_result[0].item.rarity == Rarity.Tier.EPIC
			and not skin_result[0].duplicate, "3 Tinh thể + 300 Bụi => skin Sử thi chưa có")

	# Ghép đồ: 5 món cùng bậc (trộn loại) => 1 món bậc kế tiếp.
	InventoryManager.grant(&"gold_pouch_small", 4, "test")
	_check(ShopManager.get_fusable_count(Rarity.Tier.COMMON) == 5 and ShopManager.can_fuse(Rarity.Tier.COMMON), "có 5 món Thường để ghép")
	var fused := ShopManager.fuse(Rarity.Tier.COMMON)
	_check(fused.item.rarity == Rarity.Tier.UNCOMMON and ShopManager.get_fusable_count(Rarity.Tier.COMMON) == 0, "ghép ra món Ít gặp (%s)" % fused.item.display_name)
	_check(ShopManager.fuse(Rarity.Tier.COMMON).is_empty(), "không đủ 5 thì không ghép")

	# Cửa hàng hôm nay: cố định trong ngày, mỗi ô mua một lần, sang ngày mới thì đổi.
	ShopManager.date_override = "2026-01-01"
	var offers := ShopManager.get_daily_offers()
	var offer_ids := offers.map(func(def: ItemDef) -> StringName: return def.id)
	_check(offers.size() == ShopManager.SHOP_SLOTS and offer_ids == ShopManager.get_daily_offers().map(func(def: ItemDef) -> StringName: return def.id),
			"4 món, giống nhau mỗi lần mở trong ngày")
	_check(offers.all(func(def: ItemDef) -> bool: return def.droppable and def.kind != ItemDef.Kind.MATERIAL), "không bán nguyên liệu / đồ độc quyền")
	var slot := -1
	for i in offers.size():
		if offers[i].is_stackable() or not InventoryManager.owns(offers[i].id):
			slot = i
			break
	var price := ShopManager.price_of(offers[slot])
	_check(ShopManager.buy(slot).is_empty(), "thiếu xu thì không mua được")
	EconomyManager.add(EconomyManager.COINS, price, "test")
	_check(not ShopManager.buy(slot).is_empty() and EconomyManager.get_amount(EconomyManager.COINS) == 0, "mua với giá %d xu" % price)
	_check(ShopManager.is_bought(slot) and ShopManager.buy(slot).is_empty(), "mỗi ô chỉ mua một lần mỗi ngày")
	var other_day := false
	for day in ["2026-01-02", "2026-01-03", "2026-01-04"]:
		ShopManager.date_override = day
		other_day = other_day or ShopManager.get_daily_offers().map(func(def: ItemDef) -> StringName: return def.id) != offer_ids
	_check(other_day and not ShopManager.is_bought(slot), "sang ngày mới: hàng đổi, được mua lại")

	# Nâng cấp vĩnh viễn: giá tăng dần, có giới hạn, áp dụng khi vào ván.
	_check(ShopManager.get_upgrade_cost(&"treasury") == 300, "nâng cấp đầu tiên 300 xu")
	EconomyManager.add(EconomyManager.COINS, 5000, "test")
	_check(ShopManager.buy_upgrade(&"treasury") and ShopManager.get_upgrade_cost(&"treasury") == 345, "giá cấp 2 = 300 × 1.15 = 345")
	while ShopManager.buy_upgrade(&"treasury"):
		pass
	while ShopManager.buy_upgrade(&"walls"):
		pass
	_check(ShopManager.get_upgrade_level(&"treasury") == 5 and ShopManager.get_upgrade_cost(&"treasury") == -1
			and ShopManager.get_upgrade_level(&"walls") == 2, "có giới hạn: Kho bạc 5 cấp, Tường thành 2 cấp")
	var bonuses := ShopManager.get_upgrade_bonuses()
	_check(is_equal_approx(bonuses.bonus_gold_pct, 10.0) and is_equal_approx(bonuses.bonus_lives, 2.0), "tối đa +10% vàng, +2 máu")
	SaveManager.set_flag(TutorialManager.DONE_FLAG, true)
	GameManager.current_level = GameManager.LEVEL_CATALOG.levels[1]
	var main := await _new_main()
	_check(GameManager.gold == main.level.starting_gold + roundi(main.level.starting_gold * 0.1) and GameManager.lives == main.level.starting_lives + 2,
			"vào ván: nâng cấp vĩnh viễn được áp dụng")
	await _free_main(main)
	GameManager.current_level = null

	# Màn hình Cửa hàng (4 tab).
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame
	menu.shop_button.pressed.emit()
	var screen: ShopScreen = menu.shop_screen
	_check(screen.visible and screen.action_buttons.size() == ShopManager.SHOP_SLOTS, "tab Hôm nay: 4 nút mua")
	screen.tab = ShopScreen.Tab.MERCHANT
	screen.refresh()
	_check(screen.action_buttons[&"trade_steel_to_crystal"].disabled, "tab Thương nhân: thiếu đồ thì nút xám")
	InventoryManager.grant(&"steel_shard", 5, "test")
	var shards_before := InventoryManager.count(&"steel_shard")
	var crystals_before := InventoryManager.count(&"crystal")
	screen.refresh()
	screen.action_buttons[&"trade_steel_to_crystal"].pressed.emit()
	_check(InventoryManager.count(&"crystal") == crystals_before + 1 and InventoryManager.count(&"steel_shard") == shards_before - 5, "bấm Đổi trên thẻ")
	screen.tab = ShopScreen.Tab.UPGRADES
	screen.refresh()
	_check(screen.action_buttons[&"upgrade_treasury"].disabled and screen.action_buttons[&"upgrade_treasury"].text == "Tối đa", "tab Nâng cấp: đã tối đa thì khoá")
	screen.close()
	menu.queue_free()
	await get_tree().process_frame
	ShopManager.date_override = ""
	ToastLayer.clear()
	SaveManager.reset_progress()


# --- Phần 1n: nhiệm vụ ngày, quà đăng nhập, Codex, hub menu chính --------------------

func _test_daily_and_codex() -> void:
	print("[1n] Nhiệm vụ ngày + quà đăng nhập + Codex")
	SaveManager.reset_progress()
	DailyManager.date_override = "2026-03-10"
	_check(DailyManager.defs.size() >= 6, "có %d mẫu nhiệm vụ" % DailyManager.defs.size())
	var active := DailyManager.get_active()
	_check(active.size() == DailyManager.QUESTS_PER_DAY, "ngày đầu: 3 nhiệm vụ")
	var unique_ids := {}
	for item: Dictionary in active:
		unique_ids[item.id] = true
	_check(unique_ids.size() == active.size(), "3 nhiệm vụ khác nhau")

	# Tiến độ tính từ lúc nhận: làm đủ thì Nhận được, đúng một lần.
	var quest: Dictionary = active[0]
	var def := DailyManager.get_def(quest)
	_check(DailyManager.get_progress(quest).x == 0 and not DailyManager.claim_quest(0), "chưa làm thì chưa nhận được")
	StatsManager.increment(def.stat_key, def.target)
	var level_exp_before := ProgressionManager.get_exp() + ProgressionManager.get_level() * 100000
	_check(DailyManager.is_complete(quest) and DailyManager.get_claimable_quest_count() >= 1, "làm đủ: '%s' hoàn thành" % def.get_text())
	_check(DailyManager.claim_quest(0) and not DailyManager.claim_quest(0), "nhận thưởng nhiệm vụ đúng một lần")
	_check(EconomyManager.get_amount(EconomyManager.COINS) == def.reward_coins
			and ProgressionManager.get_exp() + ProgressionManager.get_level() * 100000 > level_exp_before, "nhận %d xu + KN" % def.reward_coins)

	# Đổi miễn phí 1 lần / ngày.
	var old_id: String = DailyManager.get_active()[1].id
	_check(DailyManager.reroll(1) and DailyManager.get_active()[1].id != old_id, "đổi nhiệm vụ miễn phí")
	_check(not DailyManager.can_reroll() and not DailyManager.reroll(2), "chỉ đổi 1 lần mỗi ngày")

	# Ngày mới: nhiệm vụ đã nhận bị bỏ, nhiệm vụ chưa làm được giữ, thêm 3 nhiệm vụ mới.
	DailyManager.date_override = "2026-03-11"
	_check(DailyManager.get_active().size() == 2 + 3 and DailyManager.can_reroll(), "ngày sau: giữ 2 cũ + 3 mới, được đổi lại")
	# Nghỉ 10 ngày: chỉ giữ tối đa 3 ngày nhiệm vụ.
	DailyManager.date_override = "2026-03-21"
	var days := {}
	for item: Dictionary in DailyManager.get_active():
		days[item.day] = true
	_check(DailyManager.get_active().size() == 9 and days.size() == 3, "nghỉ lâu: tích luỹ tối đa 3 ngày (9 nhiệm vụ)")

	# Quà đăng nhập: mỗi ngày 1 lần, bỏ lỡ ngày không bị reset.
	_check(DailyManager.can_claim_login() and DailyManager.get_login_index() == 0, "có quà ngày 1")
	var gift := DailyManager.claim_login()
	_check(not gift.is_empty() and DailyManager.claim_login().is_empty(), "nhận quà hôm nay đúng một lần")
	DailyManager.date_override = "2026-03-22"
	DailyManager.claim_login()
	DailyManager.date_override = "2026-03-30" # Bỏ lỡ 7 ngày.
	_check(DailyManager.can_claim_login() and DailyManager.get_login_index() == 2, "bỏ lỡ nhiều ngày: vẫn tiếp tục ngày 3 (không reset)")

	# Lưu / đọc lại.
	SaveManager.flush()
	SaveManager.save_path = TEST_SAVE_PATH
	_check(DailyManager.get_login_claimed_total() == 2 and DailyManager.get_active().size() == 9, "đọc lại: giữ chuỗi đăng nhập + nhiệm vụ")

	# Hub menu chính: thẻ hồ sơ + chấm đỏ Nhiệm vụ + Codex.
	StatsManager._on_enemy_seen(&"basic")
	StatsManager._on_enemy_seen(&"healer")
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame
	_check(menu.profile_chip.visible and menu._quests_dot.count == DailyManager.get_claimable_count() and menu._quests_dot.count >= 1, "hub: thẻ hồ sơ + chấm đỏ Nhiệm vụ (%d)" % menu._quests_dot.count)
	_check(menu.settings_button.get_parent() == menu._meta_grid, "nút Cài đặt nằm trong lưới hub")
	menu.quests_button.pressed.emit()
	_check(menu.quests_screen.visible and menu.quests_screen.claim_buttons.size() == 9, "màn Nhiệm vụ: 9 thẻ")
	menu.quests_screen.login_button.pressed.emit()
	_check(DailyManager.get_login_claimed_total() == 3 and menu.quests_screen.login_button.disabled, "bấm Nhận quà hôm nay")
	menu.quests_screen.close()
	menu.codex_button.pressed.emit()
	var codex: CodexScreen = menu.codex_screen
	_check(codex.visible and codex.shown_count == waves_enemy_count() and codex._summary.text.begins_with("Đã gặp 2 /"), "Codex: đủ loại địch, đã gặp 2 (%s)" % codex._summary.text)
	codex.tab = CodexScreen.Tab.ITEMS
	codex.refresh()
	_check(codex.shown_count == InventoryManager.defs.size(), "Codex vật phẩm: đủ %d ô" % codex.shown_count)
	codex.close()
	menu.queue_free()
	await get_tree().process_frame
	DailyManager.date_override = ""
	ToastLayer.clear()
	SaveManager.reset_progress()


func waves_enemy_count() -> int:
	var count := 0
	for file_name in ResourceLoader.list_directory("res://resources/enemies"):
		if file_name.ends_with(".tres"):
			count += 1
	return count


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
	_check(main.last_rewards.get("drops", []).size() == 2, "%s: thắng rơi 2 vật phẩm" % level.display_name)
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
	# Test tự quyết khi nào gọi wave; phần [1q] bật lại để kiểm tra đếm ngược.
	main.wave_manager.auto_start_waves = false
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


## Chọn loại tháp để xây (select_tower là bật / tắt nên chỉ gọi khi chưa chọn đúng loại).
func _choose(build: BuildManager, tower_data: TowerData) -> void:
	if build.selected_tower_data != tower_data:
		build.select_tower(tower_data)


func _press_key(keycode: Key, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.shift_pressed = shift
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
