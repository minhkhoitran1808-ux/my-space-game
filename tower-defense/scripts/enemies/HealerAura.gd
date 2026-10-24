class_name HealerAura
extends Node2D
## Hào quang hồi máu của địch "Thầy lang" (EnemyData.heal_radius > 0).
##
## Cứ heal_interval giây, hồi heal_amount máu (nhân theo hệ số máu của wave) cho mọi địch
## KHÁC còn sống trong bán kính heal_radius, kể cả địch bay. Bản thân Thầy lang không tự hồi,
## nên người chơi có lý do ưu tiên hạ nó trước (chế độ ngắm "Nhiều máu nhất" / "Gần nhất").
##
## Mỗi lần hồi có một vòng xanh lan ra để người chơi thấy phạm vi; giảm chuyển động thì vòng
## chỉ mờ dần tại chỗ. Chỉ vẽ lại trong lúc vòng đang hiện.

const PULSE_TIME := 0.45
const COLOR := Color("4ADE80")

var _enemy: Enemy
var _timer := 0.0
var _pulse_age := INF


## Enemy gọi khi data có heal_radius > 0.
func setup(enemy: Enemy) -> void:
	_enemy = enemy
	# Lần hồi đầu tiên sớm hơn một chút để người chơi nhận ra ngay vai trò của nó.
	_timer = enemy.data.heal_interval * 0.5
	show_behind_parent = true # Vòng nằm dưới thân Thầy lang (z_index âm sẽ chui xuống dưới cả nền).


func _process(delta: float) -> void:
	if _enemy == null or not _enemy.is_alive():
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer += _enemy.data.heal_interval
		heal_nearby()
	if _pulse_age < PULSE_TIME:
		_pulse_age += delta
		queue_redraw()


## Hồi máu cho các địch xung quanh ngay lập tức. Trả về số địch thực sự được hồi.
func heal_nearby() -> int:
	var data := _enemy.data
	var amount := data.heal_amount * _enemy.health_multiplier
	var radius_squared := data.heal_radius * data.heal_radius
	var healed := 0
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var other := node as Enemy
		if other == null or other == _enemy or not other.is_alive():
			continue
		if other.global_position.distance_squared_to(_enemy.global_position) <= radius_squared:
			if other.heal(amount) > 0.0:
				healed += 1
	_pulse_age = 0.0
	queue_redraw()
	return healed


func _draw() -> void:
	if _pulse_age >= PULSE_TIME:
		return
	var t := _pulse_age / PULSE_TIME
	var radius := _enemy.data.heal_radius
	if not VisualSettings.reduced_motion:
		radius *= 0.3 + 0.7 * (1.0 - (1.0 - t) * (1.0 - t))
	draw_circle(Vector2.ZERO, radius, Color(COLOR, 0.12 * (1.0 - t)))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(COLOR, 0.8 * (1.0 - t)), 2.0, true)
