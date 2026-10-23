class_name Projectile
extends Node2D
## Viên đạn bay đuổi theo mục tiêu.
##
## Nếu mục tiêu chết giữa đường, đạn vẫn bay tới vị trí cuối cùng của nó:
## đạn nổ lan (splash) vẫn gây sát thương xung quanh, đạn thường thì trượt.

## Phát ra khi đạn chạm đích (dùng cho hiệu ứng nổ sau này).
signal impacted(impact_position: Vector2, splash_radius: float)

const HIT_DISTANCE := 8.0

var target: Enemy = null
var damage_info: DamageInfo = null
var speed: float = 500.0
var splash_radius: float = 0.0
var color: Color = Color.WHITE
var radius: float = 4.0

var _target_position := Vector2.ZERO


## Gọi trước khi add_child().
func setup(p_target: Enemy, p_info: DamageInfo, p_speed: float, p_splash_radius: float, p_color: Color) -> void:
	target = p_target
	damage_info = p_info
	speed = p_speed
	splash_radius = p_splash_radius
	color = p_color
	radius = 7.0 if splash_radius > 0.0 else 4.0
	_target_position = p_target.global_position


func _process(delta: float) -> void:
	if is_instance_valid(target) and target.is_alive():
		_target_position = target.global_position

	var to_target := _target_position - global_position
	var step := speed * delta
	if to_target.length() <= maxf(step, HIT_DISTANCE):
		global_position = _target_position
		_impact()
		return
	global_position += to_target.normalized() * step
	rotation = to_target.angle()


func _impact() -> void:
	var primary: Enemy = target if is_instance_valid(target) else null
	Combat.apply_hit(primary, global_position, damage_info, splash_radius, get_tree())
	impacted.emit(global_position, splash_radius)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_line(Vector2(-radius * 2.0, 0), Vector2.ZERO, Color(color, 0.5), radius)
