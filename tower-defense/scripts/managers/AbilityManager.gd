class_name AbilityManager
extends Node2D
## Kỹ năng chủ động của người chơi: hồi chiêu, chọn vùng bằng chuột, phím tắt.
##
## - Bấm nút kỹ năng / phím tắt: kỹ năng cần chọn vùng thì vào chế độ ngắm (vẽ vòng tròn
##   theo chuột, chuột trái để dùng, chuột phải / Esc để huỷ); kỹ năng toàn bản đồ thì dùng ngay.
## - Sát thương đi qua Combat.apply_hit() giống tháp, nên giáp / kháng / hiệu ứng vẫn áp dụng.
##
## Node này đặt SAU SelectionManager trong cây node để khi đang ngắm, click chuột được
## dùng cho kỹ năng thay vì chọn / xây tháp.

signal ability_cast(ability: AbilityData, cast_position: Vector2)
## Phát ra khi bắt đầu / thôi ngắm (null = thôi).
signal targeting_changed(ability: AbilityData)
## Phát ra mỗi frame khi thời gian hồi thay đổi (remaining = 0 là đã sẵn sàng).
signal cooldown_changed(ability: AbilityData, remaining: float)
signal ability_failed(reason: String)

@export var abilities: Array[AbilityData] = []

## Kỹ năng đang ngắm (null = không ngắm).
var targeting: AbilityData = null

var _cooldowns: Dictionary = {} # AbilityData -> giây còn lại
var _aim_position := Vector2.ZERO


func get_cooldown_remaining(ability: AbilityData) -> float:
	return _cooldowns.get(ability, 0.0)


func is_ready(ability: AbilityData) -> bool:
	return get_cooldown_remaining(ability) <= 0.0


## Người chơi muốn dùng kỹ năng (nút trên HUD hoặc phím tắt).
func request(ability: AbilityData) -> void:
	if not GameManager.is_playing():
		return
	if not is_ready(ability):
		ability_failed.emit("%s đang hồi (%ds)" % [ability.display_name, ceili(get_cooldown_remaining(ability))])
		return
	if not ability.targeted:
		cast(ability, Vector2.ZERO)
	elif targeting == ability:
		cancel_targeting()
	else:
		targeting = ability
		targeting_changed.emit(targeting)
		queue_redraw()


func cancel_targeting() -> void:
	if targeting == null:
		return
	targeting = null
	targeting_changed.emit(null)
	queue_redraw()


## Dùng kỹ năng tại một vị trí (bỏ qua vị trí nếu là kỹ năng toàn bản đồ).
func cast(ability: AbilityData, cast_position: Vector2) -> bool:
	if not GameManager.is_playing() or not is_ready(ability):
		return false
	var info := DamageInfo.new(ability.damage, ability.damage_type, self)
	info.effects = ability.effects
	if ability.radius > 0.0:
		Combat.apply_hit(null, cast_position, info, ability.radius, get_tree())
	else:
		for node in get_tree().get_nodes_in_group(Enemy.GROUP):
			var enemy := node as Enemy
			if enemy and enemy.is_alive():
				enemy.take_damage(info)

	_cooldowns[ability] = ability.cooldown
	if targeting == ability:
		cancel_targeting()
	ability_cast.emit(ability, cast_position)
	return true


## Giảm thời gian hồi của mọi kỹ năng (thưởng khi gọi wave sớm).
func reduce_cooldowns(seconds: float) -> void:
	for ability: AbilityData in _cooldowns.keys():
		_cooldowns[ability] = maxf(_cooldowns[ability] - seconds, 0.001)


func _process(delta: float) -> void:
	for ability: AbilityData in _cooldowns.keys():
		var remaining: float = maxf(_cooldowns[ability] - delta, 0.0)
		cooldown_changed.emit(ability, remaining)
		if remaining <= 0.0:
			_cooldowns.erase(ability)
		else:
			_cooldowns[ability] = remaining


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		for ability in abilities:
			if event.keycode == ability.hotkey:
				request(ability)
				get_viewport().set_input_as_handled()
				return
		if event.keycode == KEY_ESCAPE and targeting:
			cancel_targeting()
			get_viewport().set_input_as_handled()
		return

	if targeting == null or not event is InputEventMouse:
		return
	_aim_position = to_global((make_input_local(event) as InputEventMouse).position)
	if event is InputEventMouseMotion:
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			cast(targeting, _aim_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_targeting()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if targeting == null:
		return
	var center := to_local(_aim_position)
	draw_circle(center, targeting.radius, Color(targeting.color, 0.15))
	draw_arc(center, targeting.radius, 0.0, TAU, 48, Color(targeting.color, 0.9), 3.0)
	draw_circle(center, 4.0, targeting.color)
