class_name GameMap
extends Node2D
## Một bản đồ: chứa các Path2D (làn đường) trong node con "Paths".
##
## Địch (PathFollow2D) được spawn làm con của các Path2D này. Có thể có nhiều làn;
## mọi làn nên kết thúc tại cùng một điểm (nhà chính) = điểm cuối của làn đầu tiên.
## Ground vẽ nền và đường đi dựa trên các Path2D này nên bản đồ không cần asset.

@onready var _paths_root: Node = $Paths


func get_paths() -> Array[Path2D]:
	var paths: Array[Path2D] = []
	for child in _paths_root.get_children():
		if child is Path2D and child.curve and child.curve.point_count >= 2:
			paths.append(child)
	return paths


## Vị trí nhà chính (toạ độ thế giới) = điểm cuối của làn đầu tiên.
func get_base_position() -> Vector2:
	var path := get_paths()[0]
	return path.to_global(path.curve.get_point_position(path.curve.point_count - 1))
