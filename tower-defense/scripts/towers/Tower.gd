class_name Tower
extends Node2D
## Tháp: tự chọn mục tiêu trong tầm rồi tấn công theo TowerData.
##
## - HITSCAN: trúng ngay, vẽ một tia sáng ngắn.
## - PROJECTILE: bắn ra một Projectile bay đuổi theo mục tiêu.
## Cả hai kiểu đều dùng Combat.apply_hit() nên nổ lan / hiệu ứng hoạt động giống nhau.

## Phát ra mỗi lần bắn.
signal fired(target: Enemy, damage: float)

## Cách chọn mục tiêu khi có nhiều địch trong tầm.
enum TargetMode {
	FIRST, ## Địch đi xa nhất (gần nhà chính nhất).
	LAST, ## Địch đi sau cùng.
	CLOSEST, ## Địch gần tháp nhất.
	STRONGEST, ## Địch còn nhiều máu nhất.
}

const DEFAULT_PROJECTILE := preload("res://scenes/projectiles/Projectile.tscn")
const BASE_SIZE := 44.0
const BARREL_LENGTH := 24.0
const SHOT_VISUAL_TIME := 0.08
const AIM_SPEED := 15.0

@export var data: TowerData
@export var target_mode: TargetMode = TargetMode.FIRST

## Mục tiêu hiện tại (null nếu không có địch trong tầm).
var target: Enemy = null
## Node chứa đạn bắn ra (BuildManager gán). Để trống thì dùng node cha của tháp.
var projectile_container: Node = null
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
	var info := DamageInfo.new(data.damage, data.damage_type, self)
	info.effects = data.on_hit_effects
	fired.emit(enemy, data.damage)

	match data.attack_type:
		TowerData.AttackType.PROJECTILE:
			_spawn_projectile(enemy, info)
		_:
			_shot_timer = SHOT_VISUAL_TIME
			_last_shot_position = enemy.global_position
			Combat.apply_hit(enemy, enemy.global_position, info, data.splash_radius, get_tree())


func _spawn_projectile(enemy: Enemy, info: DamageInfo) -> void:
	var scene := data.projectile_scene if data.projectile_scene else DEFAULT_PROJECTILE
	var projectile := scene.instantiate() as Projectile
	projectile.setup(enemy, info, data.projectile_speed, data.splash_radius, data.color.lightened(0.3))
	var container := projectile_container if projectile_container else get_parent()
	container.add_child(projectile)
	projectile.global_position = global_position + Vector2.from_angle(_aim_angle) * BARREL_LENGTH


# --- Hiển thị tạm (chưa có sprite) ---------------------------------------------

func _draw() -> void:
	if show_range:
		draw_circle(Vector2.ZERO, data.attack_range, Color(data.color, 0.08))
		draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 64, Color(data.color, 0.6), 2.0)

	# Đế tháp + thân + nòng súng (nòng to hơn với tháp nổ lan).
	var half := BASE_SIZE * 0.5
	draw_rect(Rect2(-half, -half, BASE_SIZE, BASE_SIZE), Color(0.25, 0.27, 0.32))
	draw_rect(Rect2(-half, -half, BASE_SIZE, BASE_SIZE), Color(0.1, 0.1, 0.12), false, 2.0)
	draw_circle(Vector2.ZERO, 14.0, data.color)
	var barrel_tip := Vector2.from_angle(_aim_angle) * BARREL_LENGTH
	var barrel_width := 11.0 if data.splash_radius > 0.0 else 7.0
	draw_line(Vector2.ZERO, barrel_tip, data.color.darkened(0.3), barrel_width)

	# Tia bắn tức thời (chỉ với HITSCAN).
	if _shot_timer > 0.0:
		var alpha := _shot_timer / SHOT_VISUAL_TIME
		var beam_end := to_local(_last_shot_position)
		draw_line(barrel_tip, beam_end, Color(data.color.lightened(0.5), alpha), 3.0)
		if data.splash_radius > 0.0:
			draw_arc(beam_end, data.splash_radius, 0.0, TAU, 24, Color(data.color, alpha * 0.8), 2.0)
