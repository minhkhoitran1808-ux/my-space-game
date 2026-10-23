class_name StatusEffectHandler
extends Node
## Quản lý các hiệu ứng trạng thái đang có trên một Enemy (node cha).
##
## Enemy chỉ cần hỏi get_speed_multiplier() khi di chuyển; phần đếm giờ,
## trừ máu theo thời gian và hết hạn hiệu ứng đều nằm ở đây.

## Phát ra khi có hiệu ứng được thêm hoặc hết hạn (để Enemy vẽ lại).
signal effects_changed

## id -> { data: StatusEffectData, remaining: float, tick_timer: float, source: Node }
var _active: Dictionary = {}

@onready var _enemy: Enemy = get_parent()


func apply(effect: StatusEffectData, source: Node = null) -> void:
	var current: Dictionary = _active.get(effect.id, {})
	if current.is_empty() or effect.get_strength() > current.data.get_strength():
		_active[effect.id] = {
			"data": effect,
			"remaining": effect.duration,
			"tick_timer": effect.tick_interval,
			"source": source,
		}
		effects_changed.emit()
	else:
		# Hiệu ứng yếu hơn / bằng: chỉ kéo dài thời gian.
		current.remaining = maxf(current.remaining, effect.duration)


func has_effect(id: StringName) -> bool:
	return _active.has(id)


func clear() -> void:
	_active.clear()
	effects_changed.emit()


## Hệ số nhân tốc độ: lấy hiệu ứng làm chậm mạnh nhất (không nhân dồn),
## sau đó giảm theo slow_resistance của địch.
func get_speed_multiplier() -> float:
	var strongest_slow := 0.0
	for entry: Dictionary in _active.values():
		strongest_slow = maxf(strongest_slow, entry.data.slow_amount)
	strongest_slow = minf(strongest_slow, _enemy.data.max_slow)
	return 1.0 - strongest_slow * (1.0 - _enemy.data.slow_resistance)


## Màu của các hiệu ứng đang có, để Enemy vẽ vòng sáng.
func get_tints() -> Array[Color]:
	var tints: Array[Color] = []
	for entry: Dictionary in _active.values():
		tints.append(entry.data.tint)
	return tints


func _process(delta: float) -> void:
	if _active.is_empty():
		return

	var changed := false
	for id: StringName in _active.keys():
		var entry: Dictionary = _active[id]
		var effect: StatusEffectData = entry.data
		entry.remaining -= delta

		if effect.damage_per_second > 0.0:
			entry.tick_timer -= delta
			while entry.tick_timer <= 0.0:
				entry.tick_timer += effect.tick_interval
				var source: Node = entry.source if is_instance_valid(entry.source) else null
				var tick := DamageInfo.new(effect.damage_per_second * effect.tick_interval, effect.damage_type, source)
				tick.is_periodic = true
				_enemy.take_damage(tick)
				if not _enemy.is_alive():
					return

		if entry.remaining <= 0.0:
			_active.erase(id)
			changed = true

	if changed:
		effects_changed.emit()
