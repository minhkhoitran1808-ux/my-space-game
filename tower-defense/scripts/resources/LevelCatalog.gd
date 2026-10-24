class_name LevelCatalog
extends Resource
## Danh sách các màn chơi theo thứ tự. Màn sau mở khoá khi qua màn trước.

@export var levels: Array[LevelData] = []


func get_level_index(level: LevelData) -> int:
	return levels.find(level)


## Màn kế tiếp (null nếu là màn cuối hoặc không có trong danh sách).
func get_next_level(level: LevelData) -> LevelData:
	var index := get_level_index(level)
	if index < 0 or index + 1 >= levels.size():
		return null
	return levels[index + 1]
