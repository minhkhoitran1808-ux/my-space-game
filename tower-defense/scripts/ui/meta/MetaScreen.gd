class_name MetaScreen
extends Control
## Khung chung cho các màn hình meta (Thành tựu, Kho đồ, Cửa hàng, Codex, Nhiệm vụ):
## nền tối phủ màn hình + thẻ giữa màn hình có tiêu đề, vùng nút phụ, nút Đóng [Esc]
## và vùng nội dung. Lớp con dựng nội dung trong _build_content() và vẽ lại trong refresh().
## Chỉ một lớp modal; dựng hoàn toàn bằng code và dùng theme HUD (nút, thẻ, nhãn).

signal closed

const HUD_THEME := preload("res://resources/ui/hud_theme.tres")
const PANEL_SIZE := Vector2(980, 620)
const COLOR_GOLD := Color("#FFC72C")
const COLOR_MUTED := Color(1, 1, 1, 0.65)

var title_label: Label
## Vùng nút / thông tin phụ ở bên phải tiêu đề.
var header_extra: HBoxContainer
var close_button: Button
## Vùng nội dung chính (lớp con thêm node vào đây).
var content: VBoxContainer


func _ready() -> void:
	theme = HUD_THEME
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ModalPanel"
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)
	title_label = make_label("", 28)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	header_extra = HBoxContainer.new()
	header_extra.add_theme_constant_override("separation", 10)
	header.add_child(header_extra)
	close_button = make_button("Đóng  [Esc]")
	close_button.pressed.connect(close)
	header.add_child(close_button)

	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	box.add_child(content)
	_build_content()
	hide()


## Mở màn hình (vẽ lại nội dung theo hồ sơ hiện tại).
func open() -> void:
	refresh()
	show()


func close() -> void:
	hide()
	closed.emit()


## Lớp con: dựng các node cố định một lần.
func _build_content() -> void:
	pass


## Lớp con: cập nhật nội dung theo dữ liệu hiện tại.
func refresh() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


# --- Tiện ích dựng UI ----------------------------------------------------------------

static func make_label(text: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	return label


static func make_button(text: String, variation: StringName = &"") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 38)
	if variation != &"":
		button.theme_type_variation = variation
	UiFx.setup_button(button)
	return button


## Nền thẻ tối có viền màu (viền trái dày hơn làm "dải màu" phân loại).
static func card_style(accent: Color, background: Color = Color(0.09, 0.11, 0.16, 1.0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = accent
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


## Thanh tiến độ mảnh vẽ tay (ratio 0..1).
static func make_progress_bar(ratio: float, color: Color, height: float = 8.0) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.draw.connect(func() -> void:
		var rect := Rect2(Vector2.ZERO, bar.size)
		bar.draw_rect(rect, Color(0, 0, 0, 0.45))
		bar.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), color)
		bar.draw_rect(rect, Color(1, 1, 1, 0.12), false, 1.0))
	return bar


## Danh sách cuộn dọc; trả về VBox bên trong để thêm thẻ.
static func make_scroll_list(parent: Control) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	return list


## Xoá mọi node con (dùng khi vẽ lại danh sách).
static func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
