class_name Enemy
extends PathFollow2D
## Địch cơ bản: chạy dọc theo Path2D cha.
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

## Tên group để tháp tìm mục tiêu.
const GROUP := &"enemies"
const HEALTH_BAR_SIZE := Vector2(34, 5)
const HIT_FLASH_TIME := 0.1

@export var data: EnemyData

var max_health: float = 0.0
var health: float = 0.0
var speed: float = 0.0

var _is_dead := false
var _path_length := 0.0
var _hit_flash := 0.0


## Gán dữ liệu trước khi add_child(). Hệ số nhân cho phép wave sau mạnh hơn.
func setup(enemy_data: EnemyData, health_multiplier: float = 1.0, speed_multiplier: float = 1.0) -> void:
	data = enemy_data
	max_health = data.max_health * health_multiplier
	health = max_health
	speed = data.speed * speed_multiplier


func _ready() -> void:
	assert(data != null, "Enemy cần EnemyData: hãy gọi setup() trước khi add_child().")
	if max_health <= 0.0:
		setup(data) # Trường hợp đặt địch thẳng vào scene trong editor.
	loop = false
	rotates = false
	add_to_group(GROUP)

	var path := get_parent() as Path2D
	assert(path != null and path.curve != null, "Enemy phải là con trực tiếp của một Path2D có Curve2D.")
	_path_length = path.curve.get_baked_length()


func _process(delta: float) -> void:
	if _is_dead:
		return

	progress += speed * delta
	if progress >= _path_length - 0.01:
		_reach_end()
		return

	if _hit_flash > 0.0:
		_hit_flash = maxf(_hit_flash - delta, 0.0)
		queue_redraw()


## Còn sống và còn trong scene (queue_free chỉ xoá vào cuối frame).
func is_alive() -> bool:
	return not _is_dead and is_inside_tree()


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	health = maxf(health - amount, 0.0)
	_hit_flash = HIT_FLASH_TIME
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0.0:
		_die()


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
	var body_color := data.color.lerp(Color.WHITE, _hit_flash / HIT_FLASH_TIME)
	draw_circle(Vector2.ZERO, data.radius, body_color)
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 32, data.color.darkened(0.5), 2.0)

	# Thanh máu (chỉ hiện khi đã bị bắn).
	if health < max_health:
		var bar_pos := Vector2(-HEALTH_BAR_SIZE.x * 0.5, -data.radius - 10.0)
		var ratio := health / max_health
		draw_rect(Rect2(bar_pos, HEALTH_BAR_SIZE), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bar_pos, Vector2(HEALTH_BAR_SIZE.x * ratio, HEALTH_BAR_SIZE.y)),
				Color.RED.lerp(Color.GREEN, ratio))
