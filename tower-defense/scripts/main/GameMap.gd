class_name GameMap
extends Node2D
## Một bản đồ: chứa các Path2D (làn đường) trong node con "Paths".
##
## Địch (PathFollow2D) được spawn làm con của các Path2D này. Có thể có nhiều làn;
## mọi làn nên kết thúc tại cùng một điểm (nhà chính) = điểm cuối của làn đầu tiên.
## Ground vẽ nền và đường đi dựa trên các Path2D này nên bản đồ không cần asset.
##
## Địch bay đi theo các Path2D trong node con "AirPaths". Nếu bản đồ không có node này,
## một làn trên không thẳng từ đầu làn 1 tới nhà chính sẽ được tạo tự động.
## Làn trên không không được vẽ và không chặn việc xây tháp.
##
## Địa hình (tuỳ chọn): node con "Terrain" chứa các Polygon2D có metadata "kind":
## - "mud": bùn, địch đi bộ qua bị chậm 20%.
## - "hill": đồi, tháp đặt lên được +15% tầm bắn.
## Polygon2D chỉ dùng để chỉnh hình trong editor; Ground vẽ địa hình nên chúng được ẩn đi.

const TERRAIN_MUD := &"mud"
const TERRAIN_HILL := &"hill"
## Hiệu ứng của địa hình.
const MUD_SLOW := 0.2
const HILL_RANGE_BONUS := 0.15

@onready var _paths_root: Node = $Paths


## kind -> Array[PackedVector2Array] (toạ độ toàn cục), lập một lần trong _ready().
var _terrain: Dictionary = {}


func _ready() -> void:
	if not has_node("AirPaths"):
		_create_default_air_path()
	if has_node("Terrain"):
		for node in get_node("Terrain").get_children():
			var polygon := node as Polygon2D
			if polygon == null or not polygon.has_meta("kind"):
				continue
			var points := PackedVector2Array()
			for point in polygon.polygon:
				points.append(polygon.to_global(point))
			var kind := StringName(polygon.get_meta("kind"))
			if not _terrain.has(kind):
				_terrain[kind] = []
			_terrain[kind].append(points)
			polygon.visible = false


## Các vùng địa hình một loại (toạ độ toàn cục).
func get_terrain_polygons(kind: StringName) -> Array:
	return _terrain.get(kind, [])


## Loại địa hình tại một điểm (&"" nếu là đất thường).
func get_terrain_at(world_pos: Vector2) -> StringName:
	for kind: StringName in _terrain:
		for points: PackedVector2Array in _terrain[kind]:
			if Geometry2D.is_point_in_polygon(world_pos, points):
				return kind
	return &""


func get_paths() -> Array[Path2D]:
	return _collect_paths(_paths_root)


func get_air_paths() -> Array[Path2D]:
	return _collect_paths(get_node("AirPaths"))


## Vị trí nhà chính (toạ độ thế giới) = điểm cuối của làn đầu tiên.
func get_base_position() -> Vector2:
	var path := get_paths()[0]
	return path.to_global(path.curve.get_point_position(path.curve.point_count - 1))


func _collect_paths(root: Node) -> Array[Path2D]:
	var paths: Array[Path2D] = []
	for child in root.get_children():
		if child is Path2D and child.curve and child.curve.point_count >= 2:
			paths.append(child)
	return paths


func _create_default_air_path() -> void:
	var ground := get_paths()[0]
	var curve := Curve2D.new()
	curve.add_point(to_local(ground.to_global(ground.curve.get_point_position(0))))
	curve.add_point(to_local(get_base_position()))
	var air_path := Path2D.new()
	air_path.name = "AirLane1"
	air_path.curve = curve
	var air_root := Node2D.new()
	air_root.name = "AirPaths"
	air_root.add_child(air_path)
	add_child(air_root)
