class_name TowerInfoPanel
extends PanelContainer
## Bảng thông tin tháp đang chọn: chỉ số (kèm so sánh cấp sau), thống kê,
## cách chọn mục tiêu, nút nâng cấp và bán.
##
## Bảng chỉ HIỂN THỊ và phát signal; Main sẽ nối tới SelectionManager / BuildManager.
## Bảng tự né sang phía bên kia màn hình để không che tháp đang chọn.

## branch: nhánh cấp 4 (0 = A, 1 = B; tháp chưa tới chỗ rẽ nhánh thì luôn 0).
signal upgrade_requested(branch: int)
signal sell_requested
signal target_mode_selected(mode: Tower.TargetMode)
signal close_requested
## Rê chuột vào / ra nút Nâng cấp (để xem trước tầm bắn sau nâng cấp theo nhánh).
signal upgrade_hovered(hovering: bool, branch: int)

## Tên hiển thị, theo đúng thứ tự Tower.TargetMode.
const TARGET_MODE_NAMES := ["Đầu đoàn", "Cuối đoàn", "Gần nhất", "Nhiều máu nhất", "Ít máu nhất"]
const SCREEN_MARGIN := 16.0
const TOP_OFFSET := 72.0

var tower: Tower = null
## Nút nhánh B (dựng bằng code, nằm ngay dưới nút Nâng cấp; chỉ hiện ở chỗ rẽ nhánh).
var branch_b_button: Button

@onready var title_label: Label = %TitleLabel
@onready var level_label: Label = %LevelLabel
@onready var stats_label: Label = %StatsLabel
@onready var record_label: Label = %RecordLabel
@onready var target_option: OptionButton = %TargetOption
@onready var upgrade_button: Button = %UpgradeButton
@onready var sell_button: Button = %SellButton
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	for mode_name in TARGET_MODE_NAMES:
		target_option.add_item(mode_name)
	target_option.item_selected.connect(func(index: int) -> void: target_mode_selected.emit(index))
	branch_b_button = Button.new()
	branch_b_button.custom_minimum_size = upgrade_button.custom_minimum_size
	branch_b_button.theme_type_variation = upgrade_button.theme_type_variation
	upgrade_button.add_sibling(branch_b_button)
	for pair in [[upgrade_button, 0], [branch_b_button, 1]]:
		var button: Button = pair[0]
		var branch: int = pair[1]
		button.pressed.connect(upgrade_requested.emit.bind(branch))
		button.mouse_entered.connect(upgrade_hovered.emit.bind(true, branch))
		button.mouse_exited.connect(upgrade_hovered.emit.bind(false, branch))
	sell_button.pressed.connect(sell_requested.emit)
	close_button.pressed.connect(close_requested.emit)
	hide()


## Hiện thông tin của một tháp (null = ẩn bảng).
func show_tower(p_tower: Tower) -> void:
	tower = p_tower
	if not is_instance_valid(tower):
		tower = null
		hide()
		return
	_refresh()
	show()
	_place_away_from(tower.global_position)


func _process(_delta: float) -> void:
	# Cập nhật liên tục để thống kê, vàng và trạng thái nút luôn đúng.
	if visible and is_instance_valid(tower):
		_refresh()


func _refresh() -> void:
	var data := tower.data
	var next := data.next_level
	var branching := next == null and data.branches.size() >= 2
	title_label.text = data.display_name if data.branch_name.is_empty() else "%s · %s" % [data.display_name, data.branch_name]
	level_label.text = "Cấp %d / %d" % [data.level, TowerStats.max_level(data)]
	var stats := TowerStats.describe(data, next)
	if not data.weakness_text.is_empty():
		stats += "\nĐiểm yếu: " + data.weakness_text
	if tower.get_damage_multiplier() > 1.0:
		stats += "\nĐang được Cờ hiệu buff: +%d%% sát thương" % roundi((tower.get_damage_multiplier() - 1.0) * 100.0)
	stats_label.text = stats
	record_label.text = "Đã hạ: %d địch    Sát thương gây ra: %d" % [tower.kills, roundi(tower.damage_dealt)]
	record_label.visible = data.is_attacker()
	target_option.get_parent().visible = data.is_attacker()
	if target_option.selected != tower.target_mode:
		target_option.select(tower.target_mode)

	branch_b_button.visible = branching
	if next:
		_set_upgrade_button(upgrade_button, next, "Nâng cấp: %d vàng  [U]" % next.cost)
	elif branching:
		_set_upgrade_button(upgrade_button, data.branches[0], "A · %s: %d vàng  [U]" % [data.branches[0].branch_name, data.branches[0].cost])
		_set_upgrade_button(branch_b_button, data.branches[1], "B · %s: %d vàng  [Shift+U]" % [data.branches[1].branch_name, data.branches[1].cost])
	else:
		upgrade_button.text = "Đã đạt cấp tối đa"
		upgrade_button.tooltip_text = ""
		upgrade_button.disabled = true
	if tower.is_refundable_in_full():
		sell_button.text = "Hoàn tác: +%d vàng  [X]" % tower.get_sell_value()
	else:
		sell_button.text = "Bán: +%d vàng  [X]" % tower.get_sell_value()


## Nút nâng cấp: chữ, khoá khi thiếu vàng, tooltip so sánh chỉ số (+ điểm yếu của nhánh).
func _set_upgrade_button(button: Button, next: TowerData, text: String) -> void:
	button.text = text
	button.disabled = not GameManager.can_afford(next.cost)
	var tooltip := TowerStats.describe(tower.data, next)
	if not next.weakness_text.is_empty():
		tooltip += "\nĐiểm yếu: " + next.weakness_text
	button.tooltip_text = tooltip


## Đặt bảng ở nửa màn hình không chứa tháp.
func _place_away_from(world_position: Vector2) -> void:
	reset_size()
	var screen_width := get_viewport_rect().size.x
	var x := SCREEN_MARGIN if world_position.x > screen_width * 0.5 else screen_width - size.x - SCREEN_MARGIN
	position = Vector2(x, TOP_OFFSET)
