class_name HUD
extends Control
## Giao diện trong trận: vàng, mạng sống, wave, xem trước wave sau, tốc độ, tạm dừng,
## nút chọn tháp (kèm tooltip chỉ số), nút bắt đầu / gọi sớm wave,
## bảng thông tin tháp, menu tạm dừng và bảng kết thúc ván.
##
## HUD tự lắng nghe GameManager để cập nhật số liệu (chỉ theo sự kiện, không cập nhật mỗi frame).
## Các hành động của người chơi được phát ra bằng signal; Main nối chúng tới hệ thống tương ứng.
##
## Giao diện dùng theme riêng res://resources/ui/hud_theme.tres (màu, font, style nút 5 trạng thái).
## Hiệu ứng nhỏ (hover, nảy số, nhấp nháy) nằm trong UiFx để dùng lại được ở nơi khác.

signal start_wave_pressed
signal tower_selected(tower_data: TowerData)
signal restart_pressed
signal next_level_pressed
signal level_select_pressed
signal speed_pressed
signal pause_pressed
signal ability_pressed(ability: AbilityData)
signal tutorial_skip_pressed

const MESSAGE_DURATION := 1.6
## Thời gian số vàng "chạy" tới giá trị mới.
const GOLD_COUNT_TIME := 0.35
## Dưới tỉ lệ máu này thì trái tim đập liên tục để cảnh báo.
const LOW_LIVES_RATIO := 0.25

## Token màu theo bảng màu của HUD (khớp với hud_theme.tres).
const COLOR_GOLD := Color("#FFC72C")
const COLOR_DANGER := Color("#E63946")
const COLOR_SUCCESS := Color("#38B000")
const COLOR_WAVE := Color("#4EA8DE")
const COLOR_RETRY := Color("#F77F00")

# --- Top bar
@onready var gold_label: Label = %GoldLabel
@onready var gold_icon: HudIcon = %GoldIcon
@onready var lives_label: Label = %LivesLabel
@onready var lives_icon: HudIcon = %LivesIcon
@onready var lives_bar: ProgressBar = %LivesBar
@onready var wave_label: Label = %WaveLabel
@onready var next_wave_label: Label = %NextWaveLabel
@onready var start_wave_button: Button = %StartWaveButton
@onready var speed_button: Button = %SpeedButton
@onready var pause_button: Button = %PauseButton
# --- Thanh dưới
@onready var tower_buttons: HBoxContainer = %TowerButtons
@onready var ability_buttons: HBoxContainer = %AbilityButtons
# --- Bảng kết thúc
@onready var game_over_panel: Control = %GameOverPanel
@onready var game_over_dim: ColorRect = %Dim
@onready var result_card: PanelContainer = %ResultCard
@onready var result_icon: HudIcon = %ResultIcon
@onready var result_label: Label = %ResultLabel
@onready var result_detail: Label = %ResultDetail
@onready var result_stars: StarRating = %ResultStars
@onready var stat_a_caption: Label = %StatACaption
@onready var stat_a_value: Label = %StatAValue
@onready var stat_b_caption: Label = %StatBCaption
@onready var stat_b_value: Label = %StatBValue
@onready var next_level_button: Button = %NextLevelButton
@onready var restart_button: Button = %RestartButton
@onready var level_select_button: Button = %LevelSelectButton
# --- Lớp phủ khác
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var message_label: Label = %MessageLabel
@onready var tower_info_panel: TowerInfoPanel = %TowerInfoPanel
@onready var boss_bar: BossBar = %BossBar
## Khối thưởng cuối ván (xu, KN, vật phẩm), dựng bằng code và chèn vào thẻ kết quả.
var reward_summary: RewardSummary
@onready var settings_menu: SettingsMenu = %SettingsMenu
@onready var tutorial_panel: PanelContainer = %TutorialPanel
@onready var tutorial_step_label: Label = %TutorialStepLabel
@onready var tutorial_text_label: Label = %TutorialTextLabel
@onready var tutorial_skip_button: Button = %TutorialSkipButton

var _buttons_by_tower: Dictionary = {} # TowerData -> Button
var _buttons_by_ability: Dictionary = {} # AbilityData -> Button
var _message_tween: Tween
var _gold_tween: Tween
var _lives_bar_tween: Tween
var _heartbeat_tween: Tween
## Giá trị vàng đang hiển thị (chạy dần tới GameManager.gold).
var _shown_gold: float = 0.0
var _shown_lives: int = 0
## Hiệu ứng số liệu chỉ bật sau frame đầu, để lúc vào màn (GameManager.reset) không nhấp nháy.
var _animate_changes := false


func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.game_speed_changed.connect(update_speed)
	start_wave_button.pressed.connect(start_wave_pressed.emit)
	restart_button.pressed.connect(restart_pressed.emit)
	next_level_button.pressed.connect(next_level_pressed.emit)
	level_select_button.pressed.connect(level_select_pressed.emit)
	speed_button.pressed.connect(speed_pressed.emit)
	pause_button.pressed.connect(pause_pressed.emit)
	tutorial_skip_button.pressed.connect(tutorial_skip_pressed.emit)

	# Hiệu ứng hover / nhấn cho mọi nút có sẵn trong HUD (kể cả menu tạm dừng, bảng tháp...).
	for node in find_children("*", "BaseButton", true, false):
		if not node is CheckBox and not node is CheckButton:
			UiFx.setup_button(node)

	reward_summary = RewardSummary.new()
	var stats_row := result_card.find_child("Stats", true, false)
	stats_row.add_sibling(reward_summary)

	game_over_panel.hide()
	message_label.modulate.a = 0.0
	_on_gold_changed(GameManager.gold)
	_on_lives_changed(GameManager.lives)
	_on_wave_changed(GameManager.current_wave, GameManager.total_waves)
	update_speed(GameManager.game_speed)
	set_deferred("_animate_changes", true)


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
		button.theme_type_variation = &"DockButton"
		button.custom_minimum_size = Vector2(124, 52)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = TowerStats.tooltip(tower_data)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(tower_selected.emit.bind(tower_data))
		tower_buttons.add_child(button)
		UiFx.setup_button(button)
		_buttons_by_tower[tower_data] = button
	_update_tower_buttons()


## Tạo một nút cho mỗi kỹ năng chủ động.
func setup_ability_buttons(abilities: Array[AbilityData]) -> void:
	for child in ability_buttons.get_children():
		child.queue_free()
	_buttons_by_ability.clear()
	for ability in abilities:
		var button := Button.new()
		button.icon = _make_color_icon(ability.color)
		button.theme_type_variation = &"DockButton"
		button.custom_minimum_size = Vector2(124, 52)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = "%s  [%s]\n%s\nHồi chiêu: %ds" % [ability.display_name,
				OS.get_keycode_string(ability.hotkey), ability.description, roundi(ability.cooldown)]
		button.pressed.connect(func() -> void:
			button.set_pressed_no_signal(false)
			ability_pressed.emit(ability))
		ability_buttons.add_child(button)
		UiFx.setup_button(button)
		_buttons_by_ability[ability] = button
		update_ability_cooldown(ability, 0.0)


## Cập nhật nút kỹ năng: hiện số giây còn hồi, hoặc "Sẵn sàng".
func update_ability_cooldown(ability: AbilityData, remaining: float) -> void:
	var button: Button = _buttons_by_ability.get(ability)
	if button == null:
		return
	var status := "Sẵn sàng" if remaining <= 0.0 else "Hồi %ds" % ceili(remaining)
	button.text = "[%s] %s\n%s" % [OS.get_keycode_string(ability.hotkey), ability.display_name, status]
	button.disabled = remaining > 0.0


## Đánh dấu nút kỹ năng đang ngắm (null = không ngắm).
func set_targeting_ability(ability: AbilityData) -> void:
	for data: AbilityData in _buttons_by_ability:
		_buttons_by_ability[data].set_pressed_no_signal(data == ability)


## Đánh dấu nút của loại tháp đang được chọn (null = không chọn).
func set_selected_tower(tower_data: TowerData) -> void:
	for data: TowerData in _buttons_by_tower:
		_buttons_by_tower[data].set_pressed_no_signal(data == tower_data)


## Cập nhật nút wave. Khi wave trước vẫn còn địch (is_early_call) thì nút thành "Gọi sớm"
## và đổi sang màu vàng (thưởng thêm vàng).
func update_wave_button(can_start: bool, next_wave_number: int, has_more_waves: bool,
		is_early_call: bool = false, early_bonus: int = 0) -> void:
	start_wave_button.disabled = not can_start
	start_wave_button.theme_type_variation = &"PrimaryButton"
	if not has_more_waves:
		start_wave_button.text = "Đã hết wave"
	elif not can_start:
		start_wave_button.text = "Địch đang xuất hiện..."
	elif is_early_call:
		# Đang nghỉ giữa wave: early_bonus = số giây còn lại trước khi wave sau tự bắt đầu.
		start_wave_button.text = "Wave %d sau %ds · Gọi sớm +%d" % [next_wave_number, early_bonus, early_bonus]
		# Nút gọi sớm dùng màu vàng (token "gold economy") để báo có thưởng.
		start_wave_button.theme_type_variation = &"GoldButton"
	else:
		start_wave_button.text = "Bắt đầu Wave %d  [Space]" % next_wave_number


## Hiện thành phần wave sắp tới, vd "Wave 4: 5× Bọc thép, 8× Lính thường".
## test_label khác rỗng: wave kiểm tra (vd "Wave giáp nặng"), tô màu cam để báo trước.
func set_next_wave_preview(wave_number: int, composition: Array[Dictionary], test_label: String = "") -> void:
	if test_label.is_empty():
		next_wave_label.remove_theme_color_override("font_color")
	else:
		next_wave_label.add_theme_color_override("font_color", COLOR_RETRY)
	if composition.is_empty():
		next_wave_label.text = "Không còn wave nào"
		next_wave_label.tooltip_text = ""
		return
	var parts := PackedStringArray()
	for entry in composition:
		parts.append("%d× %s" % [entry.count, entry.data.display_name])
	next_wave_label.text = ("%s: %s" % [test_label, ", ".join(parts)]) if not test_label.is_empty() \
			else "Tiếp: %s" % ", ".join(parts)
	next_wave_label.tooltip_text = "Wave %d: %s" % [wave_number, ", ".join(parts)]


func update_speed(speed: float) -> void:
	speed_button.text = "x%d [F]" % roundi(speed)


## Hiện thông báo ngắn ở cuối màn hình rồi mờ dần.
func show_message(text: String, color: Color = Color(1.0, 0.45, 0.45)) -> void:
	message_label.text = text
	message_label.modulate = color
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_DURATION)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)


## Bảng kết thúc màn: kết quả, số sao, máu còn lại và các nút điều hướng.
func show_game_over(victory: bool, stars: int, lives: int, max_lives: int, has_next_level: bool) -> void:
	if victory:
		result_label.text = "CHIẾN THẮNG!"
		result_detail.text = "Bạn đã giữ vững nhà chính qua mọi đợt tấn công."
		_style_result(HudIcon.Kind.TROPHY, COLOR_GOLD, COLOR_SUCCESS)
	else:
		result_label.text = "THẤT BẠI"
		result_detail.text = "Nhà chính đã thất thủ ở wave %d. Thử đổi cách xếp tháp nhé!" % GameManager.current_wave
		_style_result(HudIcon.Kind.SKULL, COLOR_DANGER, COLOR_DANGER)
	stat_a_caption.text = "MÁU CÒN LẠI"
	stat_a_value.text = "%d / %d" % [lives, max_lives]
	stat_b_caption.text = "WAVE"
	stat_b_value.text = "%d / %d" % [GameManager.current_wave, GameManager.total_waves]
	result_stars.visible = victory
	next_level_button.visible = has_next_level
	_open_result_panel(stars if victory else 0)


## Hiện phần thưởng cuối ván (gọi sau show_game_over / show_endless_over).
func show_match_rewards(rewards: Dictionary) -> void:
	reward_summary.play(rewards)


## Hiện một bước hướng dẫn (text rỗng = ẩn bảng hướng dẫn).
func show_tutorial_step(text: String, step_number: int, step_count: int) -> void:
	tutorial_panel.visible = not text.is_empty()
	tutorial_step_label.text = "HƯỚNG DẪN %d/%d" % [step_number, step_count]
	tutorial_text_label.text = text


## Bảng kết thúc chế độ vô tận: wave đạt được và kỷ lục.
func show_endless_over(wave_reached: int, best_wave: int, new_record: bool) -> void:
	result_label.text = "KỶ LỤC MỚI!" if new_record else "KẾT THÚC"
	result_detail.text = "Trụ được tới wave %d  ·  Kỷ lục: wave %d" % [wave_reached, best_wave]
	_style_result(HudIcon.Kind.FLAG, COLOR_GOLD, COLOR_GOLD if new_record else COLOR_WAVE)
	stat_a_caption.text = "WAVE ĐẠT ĐƯỢC"
	stat_a_value.text = str(wave_reached)
	stat_b_caption.text = "KỶ LỤC"
	stat_b_value.text = str(best_wave)
	result_stars.visible = false
	next_level_button.visible = false
	_open_result_panel(0)


# --- Bảng kết thúc: màu + animation ---------------------------------------------

## Đổi icon, màu tiêu đề và màu viền thẻ theo kết quả (thắng = vàng/xanh, thua = đỏ).
func _style_result(icon_kind: HudIcon.Kind, title_color: Color, accent: Color) -> void:
	result_icon.kind = icon_kind
	result_icon.color = title_color
	result_label.add_theme_color_override("font_color", title_color)
	var card_style := result_card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	card_style.border_color = Color(accent, 0.7)
	result_card.add_theme_stylebox_override("panel", card_style)


## Fade nền tối + thẻ phóng to nảy nhẹ, rồi bật lần lượt từng sao.
## Tween tạo trên game_over_panel (process_mode = ALWAYS) nên vẫn chạy khi game đang pause.
func _open_result_panel(stars: int) -> void:
	game_over_panel.show()
	game_over_dim.modulate.a = 0.0
	result_card.modulate.a = 0.0
	result_card.pivot_offset = result_card.size * 0.5
	result_card.scale = Vector2.ONE * 0.85
	result_stars.stars = 0

	var tween := game_over_panel.create_tween()
	tween.tween_property(game_over_dim, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(result_card, "modulate:a", 1.0, 0.25).set_delay(0.08)
	tween.parallel().tween_property(result_card, "scale", Vector2.ONE, 0.45) \
			.set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in stars:
		tween.tween_interval(0.12)
		tween.tween_callback(func() -> void:
			result_stars.stars = i + 1
			UiFx.pulse(result_stars, 1.25, 0.3))


# --- Số liệu top bar ------------------------------------------------------------

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


## Vàng: số "chạy" tới giá trị mới, nảy nhẹ và loé xanh (tăng) / cam (giảm).
func _on_gold_changed(gold: int) -> void:
	_update_tower_buttons()
	if _gold_tween:
		_gold_tween.kill()
	if not _animate_changes:
		_set_shown_gold(gold)
		return
	var increased := gold > _shown_gold
	_gold_tween = create_tween()
	_gold_tween.tween_method(_set_shown_gold, _shown_gold, float(gold), GOLD_COUNT_TIME) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	UiFx.pulse(gold_label, 1.18 if increased else 1.1)
	UiFx.pulse(gold_icon, 1.15)
	UiFx.flash(gold_label, Color(0.75, 1.0, 0.7) if increased else Color(1.0, 0.7, 0.55), 0.3, 1)


func _set_shown_gold(value: float) -> void:
	_shown_gold = value
	gold_label.text = str(roundi(value))


## Máu: số loé đỏ, tim nảy, thanh máu tụt mượt; máu thấp thì tim đập liên tục.
func _on_lives_changed(lives: int) -> void:
	var max_lives := maxi(GameManager.starting_lives, 1)
	var lost := lives < _shown_lives
	_shown_lives = lives
	lives_label.text = str(lives)
	lives_bar.max_value = max_lives
	if _lives_bar_tween:
		_lives_bar_tween.kill()
	if _animate_changes:
		_lives_bar_tween = create_tween()
		_lives_bar_tween.tween_property(lives_bar, "value", float(lives), 0.4) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if lost:
			UiFx.flash(lives_label, Color(1.0, 0.35, 0.4), 0.5, 2)
			UiFx.pulse(lives_icon, 1.3, 0.3)
	else:
		lives_bar.value = lives
	_update_heartbeat(float(lives) / max_lives)


## Bật / tắt nhịp tim liên tục của icon máu khi máu xuống thấp.
func _update_heartbeat(ratio: float) -> void:
	var low := ratio > 0.0 and ratio <= LOW_LIVES_RATIO
	if low and (_heartbeat_tween == null or not _heartbeat_tween.is_valid()):
		lives_icon.pivot_offset = lives_icon.size * 0.5
		_heartbeat_tween = lives_icon.create_tween().set_loops()
		_heartbeat_tween.tween_property(lives_icon, "scale", Vector2.ONE * 1.2, 0.18)
		_heartbeat_tween.tween_property(lives_icon, "scale", Vector2.ONE, 0.18)
		_heartbeat_tween.tween_interval(0.45)
	elif not low and _heartbeat_tween and _heartbeat_tween.is_valid():
		_heartbeat_tween.kill()
		lives_icon.scale = Vector2.ONE


func _on_wave_changed(current_wave: int, total_waves: int) -> void:
	# total_waves = 0 nghĩa là chế độ vô tận.
	wave_label.text = "Wave %d / %d" % [current_wave, total_waves] if total_waves > 0 \
			else "Wave %d (vô tận)" % current_wave
	if _animate_changes and current_wave > 0:
		UiFx.pulse(wave_label, 1.12)
