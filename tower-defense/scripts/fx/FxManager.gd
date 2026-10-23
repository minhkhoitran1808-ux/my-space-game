class_name FxManager
extends Node2D
## Hiệu ứng phản hồi (hình ảnh + âm thanh) cho các sự kiện trong trận.
##
## - Số sát thương bay lên khi địch trúng đòn (màu theo loại sát thương).
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

const DAMAGE_COLORS := {
	DamageInfo.Type.PHYSICAL: Color(1.0, 1.0, 1.0),
	DamageInfo.Type.MAGIC: Color(0.8, 0.6, 1.0),
	DamageInfo.Type.TRUE: Color(1.0, 0.6, 0.25),
}

## { position, velocity, text, color, size, age }
var _texts: Array[Dictionary] = []
## { position, velocity, color, age }
var _particles: Array[Dictionary] = []
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
	if not show_damage_numbers or amount < 0.5 or _texts.size() >= MAX_FLOATING_TEXTS:
		return
	# Số sát thương mọc phía TRÊN thanh máu để không bao giờ che thanh.
	_add_text(enemy.global_position + Vector2(randf_range(-8, 8), enemy.health_bar.position.y - 6.0),
			str(roundi(amount)), DAMAGE_COLORS.get(info.type, Color.WHITE), 12 if info.is_periodic else 15)


func _on_enemy_died(enemy: Enemy, reward: int) -> void:
	var origin := enemy.global_position
	_add_text(origin + Vector2(0, -enemy.data.radius - 18.0), "+%d" % reward, Color(1.0, 0.85, 0.3), 16)
	var count := 6 + int(enemy.data.radius * 0.4)
	for i in count:
		var direction := Vector2.from_angle(TAU * i / count + randf_range(-0.3, 0.3))
		_particles.append({
			"position": origin,
			"velocity": direction * randf_range(60.0, 140.0),
			"color": enemy.data.color,
			"age": 0.0,
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
	_particles = _particles.filter(func(item: Dictionary) -> bool: return item.age < PARTICLE_LIFETIME)
	_rings = _rings.filter(func(item: Dictionary) -> bool: return item.age < RING_LIFETIME)
	queue_redraw()


func _update_shake(delta: float) -> void:
	if camera == null:
		return
	if _shake_strength > 0.05:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength
		_shake_strength = lerpf(_shake_strength, 0.0, minf(1.0, SHAKE_DECAY * delta))
	elif camera.offset != Vector2.ZERO:
		_shake_strength = 0.0
		camera.offset = Vector2.ZERO


func _draw() -> void:
	if _flash_time > 0.0:
		draw_rect(get_viewport_rect().grow(32.0), Color(_flash_color, 0.35 * _flash_time / FLASH_DURATION))

	for ring in _rings:
		var t: float = clampf(ring.age / RING_LIFETIME, 0.0, 1.0)
		draw_circle(ring.position, ring.radius * (0.4 + 0.6 * t), Color(ring.color, 0.25 * (1.0 - t)))
		draw_arc(ring.position, ring.radius * (0.4 + 0.6 * t), 0.0, TAU, 32, Color(ring.color, 1.0 - t), 3.0)

	for particle in _particles:
		var t: float = particle.age / PARTICLE_LIFETIME
		draw_circle(particle.position, 3.0 * (1.0 - t) + 1.0, Color(particle.color, 1.0 - t))

	var font := ThemeDB.fallback_font
	for item in _texts:
		var alpha := 1.0 - pow(item.age / TEXT_LIFETIME, 2.0)
		var size: int = item.size
		var width := font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var text_pos: Vector2 = item.position - Vector2(width * 0.5, 0)
		draw_string_outline(font, text_pos, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, alpha * 0.8))
		draw_string(font, text_pos, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(item.color, alpha))
