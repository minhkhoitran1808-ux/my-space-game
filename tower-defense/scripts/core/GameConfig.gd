class_name GameConfig
extends RefCounted
## Hằng số dùng chung cho bản đồ và lưới xây dựng.
##
## Đặt ở một chỗ để Ground (vẽ nền) và BuildManager (đặt tháp) luôn khớp nhau.

## Kích thước một ô lưới (pixel). Mỗi tháp chiếm đúng 1 ô.
const CELL_SIZE := 64
## Vùng được phép xây tháp (chừa hàng trên cùng cho thanh UI).
const BUILD_AREA := Rect2(0, 64, 1280, 640)
## Bề rộng đường đi khi vẽ.
const PATH_WIDTH := 48.0
## Tâm ô cách đường đi nhỏ hơn khoảng này thì không được xây.
const PATH_CLEARANCE := 56.0


## Đổi vị trí trong thế giới sang toạ độ ô lưới.
static func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / CELL_SIZE), floori(world_pos.y / CELL_SIZE))


## Trả về tâm của ô lưới trong toạ độ thế giới.
static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL_SIZE) + Vector2.ONE * CELL_SIZE * 0.5


static func is_in_build_area(cell: Vector2i) -> bool:
	return BUILD_AREA.has_point(cell_to_world(cell))
