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

@onready var _paths_root: Node = $Paths


func _ready() -> void:
	if not has_node("AirPaths"):
		_create_default_air_path()


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
