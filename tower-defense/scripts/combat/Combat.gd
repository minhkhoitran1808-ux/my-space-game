class_name Combat
extends RefCounted
## Hàm tiện ích dùng chung cho mọi kiểu tấn công (bắn trúng ngay hay đạn bay).


## Gây sát thương tại một điểm va chạm.
## - splash_radius <= 0: chỉ trúng mục tiêu chính (nếu còn sống).
## - splash_radius > 0: trúng TẤT CẢ địch trong bán kính quanh điểm va chạm.
## Trả về số địch bị trúng.
static func apply_hit(primary: Enemy, impact_position: Vector2, info: DamageInfo,
		splash_radius: float, tree: SceneTree) -> int:
	if splash_radius <= 0.0:
		if is_instance_valid(primary) and primary.is_alive():
			primary.take_damage(info)
			return 1
		return 0

	var hits := 0
	var radius_squared := splash_radius * splash_radius
	# get_nodes_in_group trả về bản sao nên an toàn khi có địch chết / sinh thêm giữa vòng lặp.
	for node in tree.get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy and enemy.is_alive() \
				and enemy.global_position.distance_squared_to(impact_position) <= radius_squared:
			enemy.take_damage(info)
			hits += 1
	return hits
