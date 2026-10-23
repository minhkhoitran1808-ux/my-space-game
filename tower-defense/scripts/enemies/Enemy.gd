class_name Enemy
extends PathFollow2D
## Địch: chạy dọc theo Path2D cha, nhận sát thương có tính kháng, dính hiệu ứng.
##
## PathFollow2D bắt buộc phải là con TRỰC TIẾP của Path2D, vì vậy WaveManager
## spawn địch vào node Enemies/EnemyPath. Mọi chỉ số đọc từ EnemyData.
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

## Tên group để tháp tìm mục tiêu.
const GROUP := &"enemies"
const HEALTH_BAR_HEIGHT := 5.0
const HIT_FLASH_TIME := 0.1

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
var _hit_flash := 0.0

@onready var status_effects: StatusEffectHandler = $StatusEffects


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

	if _hit_flash > 0.0:
		_hit_flash = maxf(_hit_flash - delta, 0.0)
		queue_redraw()


## Tốc độ thực tế (đã tính làm chậm).
func get_current_speed() -> float:
	return base_speed * status_effects.get_speed_multiplier()


## Còn sống và còn trong scene (queue_free chỉ xoá vào cuối frame).
func is_alive() -> bool:
	return not _is_dead and is_inside_tree()


## Nhận một đòn đánh. Trả về lượng sát thương thực sự gây ra (sau kháng).
func take_damage(info: DamageInfo) -> float:
	if _is_dead:
		return 0.0

	# Không tính phần sát thương "thừa" vượt quá máu còn lại.
	var amount := minf(info.amount * (1.0 - data.get_resistance(info.type)), health)
	health -= amount
	last_damage_source = info.source
	# Báo cho nguồn gây sát thương (thường là Tower) để cộng thống kê.
	if is_instance_valid(info.source) and info.source.has_method(&"record_damage"):
		info.source.record_damage(amount, health <= 0.0)
	_hit_flash = HIT_FLASH_TIME
	for effect in info.effects:
		status_effects.apply(effect, info.source)

	health_changed.emit(health, max_health)
	damaged.emit(self, amount, info)
	queue_redraw()
	if health <= 0.0:
		_die()
	return amount


func _die() -> void:
	_is_dead = true
	died.emit(self, data.reward)
	queue_free()


func _reach_end() -> void:
	_is_dead = true
	reached_end.emit(self, data.damage_to_base)
	queue_free()


# --- Hiển thị tạm (chưa có sprite) ---------------------------------------------

func _draw() -> void:
	var r := data.radius
	var body_color := data.color.lerp(Color.WHITE, _hit_flash / HIT_FLASH_TIME)
	var outline := data.color.darkened(0.5)

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
		_:
			draw_circle(Vector2.ZERO, r, body_color)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, outline, 2.0)

	# Thanh máu (chỉ hiện khi đã bị bắn).
	if health < max_health:
		var bar_size := Vector2(maxf(r * 2.4, 24.0), HEALTH_BAR_HEIGHT)
		var bar_pos := Vector2(-bar_size.x * 0.5, -r - 10.0)
		var ratio := health / max_health
		draw_rect(Rect2(bar_pos, bar_size), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bar_pos, Vector2(bar_size.x * ratio, bar_size.y)), Color.RED.lerp(Color.GREEN, ratio))
