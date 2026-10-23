class_name TowerStats
extends RefCounted
## Định dạng chỉ số tháp thành chữ cho UI (tooltip nút xây, bảng thông tin tháp).
## Gom vào một chỗ để tooltip và bảng thông tin luôn hiển thị giống nhau.


## Mô tả chỉ số. Nếu truyền "next", các chỉ số thay đổi hiện dạng "cũ → mới".
static func describe(data: TowerData, next: TowerData = null) -> String:
	var compare_to := next if next else data
	var lines := PackedStringArray()
	lines.append("Sát thương: %s (%s)" % [_compare(data.damage, compare_to.damage), DamageInfo.type_name(data.damage_type)])
	lines.append("Tốc độ bắn: %s phát/giây" % _compare(data.fire_rate, compare_to.fire_rate))
	lines.append("Tầm bắn: %s" % _compare(data.attack_range, compare_to.attack_range))
	if data.splash_radius > 0.0 or compare_to.splash_radius > 0.0:
		lines.append("Nổ lan: %s" % _compare(data.splash_radius, compare_to.splash_radius))

	var effects_now := _effects_text(data)
	var effects_next := _effects_text(compare_to)
	if not effects_now.is_empty():
		lines.append("Hiệu ứng: %s" % (effects_now if effects_now == effects_next else "%s → %s" % [effects_now, effects_next]))
	lines.append("Kiểu bắn: %s" % ("Tia (trúng ngay)" if data.attack_type == TowerData.AttackType.HITSCAN else "Đạn bay"))
	return "\n".join(lines)


## Nội dung tooltip cho nút xây tháp.
static func tooltip(data: TowerData) -> String:
	var text := "%s  (%d vàng)\n" % [data.display_name, data.cost]
	if not data.description.is_empty():
		text += data.description + "\n"
	return text + "\n" + describe(data)


## Cấp tối đa của chuỗi nâng cấp chứa "data".
static func max_level(data: TowerData) -> int:
	var last := data
	while last.next_level:
		last = last.next_level
	return last.level


static func _effects_text(data: TowerData) -> String:
	var parts := PackedStringArray()
	for effect in data.on_hit_effects:
		var details := PackedStringArray()
		if effect.slow_amount > 0.0:
			details.append("%d%%" % roundi(effect.slow_amount * 100.0))
		if effect.damage_per_second > 0.0:
			details.append("%s/giây" % _num(effect.damage_per_second))
		parts.append("%s %s (%ss)" % [effect.display_name, ", ".join(details), _num(effect.duration)])
	return "; ".join(parts)


static func _compare(current: float, next_value: float) -> String:
	if is_equal_approx(current, next_value):
		return _num(current)
	return "%s → %s" % [_num(current), _num(next_value)]


## Số nguyên thì bỏ ".0" (12 thay vì 12.0), số lẻ giữ tối đa 2 chữ số.
static func _num(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return String.num(value, 2)
