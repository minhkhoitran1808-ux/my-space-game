class_name DebugTools
extends Node2D
## Phím debug để thử cân bằng nhanh. Main chỉ tạo node này khi OS.is_debug_build()
## (chạy từ editor / bản debug), nên bản phát hành không có.
##
## Ctrl+1: +1000 vàng          Ctrl+4: lớp phủ (tầm bắn, DPS 5 giây, máu địch)
## Ctrl+2: kết thúc wave       Ctrl+5: tốc độ x8 (bấm lại về x1)
## Ctrl+3: bất tử (bật / tắt)  Ctrl+6: sinh lần lượt từng loại địch
## Dùng Ctrl+số để không đụng phím 1–6 (chọn tháp) và F (đổi tốc độ).

const GOLD_STEP := 1000
const FAST_SPEED := 8.0
## Cửa sổ đo DPS (giây) và chu kỳ lấy mẫu.
const DPS_WINDOW := 5.0
const SAMPLE_INTERVAL := 0.5

var main: Node
var overlay := false
var _spawn_index := 0
## tower -> Array[float] sát thương cộng dồn tại mỗi lần lấy mẫu (mới nhất ở cuối).
var _samples: Dictionary = {}
var _sample_timer := 0.0


func setup(p_main: Node) -> void:
	main = p_main
	z_index = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not key.ctrl_pressed:
		return
	match key.keycode:
		KEY_1:
			GameManager.add_gold(GOLD_STEP)
			_notify("+%d vàng" % GOLD_STEP)
		KEY_2:
			main.wave_manager.debug_end_wave()
			_notify("Kết thúc wave")
		KEY_3:
			GameManager.debug_invincible = not GameManager.debug_invincible
			_notify("Bất tử: " + ("BẬT" if GameManager.debug_invincible else "TẮT"))
		KEY_4:
			overlay = not overlay
			_samples.clear()
			queue_redraw()
		KEY_5:
			GameManager.set_game_speed(1.0 if GameManager.game_speed >= FAST_SPEED else FAST_SPEED)
			_notify("Tốc độ x%d" % GameManager.game_speed)
		KEY_6:
			var types: Array[EnemyData] = main.wave_manager.get_enemy_types()
			var data := types[_spawn_index % types.size()]
			_spawn_index += 1
			main.wave_manager.debug_spawn(data)
			_notify("Sinh " + data.display_name)
		_:
			return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not overlay:
		return
	_sample_timer -= delta
	if _sample_timer <= 0.0:
		_sample_timer = SAMPLE_INTERVAL
		for tower: Tower in get_tree().get_nodes_in_group(Tower.GROUP):
			var history: Array = _samples.get_or_add(tower, [])
			history.append(tower.damage_dealt)
			if history.size() > int(DPS_WINDOW / SAMPLE_INTERVAL) + 1:
				history.pop_front()
	queue_redraw()


## DPS trung bình của tháp trong DPS_WINDOW giây gần nhất (0 nếu chưa đủ mẫu).
func get_dps(tower: Tower) -> float:
	var history: Array = _samples.get(tower, [])
	if history.size() < 2:
		return 0.0
	return (history.back() - history.front()) / ((history.size() - 1) * SAMPLE_INTERVAL)


func _draw() -> void:
	if not overlay:
		return
	var font := ThemeDB.fallback_font
	for tower: Tower in get_tree().get_nodes_in_group(Tower.GROUP):
		var at := tower.global_position
		if tower.data.is_attacker():
			draw_arc(at, tower.get_range(), 0.0, TAU, 64, Color(1, 1, 1, 0.35), 1.5)
		elif tower.data.aura_radius > 0.0:
			draw_arc(at, tower.data.aura_radius, 0.0, TAU, 64, Color(1, 0.85, 0.3, 0.45), 1.5)
		draw_string_outline(font, at + Vector2(-28, -36), "DPS %d" % roundi(get_dps(tower)),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color.BLACK)
		draw_string(font, at + Vector2(-28, -36), "DPS %d" % roundi(get_dps(tower)),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.95, 0.5))
	for enemy: Enemy in get_tree().get_nodes_in_group(Enemy.GROUP):
		var text := "%d" % ceili(enemy.health)
		var at := enemy.global_position + Vector2(-12, enemy.data.radius + 16)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _notify(text: String) -> void:
	ToastLayer.push("DEBUG", text, "", Color("#9B5DE5"))
