class_name BuildManager
extends Node2D
## Quản lý vòng đời tháp: xây, nâng cấp, bán, và ô lưới nào đang có tháp.
##
## - Chọn loại tháp (nút trên HUD hoặc phím 1-9) để vào chế độ xây.
## - Di chuột: phát hover_cell_changed; TowerRangeDisplay vẽ ghost + tầm bắn theo ô đó.
## - Chuột trái: đặt tháp. Chuột phải / Esc: thoát chế độ xây.
## Việc click chọn tháp có sẵn do SelectionManager lo.
##
## Dùng _unhandled_input nên click lên các nút UI sẽ không vô tình đặt tháp.

## Phát ra khi đổi loại tháp đang chọn (null = thoát chế độ xây).
signal build_mode_changed(tower_data: TowerData)
signal tower_placed(tower: Tower)
## Phát ra khi chuột chuyển sang ô lưới khác (để hiển thị ghost / tầm bắn).
signal hover_cell_changed(cell: Vector2i)
signal tower_upgraded(tower: Tower)
signal tower_sold(tower: Tower, refund: int)
## Phát ra khi đặt / nâng cấp tháp thất bại, kèm lý do để hiện lên UI.
signal placement_failed(reason: String)

@export var tower_container: Node2D
## Node chứa đạn do tháp bắn ra (vẽ phía trên địch).
@export var projectile_container: Node2D
## Danh sách tháp người chơi được xây (thứ tự = phím tắt 1, 2, 3...).
@export var available_towers: Array[TowerData] = []

## Loại tháp đang chuẩn bị xây (null = không ở chế độ xây).
var selected_tower_data: TowerData = null
## Các làn đường của bản đồ (không được xây đè lên). Main gán sau khi nạp bản đồ.
var paths: Array[Path2D] = []
## Bản đồ hiện tại (để biết ô đồi). Main gán; có thể null.
var map: GameMap = null

var _occupied_cells: Dictionary = {} # Vector2i -> Tower
var _hover_cell := Vector2i(-1, -1)


func select_tower(tower_data: TowerData) -> void:
	if tower_data and not GameManager.is_tower_unlocked(tower_data):
		var level := GameManager.get_unlock_level(tower_data)
		placement_failed.emit("%s: mở khoá khi qua màn \"%s\"" % [tower_data.display_name, level.display_name])
		return
	# Bấm lại đúng loại đang chọn => huỷ chọn.
	selected_tower_data = null if tower_data == selected_tower_data else tower_data
	build_mode_changed.emit(selected_tower_data)


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
	tower.total_invested = tower_data.cost
	tower.projectile_container = projectile_container
	tower.position = GameConfig.cell_to_world(cell)
	tower.range_multiplier = get_range_multiplier(cell)
	tower_container.add_child(tower)
	_occupied_cells[cell] = tower
	refresh_buffs()
	tower_placed.emit(tower)
	return tower


## Hệ số tầm bắn của một ô (ô đồi: 1.15).
func get_range_multiplier(cell: Vector2i) -> float:
	if map and map.get_terrain_at(GameConfig.cell_to_world(cell)) == GameMap.TERRAIN_HILL:
		return 1.0 + GameMap.HILL_RANGE_BONUS
	return 1.0


func get_tower_at(cell: Vector2i) -> Tower:
	return _occupied_cells.get(cell)


func get_towers() -> Array[Tower]:
	var towers: Array[Tower] = []
	towers.assign(_occupied_cells.values())
	return towers


## Nâng cấp tháp nếu còn cấp và đủ vàng. branch: nhánh cấp 4 (0 = A, 1 = B; bỏ qua nếu
## tháp chưa tới chỗ rẽ nhánh). Trả về true nếu thành công.
func upgrade_tower(tower: Tower, branch: int = 0) -> bool:
	if tower.data.get_upgrade(branch) == null:
		placement_failed.emit("Tháp đã đạt cấp tối đa")
		return false
	var cost := tower.get_upgrade_cost(branch)
	if not GameManager.spend_gold(cost):
		placement_failed.emit("Không đủ vàng (cần %d)" % cost)
		return false
	tower.upgrade(branch)
	refresh_buffs()
	tower_upgraded.emit(tower)
	return true


## Tính lại buff Cờ hiệu cho mọi tháp (gọi khi có tháp được xây / nâng cấp / bán).
func refresh_buffs() -> void:
	for tower in get_towers():
		tower.refresh_buff()


## Cộng vàng của mọi Mỏ vàng (gọi khi hết một wave). Trả về [[tháp, số vàng], ...].
func collect_mine_gold() -> Array:
	var payouts := []
	for tower in get_towers():
		if tower.data.gold_per_wave > 0:
			GameManager.add_gold(tower.data.gold_per_wave)
			payouts.append([tower, tower.data.gold_per_wave])
	return payouts


## Bán tháp, hoàn lại một phần vàng và giải phóng ô. Trả về số vàng nhận được.
func sell_tower(tower: Tower) -> int:
	var cell := GameConfig.world_to_cell(tower.position)
	if _occupied_cells.get(cell) != tower:
		return 0
	var refund := tower.get_sell_value()
	_occupied_cells.erase(cell)
	GameManager.add_gold(refund)
	tower.remove_from_group(Tower.GROUP)
	refresh_buffs()
	tower_sold.emit(tower, refund)
	tower.queue_free()
	return refund


func _is_on_path(world_pos: Vector2) -> bool:
	for path in paths:
		var local_pos := path.to_local(world_pos)
		if local_pos.distance_to(path.curve.get_closest_point(local_pos)) < GameConfig.PATH_CLEARANCE:
			return true
	return false


# --- Input ----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return

	if event is InputEventMouseMotion:
		var cell := event_to_cell(event)
		if cell != _hover_cell:
			_hover_cell = cell
			hover_cell_changed.emit(cell)

	elif event is InputEventMouseButton and event.pressed and is_building():
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_place_tower(event_to_cell(event))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_build()
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and is_building():
			cancel_build()
			get_viewport().set_input_as_handled()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index: int = event.keycode - KEY_1
			if index < available_towers.size():
				select_tower(available_towers[index])
				get_viewport().set_input_as_handled()


## Đổi vị trí chuột của event sang ô lưới (tính cả camera / stretch của viewport).
func event_to_cell(event: InputEventMouse) -> Vector2i:
	var local_event := make_input_local(event) as InputEventMouse
	return GameConfig.world_to_cell(to_global(local_event.position))
