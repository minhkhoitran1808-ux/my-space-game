extends "res://tests/smoke_test.gd"
## Đo hiệu năng logic + đồng bộ 3D: N địch cùng lúc ở tốc độ x3, 3D bật, 16 tháp đang bắn.
##   godot --headless --path . --fixed-fps 60 res://tests/benchmark.tscn -- [số địch] [số khung] [3d|2d]
## In ra thời gian xử lý trung bình / khung (ms) và số node tạo mới trong lúc đo.
## Không nằm trong smoke test vì kết quả phụ thuộc máy.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var enemy_count := int(args[0]) if args.size() > 0 else 150
	var frames := int(args[1]) if args.size() > 1 else 300
	var use_3d := args.size() < 3 or args[2] != "2d"
	GameManager.block_scene_changes = true
	GameManager.unlock_all_towers = true
	SaveManager.save_path = "user://benchmark_save.cfg"
	SaveManager.reset_progress()
	SaveManager.set_flag(TutorialManager.DONE_FLAG, true)
	SaveManager.set_setting("view_3d", use_3d)
	MatchTracker.log_dir = ""
	GameManager.current_level = GameManager.LEVEL_CATALOG.levels[7]
	var main := await _new_main()
	var build: BuildManager = main.build_manager
	var waves: WaveManager = main.wave_manager
	GameManager.add_gold(100000)
	GameManager.debug_invincible = true
	var samples := _path_samples(main.map.get_paths())
	for i in 16:
		var data: TowerData = build.available_towers[BOT_TOWER_ROTATION[i % BOT_TOWER_ROTATION.size()]]
		_choose(build, data)
		build.try_place_tower(_bot_best_cell(build, data, samples))
	build.cancel_build()
	GameManager.set_game_speed(3.0)

	# Giữ đủ enemy_count địch trên bản đồ (địch chết / về đích thì sinh bù), địch trâu để không chết quá nhanh.
	var types := [&"basic", &"fast", &"armored", &"swarm", &"bat", &"wisp", &"healer", &"splitter"]
	var spawn_index := 0
	var spent_usec := 0
	var created_before := 0
	var instances_before := 0
	for frame in frames + 60:
		while waves.get_alive_enemy_count() < enemy_count:
			var data := waves.get_enemy_type(types[spawn_index % types.size()])
			waves._spawn_enemy(data, 8.0, 1.0, randf() * 600.0, WaveManager.DEBUG_WAVE_INDEX)
			spawn_index += 1
		if frame == 60:
			created_before = main.view_3d.units.pool.created
			instances_before = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
			spawn_index = 0
		var start := Time.get_ticks_usec()
		await get_tree().process_frame
		if frame >= 60:
			spent_usec += Time.get_ticks_usec() - start
	var process_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	print("BENCH %s enemies=%d frames=%d avg_frame=%.2fms last_process=%.2fms new_visuals=%d enemies_spawned=%d nodes=%d->%d" % [
			"3D" if use_3d else "2D", enemy_count, frames, spent_usec / 1000.0 / frames, process_ms,
			main.view_3d.units.pool.created - created_before, spawn_index,
			instances_before, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	GameManager.debug_invincible = false
	GameManager.set_game_speed(1.0)
	await _free_main(main)
	SaveManager.reset_progress()
	AudioManager.quit_game(0)
