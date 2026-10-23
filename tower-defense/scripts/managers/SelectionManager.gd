class_name SelectionManager
extends Node
## Chọn tháp đã đặt bằng chuột và xử lý phím tắt cho tháp đang chọn.
##
## - Chuột trái vào tháp: chọn (kể cả khi đang ở chế độ xây).
## - Chuột trái vào ô trống / chuột phải / Esc: bỏ chọn.
## - U: nâng cấp, X: bán, T: đổi cách chọn mục tiêu.
##
## Node này phải nằm SAU BuildManager trong cây node: _unhandled_input đi từ node
## dưới cùng lên trên, nên click vào tháp có sẵn được ưu tiên "chọn" thay vì "xây".
## SelectionManager không tự nâng cấp / bán mà phát signal để Main gọi BuildManager.

## Phát ra khi đổi tháp đang chọn (null = bỏ chọn).
signal selection_changed(tower: Tower)
## branch: nhánh cấp 4 (U = nhánh A, Shift+U = nhánh B).
signal upgrade_requested(tower: Tower, branch: int)
signal sell_requested(tower: Tower)

@export var build_manager: BuildManager

var selected_tower: Tower = null


func select(tower: Tower) -> void:
	if tower == selected_tower:
		return
	if is_instance_valid(selected_tower):
		selected_tower.show_range = false
		selected_tower.tree_exiting.disconnect(_on_selected_tower_exiting)
	selected_tower = tower
	if tower:
		tower.show_range = true
		# Tháp bị bán / xoá thì tự bỏ chọn.
		tower.tree_exiting.connect(_on_selected_tower_exiting)
	selection_changed.emit(selected_tower)


func deselect() -> void:
	select(null)


func has_selection() -> bool:
	return is_instance_valid(selected_tower)


func set_target_mode(mode: Tower.TargetMode) -> void:
	if has_selection():
		selected_tower.target_mode = mode


## Chuyển sang cách chọn mục tiêu kế tiếp (vòng lại từ đầu).
func cycle_target_mode() -> void:
	if has_selection():
		var next_mode := (selected_tower.target_mode + 1) % Tower.TargetMode.size()
		set_target_mode(next_mode as Tower.TargetMode)


func _on_selected_tower_exiting() -> void:
	selected_tower = null
	selection_changed.emit(null)


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var tower := build_manager.get_tower_at(build_manager.event_to_cell(event))
			if tower:
				build_manager.cancel_build()
				select(tower)
				get_viewport().set_input_as_handled()
			elif not build_manager.is_building():
				deselect()
		elif event.button_index == MOUSE_BUTTON_RIGHT and has_selection():
			deselect()
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and not event.echo and has_selection():
		match event.keycode:
			KEY_ESCAPE:
				deselect()
			KEY_U:
				upgrade_requested.emit(selected_tower, 1 if event.shift_pressed else 0)
			KEY_X:
				sell_requested.emit(selected_tower)
			KEY_T:
				cycle_target_mode()
			_:
				return
		get_viewport().set_input_as_handled()
