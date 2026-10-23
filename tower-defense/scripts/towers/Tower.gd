class_name Tower
extends Node2D
## Tháp: tự chọn mục tiêu trong tầm rồi tấn công theo TowerData.
## Nâng cấp = đổi sang TowerData cấp tiếp theo (data.next_level).
##
## - HITSCAN: trúng ngay, vẽ một tia sáng ngắn.
## - PROJECTILE: bắn ra một Projectile bay đuổi theo mục tiêu.
## Cả hai kiểu đều dùng Combat.apply_hit() nên nổ lan / hiệu ứng hoạt động giống nhau.

## Phát ra mỗi lần bắn.
signal fired(target: Enemy, damage: float)
## Phát ra sau khi nâng cấp thành công.
signal upgraded(tower: Tower)
## Phát ra khi thống kê (sát thương, số địch hạ) thay đổi.
signal stats_changed(tower: Tower)

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
const UPGRADE_FX_TIME := 0.5

@export var data: TowerData
@export var target_mode: TargetMode = TargetMode.FIRST

## Mục tiêu hiện tại (null nếu không có địch trong tầm).
var target: Enemy = null
## Node chứa đạn bắn ra (BuildManager gán). Để trống thì dùng node cha của tháp.
var projectile_container: Node = null
## Bật để vẽ vòng tròn tầm bắn + viền chọn (khi người chơi chọn tháp).
var show_range := false:
	set(value):
		show_range = value
		queue_redraw()
## Tổng số vàng đã bỏ ra (xây + nâng cấp), dùng để tính tiền bán lại.
var total_invested: int = 0
## Thống kê hiển thị trong bảng thông tin.
var kills: int = 0
var damage_dealt: float = 0.0

var _cooldown := 0.0
var _aim_angle := -PI * 0.5
var _shot_timer := 0.0
var _last_shot_position := Vector2.ZERO
var _upgrade_fx := 0.0


func _ready() -> void:
	assert(data != null, "Tower cần TowerData: hãy gán data trước khi add_child().")
	if total_invested == 0:
		total_invested = data.cost


func get_level() -> int:
	return data.level


func can_upgrade() -> bool:
	return data.can_upgrade()


## Giá nâng cấp lên cấp tiếp theo (0 nếu đã tối đa).
func get_upgrade_cost() -> int:
	return data.next_level.cost if data.can_upgrade() else 0


## Số vàng nhận lại nếu bán tháp lúc này.
func get_sell_value() -> int:
	return int(total_invested * GameConfig.SELL_REFUND_RATIO)


## Đổi sang bộ chỉ số cấp tiếp theo. Việc trừ vàng do BuildManager lo.
func upgrade() -> void:
	if not data.can_upgrade():
		return
	data = data.next_level
	total_invested += data.cost
	_upgrade_fx = UPGRADE_FX_TIME
	upgraded.emit(self)
	queue_redraw()


## Enemy gọi hàm này (qua DamageInfo.source) mỗi khi tháp gây sát thương.
func record_damage(amount: float, killed: bool) -> void:
	damage_dealt += amount
	if killed:
		kills += 1
	stats_changed.emit(self)


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_shot_timer = maxf(_shot_timer - delta, 0.0)
	_upgrade_fx = maxf(_upgrade_fx - delta, 0.0)

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
		if enemy.data.is_flying and not data.can_hit_air:
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
	info.hits_air = data.can_hit_air
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

## Vẽ thân tháp (đế + thân + chấm cấp + nòng) lên một CanvasItem bất kỳ.
## Dùng chung cho tháp thật và ghost khi đặt tháp, nên ghost luôn trông giống hệt tháp sẽ xây.
## tint: màu pha vào mọi phần (tint.a = mức pha, 0 = không pha); alpha: độ trong suốt.
static func draw_body(canvas: CanvasItem, tower_data: TowerData, aim_angle: float,
		tint: Color = Color(0, 0, 0, 0), alpha: float = 1.0) -> void:
	var paint := func(color: Color) -> Color:
		var mixed := color.lerp(Color(tint, 1.0), tint.a)
		return Color(mixed, color.a * alpha)
	var half := BASE_SIZE * 0.5
	canvas.draw_rect(Rect2(-half, -half, BASE_SIZE, BASE_SIZE), paint.call(Color(0.25, 0.27, 0.32)))
	canvas.draw_rect(Rect2(-half, -half, BASE_SIZE, BASE_SIZE), paint.call(Color(0.1, 0.1, 0.12)), false, 2.0)
	canvas.draw_circle(Vector2.ZERO, 12.0 + tower_data.level * 2.0, paint.call(tower_data.color))
	# Chấm vàng thể hiện cấp.
	for i in tower_data.level:
		var pip := Vector2((i - (tower_data.level - 1) * 0.5) * 9.0, half - 6.0)
		canvas.draw_circle(pip, 3.0, paint.call(Color(1.0, 0.85, 0.3)))
	var barrel_tip := Vector2.from_angle(aim_angle) * BARREL_LENGTH
	var barrel_width := 11.0 if tower_data.splash_radius > 0.0 else 7.0
	canvas.draw_line(Vector2.ZERO, barrel_tip, paint.call(tower_data.color.darkened(0.3)), barrel_width)


func _draw() -> void:
	var half := BASE_SIZE * 0.5
	# Đang được chọn: viền trắng quanh đế. Vòng tầm bắn do RangeIndicator vẽ (TowerRangeDisplay).
	if show_range:
		draw_rect(Rect2(-half - 4.0, -half - 4.0, BASE_SIZE + 8.0, BASE_SIZE + 8.0), Color(1, 1, 1, 0.9), false, 2.0)

	draw_body(self, data, _aim_angle)
	var barrel_tip := Vector2.from_angle(_aim_angle) * BARREL_LENGTH

	# Tia bắn tức thời (chỉ với HITSCAN).
	if _shot_timer > 0.0:
		var alpha := _shot_timer / SHOT_VISUAL_TIME
		var beam_end := to_local(_last_shot_position)
		draw_line(barrel_tip, beam_end, Color(data.color.lightened(0.5), alpha), 3.0)
		if data.splash_radius > 0.0:
			draw_arc(beam_end, data.splash_radius, 0.0, TAU, 24, Color(data.color, alpha * 0.8), 2.0)

	# Vòng sáng lan ra khi vừa nâng cấp.
	if _upgrade_fx > 0.0:
		var t := 1.0 - _upgrade_fx / UPGRADE_FX_TIME
		draw_arc(Vector2.ZERO, half + t * 30.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 1.0 - t), 3.0)
