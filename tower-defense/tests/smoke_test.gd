extends Node
## Smoke test tự động: chứng minh game vẫn chơi được sau mỗi lần sửa code.
##
## Chạy (không cần mở editor):
##   godot --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn
## --fixed-fps 60 giúp mô phỏng chạy nhanh hết mức nhưng vẫn đúng như 60 FPS.
## Kết thúc với exit code 0 nếu tất cả đều đạt, 1 nếu có lỗi.
##
## Gồm 3 phần, mỗi phần dùng một bản Main mới:
##   1. Kiểm tra từng hệ thống (kháng sát thương, làm chậm, đặt tháp, dữ liệu wave,
##      nâng cấp / bán, chọn tháp bằng chuột và phím tắt...).
##   2. Bot đặt tháp theo kế hoạch, nâng cấp khi dư tiền, và phải THẮNG đủ mọi wave.
##   3. Không đặt tháp nào thì phải THUA (đảm bảo game không quá dễ).

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
## Giới hạn số frame cho mỗi lượt chơi để test không bao giờ treo.
const MAX_FRAMES_PER_RUN := 60 * 60 * 30

## Kế hoạch xây của bot: [chỉ số tháp trong available_towers, ô lưới].
## 0 = Cung thủ, 1 = Pháo, 2 = Băng, 3 = Phép.
const BOT_BUILD_ORDER := [
	[0, Vector2i(4, 7)], [0, Vector2i(8, 7)], [0, Vector2i(10, 4)],
	[2, Vector2i(8, 4)], [1, Vector2i(4, 4)], [3, Vector2i(10, 7)],
	[1, Vector2i(14, 4)], [3, Vector2i(16, 6)], [0, Vector2i(2, 3)],
	[2, Vector2i(14, 6)], [3, Vector2i(6, 7)], [1, Vector2i(12, 4)],
	[3, Vector2i(2, 7)], [0, Vector2i(10, 2)], [1, Vector2i(16, 8)],
	[3, Vector2i(12, 2)], [3, Vector2i(6, 4)], [1, Vector2i(6, 9)],
]

var _failures := PackedStringArray()


func _ready() -> void:
	print("=== SMOKE TEST ===")
	await _test_systems()
	await _test_tower_management()
	await _test_bot_playthrough()
	await _test_defeat_without_towers()

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
	var path: Path2D = main.get_node("Enemies/EnemyPath")

	# Dữ liệu wave
	_check(waves.validate_waves().is_empty(), "waves.json hợp lệ: %s" % [waves.validate_waves()])
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


# --- Phần 2: bot chơi hết game --------------------------------------------------

func _test_bot_playthrough() -> void:
	print("[2] Bot chơi hết các wave")
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var waves: WaveManager = main.wave_manager
	var next_build := 0
	var upgrades := 0
	var frames := 0

	while GameManager.is_playing() and frames < MAX_FRAMES_PER_RUN:
		# Mua tháp theo kế hoạch khi đủ tiền.
		while next_build < BOT_BUILD_ORDER.size():
			var order: Array = BOT_BUILD_ORDER[next_build]
			var tower_data: TowerData = build.available_towers[order[0]]
			if not GameManager.can_afford(tower_data.cost):
				break
			build.select_tower(tower_data) if build.selected_tower_data != tower_data else null
			_check(build.try_place_tower(order[1]) != null, "bot đặt %s tại %s" % [tower_data.display_name, order[1]])
			next_build += 1

		# Xây hết kế hoạch rồi thì dùng tiền thừa nâng cấp tháp có giá nâng cấp rẻ nhất.
		if next_build >= BOT_BUILD_ORDER.size():
			var cheapest: Tower = null
			for tower in build.get_towers():
				if tower.can_upgrade() and (cheapest == null or tower.get_upgrade_cost() < cheapest.get_upgrade_cost()):
					cheapest = tower
			if cheapest and GameManager.can_afford(cheapest.get_upgrade_cost()):
				build.upgrade_tower(cheapest)
				upgrades += 1

		if waves.can_start_next_wave():
			if waves.get_current_wave_number() > 0:
				print("    sau wave %2d: máu=%2d vàng=%4d tháp=%d" \
						% [waves.get_current_wave_number(), GameManager.lives, GameManager.gold, next_build])
			waves.start_next_wave()
		await get_tree().process_frame
		frames += 1

	print("    kết thúc: %s, máu còn %d, %d tháp, %d lần nâng cấp" \
			% [GameManager.GameState.keys()[GameManager.state], GameManager.lives, next_build, upgrades])
	var total_kills := 0
	for tower in build.get_towers():
		total_kills += tower.kills
	_check(total_kills > 100, "tháp ghi nhận số địch hạ (%d)" % total_kills)
	_check(GameManager.state == GameManager.GameState.VICTORY, "bot thắng cả %d wave" % waves.get_total_waves())
	_check(main.hud.game_over_panel.visible, "hiện bảng kết thúc khi thắng")
	await _free_main(main)


# --- Phần 3: không xây gì thì phải thua -----------------------------------------

func _test_defeat_without_towers() -> void:
	print("[3] Không đặt tháp thì phải thua")
	var main := await _new_main()
	var waves: WaveManager = main.wave_manager
	var frames := 0
	while GameManager.is_playing() and frames < MAX_FRAMES_PER_RUN:
		if waves.can_start_next_wave():
			waves.start_next_wave()
		await get_tree().process_frame
		frames += 1
	print("    thua ở wave %d" % waves.get_current_wave_number())
	_check(GameManager.state == GameManager.GameState.DEFEAT, "không xây tháp thì thua")
	await _free_main(main)


# --- Tiện ích -------------------------------------------------------------------

func _new_main() -> Node:
	get_tree().paused = false
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
