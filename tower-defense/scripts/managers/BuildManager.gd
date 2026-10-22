class_name BuildManager
extends Node2D
## Xử lý việc đặt tháp bằng chuột.
##
## - Chọn loại tháp (nút trên HUD hoặc phím 1-9) để vào chế độ xây.
## - Di chuột: hiện bóng tháp + tầm bắn (xanh = đặt được, đỏ = không).
## - Chuột trái: đặt tháp. Chuột phải / Esc: thoát chế độ xây.
## - Khi không ở chế độ xây, click vào tháp để xem tầm bắn của nó.
##
## Dùng _unhandled_input nên click lên các nút UI sẽ không vô tình đặt tháp.

## Phát ra khi đổi loại tháp đang chọn (null = thoát chế độ xây).
signal build_mode_changed(tower_data: TowerData)
signal tower_placed(tower: Tower)
## Phát ra khi đặt tháp thất bại, kèm lý do để hiện lên UI.
signal placement_failed(reason: String)

@export var tower_container: Node2D
@export var enemy_path: Path2D
## Danh sách tháp người chơi được xây (thứ tự = phím tắt 1, 2, 3...).
@export var available_towers: Array[TowerData] = []

## Loại tháp đang chuẩn bị xây (null = không ở chế độ xây).
var selected_tower_data: TowerData = null

var _occupied_cells: Dictionary = {} # Vector2i -> Tower
var _hover_cell := Vector2i(-1, -1)
var _inspected_tower: Tower = null


func select_tower(tower_data: TowerData) -> void:
	# Bấm lại đúng loại đang chọn => huỷ chọn.
	selected_tower_data = null if tower_data == selected_tower_data else tower_data
	_set_inspected_tower(null)
	build_mode_changed.emit(selected_tower_data)
	queue_redraw()


func cancel_build() -> void:
	if selected_tower_data != null:
		select_tower(selected_tower_data)


func is_building() -> bool:
	return selected_tower_data != null


## Trả về chuỗi rỗng nếu đặt được, ngược lại là lý do không đặt được.
func get_placement_error(cell: Vector2i, tower_data: TowerData) -> String:
	if not GameConfig.is_in_build_area(cell):
		return "Không thể xây ngoài bản đồ"
	if _occupied_cells.has(cell):
		return "Ô này đã có tháp"
	if _is_on_path(GameConfig.cell_to_world(cell)):
		return "Không thể xây trên đường đi"
	if not GameManager.can_afford(tower_data.cost):
		return "Không đủ vàng (cần %d)" % tower_data.cost
	return ""


func try_place_tower(cell: Vector2i) -> Tower:
	var tower_data := selected_tower_data
	var error := get_placement_error(cell, tower_data)
	if not error.is_empty():
		placement_failed.emit(error)
		return null
	if not GameManager.spend_gold(tower_data.cost):
		return null

	var tower := tower_data.scene.instantiate() as Tower
	tower.data = tower_data
	tower.position = GameConfig.cell_to_world(cell)
	tower_container.add_child(tower)
	_occupied_cells[cell] = tower
	tower_placed.emit(tower)
	queue_redraw()
	return tower


func _is_on_path(world_pos: Vector2) -> bool:
	if enemy_path == null or enemy_path.curve == null:
		return false
	var local_pos := enemy_path.to_local(world_pos)
	var closest := enemy_path.curve.get_closest_point(local_pos)
	return local_pos.distance_to(closest) < GameConfig.PATH_CLEARANCE


func _set_inspected_tower(tower: Tower) -> void:
	if is_instance_valid(_inspected_tower):
		_inspected_tower.show_range = false
	_inspected_tower = tower
	if tower:
		tower.show_range = true


# --- Input ----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return

	if event is InputEventMouseMotion:
		var cell := _event_to_cell(event)
		if cell != _hover_cell:
			_hover_cell = cell
			queue_redraw()

	elif event is InputEventMouseButton and event.pressed:
		var cell := _event_to_cell(event)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_building():
				try_place_tower(cell)
			else:
				# Click vào tháp đang có => xem tầm bắn; click chỗ trống => bỏ chọn.
				var tower: Tower = _occupied_cells.get(cell)
				_set_inspected_tower(null if tower == _inspected_tower else tower)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_build()
			_set_inspected_tower(null)
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			cancel_build()
			get_viewport().set_input_as_handled()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index: int = event.keycode - KEY_1
			if index < available_towers.size():
				select_tower(available_towers[index])
				get_viewport().set_input_as_handled()


## Đổi vị trí chuột của event sang ô lưới (tính cả camera / stretch của viewport).
func _event_to_cell(event: InputEventMouse) -> Vector2i:
	var local_event := make_input_local(event) as InputEventMouse
	return GameConfig.world_to_cell(to_global(local_event.position))


# --- Bóng tháp khi đang xây -----------------------------------------------------

func _draw() -> void:
	if not is_building() or not GameConfig.is_in_build_area(_hover_cell):
		return
	var center := GameConfig.cell_to_world(_hover_cell)
	var size := Vector2.ONE * GameConfig.CELL_SIZE
	var can_place := get_placement_error(_hover_cell, selected_tower_data).is_empty()
	var color := Color(0.3, 1.0, 0.4) if can_place else Color(1.0, 0.3, 0.3)

	draw_rect(Rect2(center - size * 0.5, size), Color(color, 0.25))
	draw_rect(Rect2(center - size * 0.5, size), Color(color, 0.8), false, 2.0)
	draw_circle(center, selected_tower_data.attack_range, Color(color, 0.08))
	draw_arc(center, selected_tower_data.attack_range, 0.0, TAU, 64, Color(color, 0.6), 2.0)
	draw_circle(center, 14.0, Color(selected_tower_data.color, 0.6))
