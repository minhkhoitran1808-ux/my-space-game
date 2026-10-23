extends Control
## Màn chọn màn: mỗi màn trong LevelCatalog là một thẻ (tên, sao, mô tả, thông tin, nút chơi).
## Màn bị khoá cho tới khi màn trước có ít nhất 1 sao. Qua một màn thì mở chế độ vô tận của màn đó.

const CARD_SIZE := Vector2(360, 370)
## Thẻ co lại khi có nhiều màn để vẫn nằm vừa một hàng (lề màn hình 40px mỗi bên, khe 24px).
const SCREEN_MARGIN := 40.0
const CARD_GAP := 24.0

@onready var cards_container: HBoxContainer = %Cards
@onready var back_button: Button = %BackButton

## Nút "Chơi" của từng màn, theo thứ tự trong catalog (test dùng để bấm thử).
var play_buttons: Array[Button] = []
## Nút "Vô tận" của từng màn, theo thứ tự trong catalog.
var endless_buttons: Array[Button] = []


func _ready() -> void:
	back_button.pressed.connect(GameManager.go_to_main_menu)
	_build_cards()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		GameManager.go_to_main_menu()
		get_viewport().set_input_as_handled()


func _build_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	play_buttons.clear()
	endless_buttons.clear()
	var catalog := GameManager.LEVEL_CATALOG
	for index in catalog.levels.size():
		cards_container.add_child(_create_card(catalog.levels[index], index,
				SaveManager.is_level_unlocked(catalog, index)))
	if not play_buttons.is_empty():
		play_buttons[0].grab_focus()


func _create_card(level: LevelData, index: int, unlocked: bool) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_card_width(), CARD_SIZE.y)
	card.modulate.a = 1.0 if unlocked else 0.55

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "%d. %s" % [index + 1, level.display_name]
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	var stars := StarRating.new()
	stars.stars = SaveManager.get_stars(level.id)
	stars.star_size = 30.0
	stars.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(stars)

	var description := Label.new()
	description.text = level.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	box.add_child(description)

	var info := Label.new()
	info.text = "%d wave  ·  %d vàng\n%d máu  ·  %d làn đường" % [level.get_wave_count(),
			level.starting_gold, level.starting_lives, _count_lanes(level)]
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	box.add_child(info)

	var play := Button.new()
	play.custom_minimum_size = Vector2(0, 46)
	play.disabled = not unlocked
	if not unlocked:
		play.text = "Khoá - hãy qua màn trước"
	elif stars.stars > 0:
		play.text = "Chơi lại"
	else:
		play.text = "Chơi"
	play.pressed.connect(GameManager.start_level.bind(level, false))
	box.add_child(play)
	play_buttons.append(play)

	var endless := Button.new()
	endless.custom_minimum_size = Vector2(0, 36)
	endless.disabled = stars.stars == 0
	var best := SaveManager.get_endless_best(level.id)
	if endless.disabled:
		endless.text = "Vô tận - qua màn này để mở"
	elif best > 0:
		endless.text = "Vô tận  (kỷ lục: wave %d)" % best
	else:
		endless.text = "Vô tận"
	endless.pressed.connect(GameManager.start_level.bind(level, true))
	box.add_child(endless)
	endless_buttons.append(endless)
	return card


## Bề rộng thẻ: tối đa CARD_SIZE.x, nhỏ hơn nếu số màn nhiều tới mức không vừa một hàng.
func _card_width() -> float:
	var count := maxi(GameManager.LEVEL_CATALOG.levels.size(), 1)
	var available := get_viewport_rect().size.x - SCREEN_MARGIN * 2.0 - CARD_GAP * (count - 1)
	return minf(CARD_SIZE.x, floorf(available / count))


func _count_lanes(level: LevelData) -> int:
	var map := level.map_scene.instantiate() as GameMap
	var lanes := map.get_node("Paths").get_child_count()
	map.free()
	return lanes
