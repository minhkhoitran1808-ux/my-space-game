class_name HUD
extends Control
## Giao diện trong trận: vàng, mạng sống, wave, nút chọn tháp (kèm tooltip chỉ số),
## nút bắt đầu wave, bảng thông tin tháp và bảng kết thúc ván.
##
## HUD tự lắng nghe GameManager để cập nhật số liệu. Các hành động của người chơi
## được phát ra bằng signal; Main sẽ nối chúng tới hệ thống tương ứng.

signal start_wave_pressed
signal tower_selected(tower_data: TowerData)
signal restart_pressed

const MESSAGE_DURATION := 1.6

@onready var gold_label: Label = %GoldLabel
@onready var lives_label: Label = %LivesLabel
@onready var wave_label: Label = %WaveLabel
@onready var tower_buttons: HBoxContainer = %TowerButtons
@onready var start_wave_button: Button = %StartWaveButton
@onready var message_label: Label = %MessageLabel
@onready var game_over_panel: PanelContainer = %GameOverPanel
@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton
@onready var tower_info_panel: TowerInfoPanel = %TowerInfoPanel

var _buttons_by_tower: Dictionary = {} # TowerData -> Button
var _message_tween: Tween


func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	start_wave_button.pressed.connect(start_wave_pressed.emit)
	restart_button.pressed.connect(restart_pressed.emit)

	game_over_panel.hide()
	message_label.modulate.a = 0.0
	_on_gold_changed(GameManager.gold)
	_on_lives_changed(GameManager.lives)
	_on_wave_changed(GameManager.current_wave, GameManager.total_waves)


## Tạo một nút cho mỗi loại tháp có thể xây.
func setup_tower_buttons(towers: Array[TowerData]) -> void:
	for child in tower_buttons.get_children():
		child.queue_free()
	_buttons_by_tower.clear()

	for i in towers.size():
		var tower_data := towers[i]
		var button := Button.new()
		button.text = "[%d] %s\n%d vàng" % [i + 1, tower_data.display_name, tower_data.cost]
		button.icon = _make_color_icon(tower_data.color)
		button.custom_minimum_size = Vector2(150, 0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = TowerStats.tooltip(tower_data)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(tower_selected.emit.bind(tower_data))
		tower_buttons.add_child(button)
		_buttons_by_tower[tower_data] = button
	_update_tower_buttons()


## Đánh dấu nút của loại tháp đang được chọn (null = không chọn).
func set_selected_tower(tower_data: TowerData) -> void:
	for data: TowerData in _buttons_by_tower:
		_buttons_by_tower[data].set_pressed_no_signal(data == tower_data)


func update_wave_button(can_start: bool, next_wave_number: int, has_more_waves: bool) -> void:
	start_wave_button.disabled = not can_start
	if not has_more_waves:
		start_wave_button.text = "Đã hết wave"
	elif can_start:
		start_wave_button.text = "Bắt đầu Wave %d [Space]" % next_wave_number
	else:
		start_wave_button.text = "Wave đang diễn ra..."


## Hiện thông báo ngắn ở cuối màn hình rồi mờ dần.
func show_message(text: String, color: Color = Color(1.0, 0.45, 0.45)) -> void:
	message_label.text = text
	message_label.modulate = color
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_DURATION)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)


func show_game_over(victory: bool) -> void:
	result_label.text = "CHIẾN THẮNG!" if victory else "THẤT BẠI!"
	result_label.modulate = Color(0.5, 1.0, 0.5) if victory else Color(1.0, 0.4, 0.4)
	game_over_panel.show()


## Tạo icon tròn đơn sắc cho nút tháp (tạm thời, thay bằng sprite khi có asset).
func _make_color_icon(color: Color, size: int = 22) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= size * 0.5 - 1.0:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _update_tower_buttons() -> void:
	# Làm mờ các tháp không đủ tiền (vẫn bấm được để chọn trước).
	for data: TowerData in _buttons_by_tower:
		_buttons_by_tower[data].modulate.a = 1.0 if GameManager.can_afford(data.cost) else 0.5


func _on_gold_changed(gold: int) -> void:
	gold_label.text = "Vàng: %d" % gold
	_update_tower_buttons()


func _on_lives_changed(lives: int) -> void:
	lives_label.text = "Máu: %d" % lives


func _on_wave_changed(current_wave: int, total_waves: int) -> void:
	wave_label.text = "Wave: %d/%d" % [current_wave, total_waves]
