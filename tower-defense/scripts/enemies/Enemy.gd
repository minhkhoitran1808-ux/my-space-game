class_name Enemy
extends PathFollow2D
## Địch: chạy dọc theo Path2D cha, nhận sát thương có tính kháng, dính hiệu ứng.
##
## PathFollow2D bắt buộc phải là con TRỰC TIẾP của Path2D, vì vậy WaveManager
## spawn địch vào các làn (Path2D) của bản đồ. Mọi chỉ số đọc từ EnemyData.
## Địch không tự cộng vàng / trừ máu nhà chính mà chỉ phát signal,
## WaveManager sẽ lắng nghe và báo cho GameManager.

## Phát ra khi địch bị tiêu diệt.
signal died(enemy: Enemy, reward: int)
## Phát ra khi địch đi tới cuối đường (chạm nhà chính).
signal reached_end(enemy: Enemy, damage: int)
## Phát ra mỗi khi máu thay đổi.
signal health_changed(current: float, maximum: float)
## Phát ra mỗi lần trúng đòn, với lượng sát thương THỰC (sau kháng).
signal damaged(enemy: Enemy, amount: float, info: DamageInfo)
## Phát ra khi được hồi máu (vd bởi Thầy lang), với lượng máu THỰC được hồi.
signal healed(enemy: Enemy, amount: float)

## Tên group để tháp tìm mục tiêu.
const GROUP := &"enemies"

@export var data: EnemyData

var max_health: float = 0.0
var health: float = 0.0
## Tốc độ gốc (chưa tính làm chậm).
var base_speed: float = 0.0
## Hệ số máu của wave, để địch con sinh ra khi chết cũng mạnh tương ứng.
var health_multiplier: float = 1.0
## Node gây đòn cuối cùng (dùng cho thống kê của tháp).
var last_damage_source: Node = null
## Địch thuộc wave nào (WaveManager gán, dùng để biết khi nào từng wave kết thúc).
var wave_index: int = -1

var _is_dead := false
var _path_length := 0.0
## Đồng hồ cho hoạt ảnh vỗ cánh / nhấp nhô của địch bay.
var _flight_time := 0.0

@onready var status_effects: StatusEffectHandler = $StatusEffects
## Thanh máu trên đầu (node riêng: không xoay, không bị nén theo thân).
@onready var health_bar: HealthBar = $HealthBar
## Nháy trắng + giật khi trúng đòn.
@onready var hit_feedback: HitFeedback = $HitFeedback


## Gán dữ liệu trước khi add_child(). Hệ số nhân cho phép wave sau mạnh hơn.
func setup(enemy_data: EnemyData, p_health_multiplier: float = 1.0, speed_multiplier: float = 1.0) -> void:
	data = enemy_data
	health_multiplier = p_health_multiplier
	max_health = data.max_health * p_health_multiplier
	health = max_health
	base_speed = data.speed * speed_multiplier


func _ready() -> void:
	assert(data != null, "Enemy cần EnemyData: hãy gọi setup() trước khi add_child().")
	if max_health <= 0.0:
		setup(data) # Trường hợp đặt địch thẳng vào scene trong editor.
	loop = false
	rotates = false
	add_to_group(GROUP)
	status_effects.effects_changed.connect(queue_redraw)
	# Hai component tự nghe signal health_changed / damaged của địch.
	health_bar.track(self)
	hit_feedback.track(self)
	hit_feedback.changed.connect(queue_redraw)
	if data.heal_radius > 0.0:
		var aura := HealerAura.new()
		aura.name = "HealerAura"
		add_child(aura)
		aura.setup(self)

	var path := get_parent() as Path2D
	assert(path != null and path.curve != null, "Enemy phải là con trực tiếp của một Path2D có Curve2D.")
	_path_length = path.curve.get_baked_length()


func _process(delta: float) -> void:
	if _is_dead:
		return

	progress += get_current_speed() * delta
	if progress >= _path_length - 0.01:
		_reach_end()
		return

	if data.is_flying:
		_flight_time += delta
		queue_redraw()


## Tốc độ thực tế (đã tính làm chậm).
func get_current_speed() -> float:
	return base_speed * status_effects.get_speed_multiplier()


## Quãng đường còn lại tới nhà chính (pixel). Dùng để nhắm "Đầu đoàn" đúng cả khi các làn
## dài ngắn khác nhau.
func remaining_distance() -> float:
	return maxf(_path_length - progress, 0.0)


## Còn sống và còn trong scene (queue_free chỉ xoá vào cuối frame).
func is_alive() -> bool:
	return not _is_dead and is_inside_tree()


## Nhận một đòn đánh. Trả về lượng sát thương thực sự gây ra (sau kháng).
func take_damage(info: DamageInfo) -> float:
	if _is_dead:
		return 0.0

	# Sau kháng mỗi đòn vẫn gây ít nhất 1 sát thương (giáp cao không làm đòn yếu "vô dụng" hẳn).
	# Không tính phần sát thương "thừa" vượt quá máu còn lại.
	var raw := info.amount * (1.0 - data.get_resistance(info.type, info.armor_pen))
	var amount := minf(maxf(raw, minf(1.0, info.amount)), health)
	health -= amount
	last_damage_source = info.source
	# Báo cho nguồn gây sát thương (thường là Tower) để cộng thống kê.
	if is_instance_valid(info.source) and info.source.has_method(&"record_damage"):
		info.source.record_damage(amount, health <= 0.0)
	for effect in info.effects:
		status_effects.apply(effect, info.source)

	health_changed.emit(health, max_health)
	damaged.emit(self, amount, info)
	if health <= 0.0:
		_die()
	return amount


## Hồi máu (không vượt quá máu tối đa). Trả về lượng máu thực sự được hồi.
func heal(amount: float) -> float:
	if _is_dead or amount <= 0.0:
		return 0.0
	var gained := minf(amount, max_health - health)
	if gained <= 0.0:
		return 0.0
	health += gained
	health_changed.emit(health, max_health)
	healed.emit(self, gained)
	return gained


func _die() -> void:
	_is_dead = true
	died.emit(self, data.reward)
	queue_free()


func _reach_end() -> void:
	_is_dead = true
	reached_end.emit(self, data.damage_to_base)
	queue_free()


# --- Hiển thị tạm (chưa có sprite) ---------------------------------------------
# Thanh máu là node con riêng (HealthBar), không vẽ ở đây.

func _draw() -> void:
	var r := data.radius
	# Nháy trắng khi trúng đòn: cả thân lẫn viền ngả về trắng.
	var flash := hit_feedback.flash_amount
	var body_color := data.color.lerp(Color.WHITE, flash)
	var outline := data.color.darkened(0.5).lerp(Color.WHITE, flash * 0.8)

	# Địch bay: bóng mờ dưới đất, thân vẽ cao hơn và nhấp nhô.
	var body_offset := Vector2.ZERO
	if data.is_flying:
		_draw_ellipse(Vector2(0, r * 0.9), Vector2(r * 1.1, r * 0.4), Color(0, 0, 0, 0.3))
		body_offset.y = -HealthBar.FLYING_LIFT + sin(_flight_time * 4.0) * 2.5
	# "Giật" khi trúng đòn: nén/giãn quanh chân thân (chân đứng yên, đầu lún xuống).
	var squash := hit_feedback.body_scale
	draw_set_transform(body_offset + Vector2(0.0, r * (1.0 - squash.y)), 0.0, squash)

	# Vòng sáng hiệu ứng (làm chậm = xanh, thiêu đốt = cam...).
	var ring := r + 4.0
	for tint in status_effects.get_tints():
		draw_arc(Vector2.ZERO, ring, 0.0, TAU, 24, tint, 3.0)
		ring += 4.0

	match data.shape:
		EnemyData.Shape.SQUARE:
			draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), body_color)
			draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), outline, false, 2.0)
		EnemyData.Shape.TRIANGLE:
			var tri := PackedVector2Array([Vector2(0, -r), Vector2(r, r * 0.8), Vector2(-r, r * 0.8)])
			draw_colored_polygon(tri, body_color)
			tri.append(tri[0])
			draw_polyline(tri, outline, 2.0)
		EnemyData.Shape.DIAMOND:
			var dia := PackedVector2Array([Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)])
			draw_colored_polygon(dia, body_color)
			dia.append(dia[0])
			draw_polyline(dia, outline, 2.0)
		EnemyData.Shape.BAT:
			# Hai cánh tam giác vỗ lên xuống quanh thân tròn nhỏ.
			var flap := sin(_flight_time * 14.0) * r * 0.5
			for side in [-1.0, 1.0]:
				var wing := PackedVector2Array([Vector2(side * r * 0.3, -r * 0.2),
						Vector2(side * r * 1.6, -r * 0.4 - flap), Vector2(side * r * 1.1, r * 0.5 - flap * 0.5)])
				draw_colored_polygon(wing, body_color.darkened(0.25))
			draw_circle(Vector2.ZERO, r * 0.6, body_color)
			draw_arc(Vector2.ZERO, r * 0.6, 0.0, TAU, 24, outline, 2.0)
		EnemyData.Shape.CROSS:
			# Thầy lang: thân tròn có dấu cộng trắng.
			draw_circle(Vector2.ZERO, r, body_color)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, outline, 2.0)
			var arm := r * 0.55
			var thick := maxf(r * 0.32, 3.0)
			var cross_color := Color.WHITE.lerp(body_color, 0.15)
			draw_rect(Rect2(-arm, -thick * 0.5, arm * 2.0, thick), cross_color)
			draw_rect(Rect2(-thick * 0.5, -arm, thick, arm * 2.0), cross_color)
		_:
			draw_circle(Vector2.ZERO, r, body_color)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, outline, 2.0)

	draw_set_transform(Vector2.ZERO)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
