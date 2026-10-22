class_name Tower
extends Node2D
## Tháp cơ bản: tự chọn mục tiêu trong tầm và gây sát thương tức thời (hitscan).
##
## Chưa có đạn bay: mỗi phát bắn trừ máu ngay và vẽ một tia sáng ngắn để thấy được.
## Sau này muốn có đạn, chỉ cần thay nội dung hàm _shoot().

## Phát ra mỗi lần bắn.
signal fired(target: Enemy, damage: float)

## Cách chọn mục tiêu khi có nhiều địch trong tầm.
enum TargetMode {
	FIRST, ## Địch đi xa nhất (gần nhà chính nhất).
	LAST, ## Địch đi sau cùng.
	CLOSEST, ## Địch gần tháp nhất.
	STRONGEST, ## Địch còn nhiều máu nhất.
}

const BASE_SIZE := 44.0
const BARREL_LENGTH := 24.0
const SHOT_VISUAL_TIME := 0.08
const AIM_SPEED := 15.0

@export var data: TowerData
@export var target_mode: TargetMode = TargetMode.FIRST

## Mục tiêu hiện tại (null nếu không có địch trong tầm).
var target: Enemy = null
## Bật để vẽ vòng tròn tầm bắn (khi người chơi chọn tháp).
var show_range := false:
	set(value):
		show_range = value
		queue_redraw()

var _cooldown := 0.0
var _aim_angle := -PI * 0.5
var _shot_timer := 0.0
var _last_shot_position := Vector2.ZERO


func _ready() -> void:
	assert(data != null, "Tower cần TowerData: hãy gán data trước khi add_child().")


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_shot_timer = maxf(_shot_timer - delta, 0.0)

	# Chọn lại mục tiêu mỗi frame để luôn theo đúng TargetMode.
	target = _find_target()
	if target:
		var desired_angle := global_position.direction_to(target.global_position).angle()
		_aim_angle = lerp_angle(_aim_angle, desired_angle, minf(1.0, delta * AIM_SPEED))
		if _cooldown <= 0.0:
			_shoot(target)

	queue_redraw()


func is_in_range(enemy: Enemy) -> bool:
	return global_position.distance_squared_to(enemy.global_position) <= data.attack_range * data.attack_range


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_score := -INF
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_alive() or not is_in_range(enemy):
			continue
		var score := _score_target(enemy)
		if score > best_score:
			best_score = score
			best = enemy
	return best


## Điểm càng cao càng được ưu tiên.
func _score_target(enemy: Enemy) -> float:
	match target_mode:
		TargetMode.LAST:
			return -enemy.progress
		TargetMode.CLOSEST:
			return -global_position.distance_squared_to(enemy.global_position)
		TargetMode.STRONGEST:
			return enemy.health
		_:
			return enemy.progress # FIRST


func _shoot(enemy: Enemy) -> void:
	_cooldown = 1.0 / data.fire_rate
	_shot_timer = SHOT_VISUAL_TIME
	_last_shot_position = enemy.global_position
	fired.emit(enemy, data.damage)
	enemy.take_damage(data.damage)


# --- Hiển thị tạm (chưa có sprite) ---------------------------------------------

func _draw() -> void:
	if show_range:
		draw_circle(Vector2.ZERO, data.attack_range, Color(data.color, 0.08))
		draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, Color(data.color, 0.6), 2.0)

	# Đế tháp + thân + nòng súng.
	var half := BASE_SIZE * 0.5
	draw_rect(Rect2(-half, -half, BASE_SIZE, BASE_SIZE), Color(0.25, 0.27, 0.32))
	draw_rect(Rect2(-half, -half, BASE_SIZE, BASE_SIZE), Color(0.1, 0.1, 0.12), false, 2.0)
	draw_circle(Vector2.ZERO, 14.0, data.color)
	var barrel_tip := Vector2.from_angle(_aim_angle) * BARREL_LENGTH
	draw_line(Vector2.ZERO, barrel_tip, data.color.darkened(0.3), 7.0)

	# Tia bắn tức thời.
	if _shot_timer > 0.0:
		var alpha := _shot_timer / SHOT_VISUAL_TIME
		draw_line(barrel_tip, to_local(_last_shot_position), Color(1.0, 0.95, 0.5, alpha), 3.0)
