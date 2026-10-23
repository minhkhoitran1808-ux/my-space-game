class_name SummonerAura
extends Node2D
## Địch gọi quân (EnemyData.summon_interval > 0, vd Boss): cứ summon_interval giây phát
## Enemy.summon_requested; WaveManager sinh quân ngay sau lưng (không cho vàng).
## Mỗi lần gọi có vòng đỏ sẫm loé ra để người chơi biết vì sao địch tự nhiên đông lên.

const PULSE_TIME := 0.4
const COLOR := Color("8C2F39")

var _enemy: Enemy
var _timer := 0.0
var _pulse_age := INF


func setup(enemy: Enemy) -> void:
	_enemy = enemy
	_timer = enemy.data.summon_interval
	show_behind_parent = true


func _process(delta: float) -> void:
	if _enemy == null or not _enemy.is_alive():
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer += _enemy.data.summon_interval
		summon()
	if _pulse_age < PULSE_TIME:
		_pulse_age += delta
		queue_redraw()


## Gọi quân ngay lập tức.
func summon() -> void:
	_enemy.summon_requested.emit(_enemy, _enemy.data.summon_enemy, _enemy.data.summon_count)
	_pulse_age = 0.0
	queue_redraw()


func _draw() -> void:
	if _pulse_age >= PULSE_TIME:
		return
	var t := _pulse_age / PULSE_TIME
	var radius := _enemy.data.radius * (1.2 + (0.0 if VisualSettings.reduced_motion else 1.3 * t))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(COLOR, 0.9 * (1.0 - t)), 4.0, true)
