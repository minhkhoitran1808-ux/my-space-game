class_name TowerInfoPanel
extends PanelContainer
## Bảng thông tin tháp đang chọn: chỉ số (kèm so sánh cấp sau), thống kê,
## cách chọn mục tiêu, nút nâng cấp và bán.
##
## Bảng chỉ HIỂN THỊ và phát signal; Main sẽ nối tới SelectionManager / BuildManager.
## Bảng tự né sang phía bên kia màn hình để không che tháp đang chọn.

signal upgrade_requested
signal sell_requested
signal target_mode_selected(mode: Tower.TargetMode)
signal close_requested
## Rê chuột vào / ra nút Nâng cấp (để xem trước tầm bắn sau nâng cấp).
signal upgrade_hovered(hovering: bool)

## Tên hiển thị, theo đúng thứ tự Tower.TargetMode.
const TARGET_MODE_NAMES := ["Đầu đoàn", "Cuối đoàn", "Gần nhất", "Nhiều máu nhất"]
const SCREEN_MARGIN := 16.0
const TOP_OFFSET := 72.0

var tower: Tower = null

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
	upgrade_button.pressed.connect(upgrade_requested.emit)
	upgrade_button.mouse_entered.connect(upgrade_hovered.emit.bind(true))
	upgrade_button.mouse_exited.connect(upgrade_hovered.emit.bind(false))
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
	title_label.text = data.display_name
	level_label.text = "Cấp %d / %d" % [data.level, TowerStats.max_level(data)]
	stats_label.text = TowerStats.describe(data, next)
	record_label.text = "Đã hạ: %d địch    Sát thương gây ra: %d" % [tower.kills, roundi(tower.damage_dealt)]
	if target_option.selected != tower.target_mode:
		target_option.select(tower.target_mode)

	if next:
		upgrade_button.text = "Nâng cấp: %d vàng  [U]" % next.cost
		upgrade_button.disabled = not GameManager.can_afford(next.cost)
	else:
		upgrade_button.text = "Đã đạt cấp tối đa"
		upgrade_button.disabled = true
	sell_button.text = "Bán: +%d vàng  [X]" % tower.get_sell_value()


## Đặt bảng ở nửa màn hình không chứa tháp.
func _place_away_from(world_position: Vector2) -> void:
	reset_size()
	var screen_width := get_viewport_rect().size.x
	var x := SCREEN_MARGIN if world_position.x > screen_width * 0.5 else screen_width - size.x - SCREEN_MARGIN
	position = Vector2(x, TOP_OFFSET)
