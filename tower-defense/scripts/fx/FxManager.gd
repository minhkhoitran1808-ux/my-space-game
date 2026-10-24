class_name FxManager
extends Node2D
## Hiệu ứng phản hồi (hình ảnh + âm thanh) cho các sự kiện trong trận.
##
## - Số sát thương bay lên khi địch trúng đòn (màu theo loại sát thương).
## - Vài tia lửa nhỏ ở điểm trúng (màu theo loại sát thương, có trần toàn cục).
## - "+N" vàng và vụ nổ hạt nhỏ khi địch chết.
## - Vòng nổ khi đạn nổ lan chạm đất.
## - Rung màn hình khi địch chạm nhà chính.
##
## FxManager chỉ LẮNG NGHE signal sẵn có (Enemy.damaged/died/reached_end, Tower.fired,
## Projectile.impacted), không hệ thống nào phải gọi ngược vào nó. Mọi hiệu ứng được vẽ
## trong một lần _draw() thay vì tạo node riêng, nên rất nhẹ kể cả khi có hàng trăm địch.

## Bật/tắt số sát thương bay lên (đọc từ cài đặt người chơi khi vào trận).
@export var show_damage_numbers := true
## Bật/tắt rung màn hình (đọc từ cài đặt người chơi khi vào trận).
@export var screen_shake := true
@export var camera: Camera2D

const TEXT_LIFETIME := 0.8
const TEXT_RISE_SPEED := 40.0
const PARTICLE_LIFETIME := 0.45
const RING_LIFETIME := 0.3
const SHAKE_DECAY := 6.0
const MAX_FLOATING_TEXTS := 120
## Tia lửa khi trúng đòn: ít, nhỏ, ngắn; vượt trần thì bỏ tia mới (không xoá tia cũ).
const SPARK_COUNT := 3
const SPARK_LIFETIME := 0.22
const MAX_SPARKS := 90
const HEAL_COLOR := Color("4ADE80")

const DAMAGE_COLORS := {
	DamageInfo.Type.PHYSICAL: Color(1.0, 1.0, 1.0),
	DamageInfo.Type.MAGIC: Color(0.8, 0.6, 1.0),
	DamageInfo.Type.TRUE: Color(1.0, 0.6, 0.25),
}

## { position, velocity, text, color, size, age }
var _texts: Array[Dictionary] = []
## { position, velocity, color, age, life, size }
var _particles: Array[Dictionary] = []
var _spark_count := 0
## { position, radius, color, age }
var _rings: Array[Dictionary] = []
var _shake_strength := 0.0
## Loé sáng toàn màn hình (kỹ năng toàn bản đồ).
var _flash_color := Color.TRANSPARENT
var _flash_time := 0.0

const FLASH_DURATION := 0.5


func _ready() -> void:
	show_damage_numbers = SaveManager.get_setting("damage_numbers")
	screen_shake = SaveManager.get_setting("screen_shake")
	SaveManager.settings_changed.connect(_on_settings_changed)


func _on_settings_changed(key: String, value: Variant) -> void:
	match key:
		"damage_numbers":
			show_damage_numbers = value
		"screen_shake":
			screen_shake = value


# --- Đăng ký nguồn sự kiện (Main gọi) ------------------------------------------

func track_enemy(enemy: Enemy) -> void:
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.healed.connect(_on_enemy_healed)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)


func track_tower(tower: Tower) -> void:
	tower.fired.connect(func(_target: Enemy, _damage: float) -> void:
		AudioManager.play(StringName("shoot_%s" % tower.data.id)))


## Theo dõi mọi đạn được thêm vào container (để bắt Projectile.impacted).
func track_projectile_container(container: Node) -> void:
	container.child_entered_tree.connect(func(node: Node) -> void:
		if node is Projectile:
			node.impacted.connect(_on_projectile_impacted))


## Hiệu ứng khi người chơi dùng kỹ năng.
func play_ability(ability: AbilityData, cast_position: Vector2) -> void:
	if ability.radius > 0.0:
		for i in 3:
			_rings.append({"position": cast_position, "radius": ability.radius * (0.6 + i * 0.25),
					"color": ability.color, "age": -i * 0.06})
		for i in 16:
			_particles.append({
				"position": cast_position,
				"velocity": Vector2.from_angle(TAU * i / 16.0) * randf_range(150.0, 260.0),
				"color": ability.color,
				"age": 0.0,
				"life": PARTICLE_LIFETIME,
				"size": 3.0,
			})
		shake(8.0)
	else:
		_flash_color = ability.color
		_flash_time = FLASH_DURATION
	AudioManager.play(StringName("ability_%s" % ability.id))


## Rung màn hình (cộng dồn, tự giảm dần).
func shake(strength: float) -> void:
	if screen_shake and not VisualSettings.reduced_motion:
		_shake_strength = minf(_shake_strength + strength, 16.0)


func get_active_effect_count() -> int:
	return _texts.size() + _particles.size() + _rings.size()


# --- Phản ứng với sự kiện -------------------------------------------------------

func _on_enemy_damaged(enemy: Enemy, amount: float, info: DamageInfo) -> void:
	if amount > 0.0 and not info.is_periodic:
		_add_sparks(enemy, DAMAGE_COLORS.get(info.type, Color.WHITE))
	if not show_damage_numbers or amount < 0.5 or _texts.size() >= MAX_FLOATING_TEXTS:
		return
	# Số sát thương mọc phía TRÊN thanh máu để không bao giờ che thanh.
	_add_text(enemy.global_position + Vector2(randf_range(-8, 8), enemy.health_bar.position.y - 6.0),
			str(roundi(amount)), DAMAGE_COLORS.get(info.type, Color.WHITE), 12 if info.is_periodic else 15)


## Tia lửa bắn ra từ mép thân địch, hướng ngẫu nhiên lệch lên trên.
func _add_sparks(enemy: Enemy, color: Color) -> void:
	if _spark_count + SPARK_COUNT > MAX_SPARKS:
		return
	var center := enemy.global_position
	for i in SPARK_COUNT:
		var direction := Vector2.from_angle(randf_range(-PI * 0.9, -PI * 0.1))
		_particles.append({
			"position": center + direction * enemy.data.radius * 0.6,
			"velocity": direction * randf_range(90.0, 160.0),
			"color": color,
			"age": 0.0,
			"life": SPARK_LIFETIME,
			"size": 2.0,
			"spark": true,
		})
	_spark_count += SPARK_COUNT


## Vài tia xanh lá bay lên khi địch được Thầy lang hồi máu (không dùng số: nhiều địch được
## hồi cùng lúc thì số chồng lên nhau rất rối; thanh máu đã cho biết lượng hồi).
func _on_enemy_healed(enemy: Enemy, _amount: float) -> void:
	_add_sparks(enemy, HEAL_COLOR)


func _on_enemy_died(enemy: Enemy, reward: int) -> void:
	var origin := enemy.global_position
	if reward > 0:
		_add_text(origin + Vector2(0, -enemy.data.radius - 18.0), "+%d" % reward, Color(1.0, 0.85, 0.3), 16)
	var count := 6 + int(enemy.data.radius * 0.4)
	for i in count:
		var direction := Vector2.from_angle(TAU * i / count + randf_range(-0.3, 0.3))
		_particles.append({
			"position": origin,
			"velocity": direction * randf_range(60.0, 140.0),
			"color": enemy.data.color,
			"age": 0.0,
			"life": PARTICLE_LIFETIME,
			"size": 3.0,
		})
	AudioManager.play(&"enemy_death")


func _on_enemy_reached_end(enemy: Enemy, damage: int) -> void:
	shake(4.0 + damage * 2.0)
	_add_text(enemy.global_position + Vector2(0, -30), "-%d máu" % damage, Color(1.0, 0.35, 0.35), 18)
	AudioManager.play(&"base_hit")


func _on_projectile_impacted(impact_position: Vector2, splash_radius: float) -> void:
	if splash_radius <= 0.0:
		return
	_rings.append({"position": impact_position, "radius": splash_radius, "color": Color(1.0, 0.6, 0.2), "age": 0.0})
	AudioManager.play(&"explosion")


## Chữ nổi lên rồi mờ dần tại một vị trí (vd "+20" trên Mỏ vàng).
func show_text(at: Vector2, text: String, color: Color, size: int = 16) -> void:
	_add_text(at, text, color, size)


func _add_text(at: Vector2, text: String, color: Color, size: int) -> void:
	_texts.append({
		"position": at,
		"text": text,
		"color": color,
		"size": size,
		"age": 0.0,
	})


# --- Cập nhật + vẽ --------------------------------------------------------------

func _process(delta: float) -> void:
	_update_shake(delta)
	if _flash_time > 0.0:
		_flash_time = maxf(_flash_time - delta, 0.0)
		queue_redraw()
	if get_active_effect_count() == 0:
		return

	for item in _texts:
		item.age += delta
		item.position.y -= TEXT_RISE_SPEED * delta
	for item in _particles:
		item.age += delta
		item.position += item.velocity * delta
		item.velocity *= 0.9
	for item in _rings:
		item.age += delta

	_texts = _texts.filter(func(item: Dictionary) -> bool: return item.age < TEXT_LIFETIME)
	_particles = _particles.filter(func(item: Dictionary) -> bool: return item.age < item.life)
	_spark_count = _particles.reduce(func(count: int, item: Dictionary) -> int:
		return count + (1 if item.has("spark") else 0), 0)
	_rings = _rings.filter(func(item: Dictionary) -> bool: return item.age < RING_LIFETIME)
	queue_redraw()


func _update_shake(delta: float) -> void:
	if camera == null:
		return
	var offset := Vector2.ZERO
	if _shake_strength > 0.05:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength
		_shake_strength = lerpf(_shake_strength, 0.0, minf(1.0, SHAKE_DECAY * delta))
	else:
		_shake_strength = 0.0
	# 3D: rung camera 3D (mét); camera 2D đứng yên vì hình 2D đã bám theo phép chiếu của camera 3D.
	if GameView.is_3d():
		GameView.camera.shake = Vector2(offset.x, -offset.y) / Space3D.PX_PER_M
		camera.offset = Vector2.ZERO
	elif camera.offset != offset:
		camera.offset = offset


func _draw() -> void:
	if _flash_time > 0.0:
		draw_rect(get_viewport_rect().grow(32.0), Color(_flash_color, 0.35 * _flash_time / FLASH_DURATION))

	for ring in _rings:
		var t: float = clampf(ring.age / RING_LIFETIME, 0.0, 1.0)
		draw_circle(ring.position, ring.radius * (0.4 + 0.6 * t), Color(ring.color, 0.25 * (1.0 - t)))
		draw_arc(ring.position, ring.radius * (0.4 + 0.6 * t), 0.0, TAU, 32, Color(ring.color, 1.0 - t), 3.0)

	for particle in _particles:
		var t: float = particle.age / particle.life
		if particle.has("spark"):
			# Tia lửa: vệt ngắn theo hướng bay, mảnh dần rồi tắt.
			var tail: Vector2 = particle.velocity * 0.03
			draw_line(particle.position - tail, particle.position, Color(particle.color, 1.0 - t), particle.size)
		else:
			draw_circle(particle.position, particle.size * (1.0 - t) + 1.0, Color(particle.color, 1.0 - t))

	var font := ThemeDB.fallback_font
	for item in _texts:
		var alpha := 1.0 - pow(item.age / TEXT_LIFETIME, 2.0)
		var size: int = item.size
		var width := font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var text_pos: Vector2 = item.position - Vector2(width * 0.5, 0)
		GameView.draw_text(self, font, text_pos, item.text, size, Color(item.color, alpha), Color(0, 0, 0, alpha * 0.8), 4)
