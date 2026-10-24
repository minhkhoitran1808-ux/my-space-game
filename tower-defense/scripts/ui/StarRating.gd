@tool
class_name StarRating
extends Control
## Hiển thị số sao (vd 2/3) bằng hình vẽ, không phụ thuộc font có ký tự ★ hay không.

@export_range(0, 5) var stars: int = 0:
	set(value):
		stars = value
		queue_redraw()
@export_range(1, 5) var max_stars: int = 3:
	set(value):
		max_stars = value
		_update_minimum_size()
@export var star_size: float = 28.0:
	set(value):
		star_size = value
		_update_minimum_size()
@export var spacing: float = 6.0
@export var filled_color: Color = Color(1.0, 0.82, 0.25)
@export var empty_color: Color = Color(1, 1, 1, 0.18)


func _ready() -> void:
	_update_minimum_size()


func _update_minimum_size() -> void:
	custom_minimum_size = Vector2(max_stars * star_size + (max_stars - 1) * spacing, star_size)
	queue_redraw()


func _draw() -> void:
	# Căn giữa dãy sao trong khung của Control.
	var total_width := max_stars * star_size + (max_stars - 1) * spacing
	var start_x := (size.x - total_width) * 0.5 + star_size * 0.5
	for i in max_stars:
		var center := Vector2(start_x + i * (star_size + spacing), size.y * 0.5)
		draw_colored_polygon(_star_points(center, star_size * 0.5), filled_color if i < stars else empty_color)


static func _star_points(center: Vector2, outer_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var radius := outer_radius if i % 2 == 0 else outer_radius * 0.45
		points.append(center + Vector2.from_angle(-PI * 0.5 + i * PI / 5.0) * radius)
	return points
