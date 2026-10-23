class_name Tower
extends Node2D
## Tháp: tự chọn mục tiêu trong tầm rồi tấn công theo TowerData.
## Nâng cấp = đổi sang TowerData của cấp sau (data.get_upgrade(nhánh)); cấp 3 rẽ 2 nhánh.
##
## - HITSCAN: trúng ngay, vẽ một tia sáng ngắn.
## - PROJECTILE: bắn ra một Projectile bay đuổi theo mục tiêu.
## - PULSE: sóng toả quanh tháp, trúng mọi địch trong tầm.
## Mọi kiểu đều dùng Combat.apply_hit() nên nổ lan / hiệu ứng hoạt động giống nhau.
##
## Tháp không bắn: Cờ hiệu (buff sát thương tháp xung quanh) và Mỏ vàng (vàng mỗi wave).
## Buff của Cờ hiệu được cache trong _damage_multiplier; BuildManager gọi refresh_buff()
## khi có tháp được xây / nâng cấp / bán.

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
	WEAKEST, ## Địch còn ít máu nhất (dọn địch sắp chết).
}

const DEFAULT_PROJECTILE := preload("res://scenes/projectiles/Projectile.tscn")
const BASE_SIZE := 44.0
const BARREL_LENGTH := 24.0
const SHOT_VISUAL_TIME := 0.08
const AIM_SPEED := 15.0
const UPGRADE_FX_TIME := 0.5
## Nhóm chứa mọi tháp đang đứng trên bản đồ (Cờ hiệu dò tháp xung quanh qua nhóm này).
const GROUP := &"towers"

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
## Skin đang dùng (ItemDef, chỉ đổi ngoại hình). null = màu mặc định của TowerData.
var skin: ItemDef = null:
	set(value):
		skin = value
		queue_redraw()
## "Hoàn tác": số vàng đã tiêu cho tháp này kể từ khi wave hiện tại bắt đầu (recent_spend)
## và wave đó (recent_wave). Phần này bán được hoàn 100%; phần tiêu từ trước hoàn theo sell_ratio.
## Nhờ vậy xây nhầm có thể bán lại nguyên giá, nhưng nâng cấp muộn không "rửa" được tiền cũ.
var recent_spend: int = 0
var recent_wave: int = -1
## Hệ số tầm bắn của ô đang đứng (ô đồi > 1). Mọi chỗ đọc tầm bắn dùng get_range().
var range_multiplier := 1.0
## Thống kê hiển thị trong bảng thông tin.
var kills: int = 0
var damage_dealt: float = 0.0

var _cooldown := 0.0
var _aim_angle := -PI * 0.5
var _shot_timer := 0.0
var _last_shot_position := Vector2.ZERO
var _upgrade_fx := 0.0
## Hệ số sát thương nhờ Cờ hiệu (1 = không được buff).
var _damage_multiplier := 1.0


func _ready() -> void:
	assert(data != null, "Tower cần TowerData: hãy gán data trước khi add_child().")
	add_to_group(GROUP)
	if total_invested == 0:
		total_invested = data.cost
	if recent_wave < 0:
		record_spend(total_invested)


func get_level() -> int:
	return data.level


func can_upgrade() -> bool:
	return data.can_upgrade()


## Giá nâng cấp theo nhánh `branch` (0 nếu đã tối đa).
func get_upgrade_cost(branch: int = 0) -> int:
	var next := data.get_upgrade(branch)
	return next.cost if next else 0


## Tầm bắn thực tế (đã tính ô đồi). Cờ hiệu: bán kính hào quang.
func get_range() -> float:
	return data.attack_range * range_multiplier


## Ghi nhận vàng vừa tiêu cho tháp (xây / nâng cấp).
func record_spend(amount: int) -> void:
	if recent_wave != GameManager.current_wave:
		recent_wave = GameManager.current_wave
		recent_spend = 0
	recent_spend += amount


## Phần vàng tiêu trong wave hiện tại (được hoàn 100%).
func get_recent_spend() -> int:
	return recent_spend if recent_wave == GameManager.current_wave else 0


## true nếu toàn bộ tiền của tháp đều tiêu trong wave hiện tại (bán = hoàn tác hoàn toàn).
func is_refundable_in_full() -> bool:
	return get_recent_spend() >= total_invested


## Số vàng nhận lại nếu bán tháp lúc này.
func get_sell_value() -> int:
	var recent := get_recent_spend()
	return recent + int((total_invested - recent) * data.get_sell_ratio())


## Đổi sang bộ chỉ số cấp sau (nhánh `branch` nếu có). Việc trừ vàng do BuildManager lo.
func upgrade(branch: int = 0) -> void:
	var next := data.get_upgrade(branch)
	if next == null:
		return
	data = next
	total_invested += data.cost
	record_spend(data.cost)
	if data.preferred_target_mode >= 0:
		target_mode = data.preferred_target_mode as TargetMode
	_upgrade_fx = UPGRADE_FX_TIME
	upgraded.emit(self)
	queue_redraw()


## Hệ số sát thương hiện tại (buff Cờ hiệu).
func get_damage_multiplier() -> float:
	return _damage_multiplier


## Tính lại buff: lấy Cờ hiệu MẠNH NHẤT có hào quang phủ tới tháp này (không cộng dồn).
func refresh_buff() -> void:
	var best := 0.0
	if data.is_attacker():
		for node in get_tree().get_nodes_in_group(GROUP):
			var banner := node as Tower
			if banner == null or banner == self or banner.is_queued_for_deletion() or banner.data.aura_radius <= 0.0:
				continue
			var radius := banner.data.aura_radius * banner.range_multiplier
			if banner.global_position.distance_squared_to(global_position) <= radius * radius:
				best = maxf(best, banner.data.aura_damage_bonus)
	if not is_equal_approx(_damage_multiplier, 1.0 + best):
		_damage_multiplier = 1.0 + best
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

	if not data.is_attacker():
		target = null
		if _upgrade_fx > 0.0:
			queue_redraw()
		return

	# Chọn lại mục tiêu mỗi frame để luôn theo đúng TargetMode.
	target = _find_target()
	if target:
		var desired_angle := global_position.direction_to(target.global_position).angle()
		_aim_angle = lerp_angle(_aim_angle, desired_angle, minf(1.0, delta * AIM_SPEED))
		if _cooldown <= 0.0:
			_shoot(target)

	queue_redraw()


func is_in_range(enemy: Enemy) -> bool:
	var reach := get_range()
	return global_position.distance_squared_to(enemy.global_position) <= reach * reach


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


## Điểm càng cao càng được ưu tiên. "Đầu đoàn" / "Cuối đoàn" tính theo quãng đường CÒN LẠI
## tới nhà chính, nên đúng cả trên bản đồ có nhiều làn dài ngắn khác nhau.
## Mạnh nhất / Yếu nhất: hoà máu thì ưu tiên con gần nhà chính hơn.
func _score_target(enemy: Enemy) -> float:
	match target_mode:
		TargetMode.LAST:
			return enemy.remaining_distance()
		TargetMode.CLOSEST:
			return -global_position.distance_squared_to(enemy.global_position)
		TargetMode.STRONGEST:
			return enemy.health * 10000.0 - enemy.remaining_distance()
		TargetMode.WEAKEST:
			return -enemy.health * 10000.0 - enemy.remaining_distance()
		_:
			return -enemy.remaining_distance() # FIRST


func _shoot(enemy: Enemy) -> void:
	_cooldown = 1.0 / data.fire_rate
	var damage := data.damage * _damage_multiplier
	var info := DamageInfo.new(damage, data.damage_type, self)
	info.effects = data.on_hit_effects
	info.hits_air = data.can_hit_air
	info.armor_pen = data.armor_pen
	fired.emit(enemy, damage)

	match data.attack_type:
		TowerData.AttackType.PROJECTILE:
			_spawn_projectile(enemy, info)
		TowerData.AttackType.PULSE:
			_shot_timer = SHOT_VISUAL_TIME * 3.0
			Combat.apply_hit(null, global_position, info, get_range(), get_tree())
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
		tint: Color = Color(0, 0, 0, 0), alpha: float = 1.0, tower_skin: ItemDef = null) -> void:
	var paint := func(color: Color) -> Color:
		var mixed := color.lerp(Color(tint, 1.0), tint.a)
		return Color(mixed, color.a * alpha)
	var body_color := tower_skin.skin_color if tower_skin else tower_data.color
	var accent := tower_skin.skin_accent if tower_skin else tower_data.color.darkened(0.3)
	var body_radius := 12.0 + tower_data.level * 2.0
	var half := BASE_SIZE * 0.5
	if tower_skin and tower_skin.pattern == ItemDef.Pattern.GLOW:
		canvas.draw_circle(Vector2.ZERO, half + 4.0, paint.call(Color(body_color, 0.25)))
	canvas.draw_rect(Rect2(-half, -half, BASE_SIZE, BASE_SIZE), paint.call(Color(0.25, 0.27, 0.32)))
	canvas.draw_rect(Rect2(-half, -half, BASE_SIZE, BASE_SIZE), paint.call(Color(0.1, 0.1, 0.12)), false, 2.0)
	if tower_skin and tower_skin.pattern == ItemDef.Pattern.STRIPES:
		for x in [-half + 5.0, half - 9.0]:
			canvas.draw_rect(Rect2(x, -half + 3.0, 4.0, BASE_SIZE - 6.0), paint.call(accent))
	canvas.draw_circle(Vector2.ZERO, body_radius, paint.call(body_color))
	if tower_skin:
		match tower_skin.pattern:
			ItemDef.Pattern.RING, ItemDef.Pattern.GLOW:
				canvas.draw_arc(Vector2.ZERO, body_radius - 2.0, 0.0, TAU, 32, paint.call(accent), 3.0, true)
			ItemDef.Pattern.STAR:
				var star := PackedVector2Array()
				for i in 10:
					var r := body_radius * (0.55 if i % 2 == 0 else 0.25)
					star.append(Vector2.from_angle(-PI * 0.5 + i * PI / 5.0) * r)
				canvas.draw_colored_polygon(star, paint.call(accent))
	# Chấm vàng thể hiện cấp.
	for i in tower_data.level:
		var pip := Vector2((i - (tower_data.level - 1) * 0.5) * 9.0, half - 6.0)
		canvas.draw_circle(pip, 3.0, paint.call(Color(1.0, 0.85, 0.3)))
	if tower_data.aura_radius > 0.0:
		# Cờ hiệu: cột cờ + lá cờ tam giác thay cho nòng súng.
		canvas.draw_line(Vector2(-4, 8), Vector2(-4, -26), paint.call(Color(0.85, 0.85, 0.9)), 3.0)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-3, -26), Vector2(16, -20), Vector2(-3, -13)]),
				paint.call(accent.lightened(0.2)))
		return
	if tower_data.gold_per_wave > 0:
		# Mỏ vàng: vài cục vàng trên miệng mỏ, không có nòng.
		for nugget in [Vector2(-6, -3), Vector2(5, -5), Vector2(0, 5)]:
			canvas.draw_circle(nugget, 5.0, paint.call(Color(1.0, 0.82, 0.25)))
			canvas.draw_arc(nugget, 5.0, 0.0, TAU, 12, paint.call(Color(0.6, 0.45, 0.1)), 1.5)
		return
	var barrel_tip := Vector2.from_angle(aim_angle) * BARREL_LENGTH
	var barrel_width := 11.0 if tower_data.splash_radius > 0.0 else 7.0
	if tower_data.attack_type == TowerData.AttackType.PULSE:
		canvas.draw_arc(Vector2.ZERO, body_radius + 4.0, 0.0, TAU, 24, paint.call(accent), 3.0)
		return
	canvas.draw_line(Vector2.ZERO, barrel_tip, paint.call(accent), barrel_width)


func _draw() -> void:
	var half := BASE_SIZE * 0.5
	# Đang được chọn: viền trắng quanh đế. Vòng tầm bắn do RangeIndicator vẽ (TowerRangeDisplay).
	if show_range:
		draw_rect(Rect2(-half - 4.0, -half - 4.0, BASE_SIZE + 8.0, BASE_SIZE + 8.0), Color(1, 1, 1, 0.9), false, 2.0)

	draw_body(self, data, _aim_angle, Color(0, 0, 0, 0), 1.0, skin)
	var barrel_tip := Vector2.from_angle(_aim_angle) * BARREL_LENGTH

	# Được Cờ hiệu buff: mũi tên vàng nhỏ ở góc trên phải.
	if _damage_multiplier > 1.0:
		var corner := Vector2(half - 7.0, -half + 7.0)
		draw_colored_polygon(PackedVector2Array([corner + Vector2(-6, 3), corner + Vector2(0, -4), corner + Vector2(6, 3)]),
				Color(1.0, 0.85, 0.3))

	# Sóng toả (PULSE): vòng lan ra tới mép tầm bắn.
	if _shot_timer > 0.0 and data.attack_type == TowerData.AttackType.PULSE:
		var t := 1.0 - _shot_timer / (SHOT_VISUAL_TIME * 3.0)
		draw_arc(Vector2.ZERO, get_range() * t, 0.0, TAU, 48, Color(data.color.lightened(0.4), 1.0 - t), 3.0)
	# Tia bắn tức thời (chỉ với HITSCAN).
	elif _shot_timer > 0.0:
		var alpha := _shot_timer / SHOT_VISUAL_TIME
		var beam_end := to_local(_last_shot_position)
		draw_line(barrel_tip, beam_end, Color(data.color.lightened(0.5), alpha), 3.0)
		if data.splash_radius > 0.0:
			draw_arc(beam_end, data.splash_radius, 0.0, TAU, 24, Color(data.color, alpha * 0.8), 2.0)

	# Vòng sáng lan ra khi vừa nâng cấp.
	if _upgrade_fx > 0.0:
		var t := 1.0 - _upgrade_fx / UPGRADE_FX_TIME
		draw_arc(Vector2.ZERO, half + t * 30.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 1.0 - t), 3.0)
