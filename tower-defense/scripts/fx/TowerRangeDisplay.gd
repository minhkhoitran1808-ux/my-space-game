class_name TowerRangeDisplay
extends Node2D
## Hiển thị tầm bắn + ghost tháp + phản hồi khi đặt tháp.
##
## Node này CHỈ hiển thị: nó nghe signal của BuildManager / SelectionManager và hỏi lại
## BuildManager.get_placement_error() - đúng hàm mà lệnh đặt thật dùng - nên ghost và kết quả
## đặt thật không bao giờ mâu thuẫn. Không có logic game nào nằm ở đây.
##
## Thứ tự vẽ (node này nằm giữa Towers và Map trong Main.tscn):
##   fill các vòng (dưới địch) < địch / đạn < viền các vòng (z 1) < ghost + hiệu ứng (z 2) < UI.

const COLOR_VALID := Color("#56B4E9")
const COLOR_INVALID := Color("#D55E00")
const OUTLINE_DARK := Color(0.043, 0.071, 0.125, 0.85)
const GHOST_ALPHA := 0.6
## Mức pha màu trạng thái vào hình tháp (35%: vẫn giữ được chi tiết của tháp).
const GHOST_TINT := 0.35
const SHAKE_PIXELS := 4.0
const SHAKE_TIME := 0.2
const SQUASH_SCALE := Vector2(1.15, 0.85)
const SHOCKWAVE_TIME := 0.35
const DUST_TIME := 0.4
const REASON_TIME := 1.2
const COST_TIME := 0.6
const TEXT_RISE := 24.0
const FONT := preload("res://assets/fonts/BeVietnamPro-SemiBold.ttf")

var build_manager: BuildManager
var selection_manager: SelectionManager

# Các lớp con (tạo trong _ready).
var _placement_ring: RangeIndicator
var _selection_ring: RangeIndicator
var _upgrade_ring: RangeIndicator
var _neighbor_layer: Node2D
var _ghost: Node2D
var _fx_layer: Node2D

var _hover_cell := Vector2i(-999, -999)
## Ô vừa đặt tháp thành công: ẩn ghost ở ô này cho tới khi chuột sang ô khác
## (nếu không, ghost sẽ lập tức đỏ lên vì "ô đã có tháp").
var _suppressed_cell := Vector2i(-999, -999)
var _placement_error := ""
var _ghost_offset := 0.0
var _shake_tween: Tween
var _upgrade_preview_on := false
var _upgrade_preview_branch := 0

## Hiệu ứng ngắn: { kind, position, age, life, ... } vẽ trong _fx_layer.
var _effects: Array[Dictionary] = []


func _ready() -> void:
	_neighbor_layer = _make_layer("NeighborRings", 1, _draw_neighbors)
	_placement_ring = _make_ring("PlacementRing")
	_selection_ring = _make_ring("SelectionRing")
	_upgrade_ring = _make_ring("UpgradePreviewRing")
	_ghost = _make_layer("Ghost", 2, _draw_ghost)
	_ghost.visible = false
	_fx_layer = _make_layer("PlacementFx", 2, _draw_effects)
	set_process(false)


## Main gọi sau khi các manager sẵn sàng.
func setup(p_build_manager: BuildManager, p_selection_manager: SelectionManager) -> void:
	build_manager = p_build_manager
	selection_manager = p_selection_manager
	build_manager.build_mode_changed.connect(_on_build_mode_changed)
	build_manager.hover_cell_changed.connect(_on_hover_cell_changed)
	build_manager.tower_placed.connect(_on_tower_placed)
	build_manager.tower_sold.connect(func(_tower: Tower, _refund: int) -> void: _refresh_all())
	build_manager.tower_upgraded.connect(_on_tower_upgraded)
	build_manager.placement_failed.connect(_on_placement_failed)
	selection_manager.selection_changed.connect(_on_selection_changed)
	GameManager.gold_changed.connect(func(_gold: int) -> void: _refresh_preview())


# --- API cho test / UI ------------------------------------------------------------

## Trạng thái vòng đặt tháp hiện tại (HIDDEN / VALID / INVALID).
func get_placement_state() -> RangeIndicator.State:
	return _placement_ring.state


func get_placement_radius() -> float:
	return _placement_ring.radius


func get_selection_ring() -> RangeIndicator:
	return _selection_ring


func get_upgrade_ring() -> RangeIndicator:
	return _upgrade_ring


func is_ghost_visible() -> bool:
	return _ghost.visible


func get_effect_count() -> int:
	return _effects.size()


## Bật / tắt vòng xem trước tầm bắn sau nâng cấp (khi rê chuột lên nút Nâng cấp).
func show_upgrade_preview(enabled: bool, branch: int = 0) -> void:
	_upgrade_preview_on = enabled
	_upgrade_preview_branch = branch
	var tower := _selected_tower()
	var next := tower.data.get_upgrade(branch) if tower else null
	if enabled and next and next.attack_range > 0.0:
		_upgrade_ring.position = tower.position
		_upgrade_ring.show_ring(RangeIndicator.State.UPGRADE_PREVIEW, next.attack_range * tower.range_multiplier)
	else:
		_upgrade_ring.hide_ring()


# --- Phản ứng với signal ------------------------------------------------------------

func _on_build_mode_changed(_tower_data: TowerData) -> void:
	_suppressed_cell = Vector2i(-999, -999)
	_refresh_all()


func _on_hover_cell_changed(cell: Vector2i) -> void:
	_hover_cell = cell
	if cell != _suppressed_cell:
		_suppressed_cell = Vector2i(-999, -999)
	_refresh_preview()


func _on_selection_changed(tower: Tower) -> void:
	if tower:
		_selection_ring.position = tower.position
		_selection_ring.show_ring(RangeIndicator.State.SELECTED, tower.get_range())
	else:
		_selection_ring.hide_ring()
	show_upgrade_preview(_upgrade_preview_on and tower != null, _upgrade_preview_branch)


func _on_tower_upgraded(tower: Tower) -> void:
	if tower == _selected_tower():
		_selection_ring.set_radius(tower.get_range())
		show_upgrade_preview(_upgrade_preview_on, _upgrade_preview_branch)


## Đặt thành công: tháp "đáp đất" (squash), sóng vòng lan tới đúng tầm bắn, bụi, "-giá".
## Chỉ là trình diễn: tiền đã trừ và tháp đã hoạt động ngay từ trước, không khoá input.
func _on_tower_placed(tower: Tower) -> void:
	# Giảm chuyển động: bỏ squash, sóng lan và bụi; chỉ giữ chữ "-giá".
	if not VisualSettings.reduced_motion:
		var squash := tower.create_tween()
		squash.tween_property(tower, "scale", SQUASH_SCALE, 0.06)
		squash.tween_property(tower, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_add_effect({"kind": "shockwave", "position": tower.position, "radius": tower.data.attack_range,
				"life": SHOCKWAVE_TIME})
		for i in 10:
			var direction := Vector2.from_angle(TAU * i / 10.0 + randf_range(-0.25, 0.25))
			_add_effect({"kind": "dust", "position": tower.position + direction * 16.0,
					"velocity": direction * randf_range(40.0, 90.0), "life": DUST_TIME})
	_add_effect({"kind": "text", "position": tower.position + Vector2(0, -34), "text": "-%d" % tower.data.cost,
			"color": Color("#FFC72C"), "life": COST_TIME, "size": 16})

	_suppressed_cell = GameConfig.world_to_cell(tower.position)
	_refresh_all()


## Đặt thất bại: ghost rung ngang ±4px (không rung camera) + lý do nổi lên cạnh ô.
func _on_placement_failed(reason: String) -> void:
	if not build_manager.is_building() or not _ghost.visible:
		return
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	if not VisualSettings.reduced_motion:
		_shake_tween = create_tween()
		for offset in [SHAKE_PIXELS, -SHAKE_PIXELS, SHAKE_PIXELS, -SHAKE_PIXELS, SHAKE_PIXELS * 0.5, 0.0]:
			_shake_tween.tween_method(_set_ghost_offset, _ghost_offset, offset, SHAKE_TIME / 6.0)
	_add_effect({"kind": "text", "position": GameConfig.cell_to_world(_hover_cell) + Vector2(0, -44),
			"text": reason, "color": Color.WHITE, "life": REASON_TIME, "size": 15})


# --- Cập nhật hiển thị --------------------------------------------------------------

func _refresh_all() -> void:
	_neighbor_layer.queue_redraw()
	_refresh_preview()


## Ghost + vòng đặt tháp theo ô đang trỏ, dùng CHUNG hàm kiểm tra với lệnh đặt thật.
func _refresh_preview() -> void:
	if build_manager == null:
		return
	var data := build_manager.selected_tower_data
	var should_show := data != null and GameConfig.is_in_build_area(_hover_cell) and _hover_cell != _suppressed_cell
	if not should_show:
		_placement_ring.hide_ring()
		_ghost.visible = false
		return

	_placement_error = build_manager.get_placement_error(_hover_cell, data)
	var center := GameConfig.cell_to_world(_hover_cell)
	_placement_ring.position = center # Snap ngay vào ô, không trễ.
	_placement_ring.show_ring(RangeIndicator.State.VALID if _placement_error.is_empty() else RangeIndicator.State.INVALID,
			data.attack_range)
	_ghost.visible = true
	_ghost.position = center + Vector2(_ghost_offset, 0)
	_ghost.queue_redraw()


func _set_ghost_offset(value: float) -> void:
	_ghost_offset = value
	if _ghost.visible:
		_ghost.position = GameConfig.cell_to_world(_hover_cell) + Vector2(value, 0)


func _selected_tower() -> Tower:
	if selection_manager and selection_manager.has_selection():
		return selection_manager.selected_tower
	return null


# --- Vẽ -----------------------------------------------------------------------------

## Vòng mờ của các tháp đã xây (chỉ khi đang đặt tháp) để thấy chỗ chồng lấn.
func _draw_neighbors() -> void:
	if build_manager == null or not build_manager.is_building():
		return
	var style: Dictionary = RangeIndicator.STYLE[RangeIndicator.State.NEIGHBOR]
	var color := Color(style.stroke, style.stroke_alpha)
	for tower in build_manager.get_towers():
		_neighbor_layer.draw_arc(tower.position, tower.get_range(), 0.0, TAU,
				RangeIndicator.POINT_COUNT, color, style.width, true)


func _draw_ghost() -> void:
	var data := build_manager.selected_tower_data if build_manager else null
	if data == null:
		return
	var valid := _placement_error.is_empty()
	var state_color := COLOR_VALID if valid else COLOR_INVALID
	var cell := Vector2.ONE * GameConfig.CELL_SIZE

	# Khung ô tháp sẽ chiếm (footprint) + bóng đổ để ghost "bám đất".
	_ghost.draw_rect(Rect2(-cell * 0.5, cell), Color(state_color, 0.12))
	_ghost.draw_rect(Rect2(-cell * 0.5 + Vector2.ONE, cell - Vector2.ONE * 2.0), Color(state_color, 0.9), false, 2.0)
	_draw_ellipse(_ghost, Vector2(0, 18), Vector2(24, 8), Color(0, 0, 0, 0.25))
	# Hình tháp thật, trong suốt và pha màu trạng thái.
	Tower.draw_body(_ghost, data, -PI * 0.5, Color(state_color, GHOST_TINT), GHOST_ALPHA,
			InventoryManager.get_equipped_skin(data.id))

	# Không đặt được: thêm ✕ ở tâm (không chỉ dựa vào màu).
	if not valid:
		var arm := 9.0
		for pass_width in [6.0, 3.0]:
			var color := OUTLINE_DARK if pass_width > 4.0 else COLOR_INVALID.lightened(0.15)
			_ghost.draw_line(Vector2(-arm, -arm), Vector2(arm, arm), color, pass_width, true)
			_ghost.draw_line(Vector2(arm, -arm), Vector2(-arm, arm), color, pass_width, true)

	# Nhãn giá cạnh ghost: trắng nếu đủ vàng, cam đỏ nếu thiếu.
	var affordable := GameManager.can_afford(data.cost)
	_draw_text(_ghost, Vector2(cell.x * 0.5 + 6.0, cell.y * 0.5 - 4.0), "%d vàng" % data.cost,
			Color.WHITE if affordable else COLOR_INVALID.lightened(0.2), 14, HORIZONTAL_ALIGNMENT_LEFT)


func _draw_effects() -> void:
	for effect in _effects:
		var t: float = clampf(effect.age / effect.life, 0.0, 1.0)
		match effect.kind:
			"shockwave":
				# Bán kính 0.3r -> 1.0r, alpha 0.6 -> 0: cho thấy vùng tháp vừa phủ.
				var eased := 1.0 - pow(1.0 - t, 3.0)
				var ring_radius: float = lerpf(0.3, 1.0, eased) * effect.radius
				_fx_layer.draw_arc(effect.position, ring_radius, 0.0, TAU, RangeIndicator.POINT_COUNT,
						Color(1, 1, 1, 0.6 * (1.0 - t)), 2.0, true)
			"dust":
				_fx_layer.draw_circle(effect.position, 3.0 * (1.0 - t) + 1.0, Color(0.62, 0.5, 0.33, 0.8 * (1.0 - t)))
			"text":
				# Bay lên 24px; mờ dần ở 0.3s cuối.
				var fade_start := maxf(0.0, 1.0 - 0.3 / effect.life)
				var alpha := 1.0 if t < fade_start else 1.0 - (t - fade_start) / (1.0 - fade_start)
				_draw_text(_fx_layer, effect.position - Vector2(0, TEXT_RISE * t), effect.text,
						Color(effect.color, alpha), effect.size, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_text(canvas: CanvasItem, at: Vector2, text: String, color: Color, size: int,
		alignment: HorizontalAlignment) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var origin := at - Vector2(width * 0.5, 0) if alignment == HORIZONTAL_ALIGNMENT_CENTER else at
	canvas.draw_string_outline(FONT, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(OUTLINE_DARK, color.a))
	canvas.draw_string(FONT, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * i / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	canvas.draw_colored_polygon(points, color)


# --- Hiệu ứng ngắn --------------------------------------------------------------

func _add_effect(effect: Dictionary) -> void:
	effect["age"] = 0.0
	_effects.append(effect)
	set_process(true)


func _process(delta: float) -> void:
	for effect in _effects:
		effect.age += delta
		if effect.kind == "dust":
			effect.position += effect.velocity * delta
			effect.velocity *= 0.88
	_effects = _effects.filter(func(effect: Dictionary) -> bool: return effect.age < effect.life)
	_fx_layer.queue_redraw()
	if _effects.is_empty():
		set_process(false)


# --- Tạo lớp con ------------------------------------------------------------------

func _make_ring(ring_name: String) -> RangeIndicator:
	var ring := RangeIndicator.new()
	ring.name = ring_name
	add_child(ring)
	return ring


func _make_layer(layer_name: String, z: int, draw_callback: Callable) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	layer.z_index = z
	layer.draw.connect(draw_callback)
	add_child(layer)
	return layer
