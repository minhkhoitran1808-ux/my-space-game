extends Node
## InventoryManager (Autoload): kho vật phẩm meta.
##
## Hồ sơ "inventory":
##   stacks    {item_id: số lượng}       (skin luôn là 0/1)
##   new       {item_id: true}           (chấm NEW trong Kho đồ, xoá khi đã xem)
##   equipped  {tower_id: item_id}       (skin đang dùng cho từng loại tháp)
##   prepared  [item_id, ...]            (đồ tiêu hao sẽ dùng ở ván kế tiếp)
##
## Mọi thay đổi đi qua grant() / consume() / salvage() kèm "reason" (giống EconomyManager).
## Đồ rơi cuối ván: 1 món, thắng thêm 1 món; độ hiếm chọn theo Rarity.DROP_WEIGHTS.

const ITEMS_FOLDER := "res://resources/items"
## Tối đa số đồ tiêu hao chuẩn bị cho một ván.
const MAX_PREPARED := 2
## Vô tận: thêm 1 món mỗi chừng này wave (tối đa ENDLESS_MAX_DROPS món).
const ENDLESS_WAVES_PER_DROP := 10
const ENDLESS_MAX_DROPS := 3

## id -> ItemDef
var defs: Dictionary = {}
## RNG cho đồ rơi (test có thể đặt seed).
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	for file_name in ResourceLoader.list_directory(ITEMS_FOLDER):
		if not file_name.ends_with(".tres"):
			continue
		var def := load(ITEMS_FOLDER.path_join(file_name)) as ItemDef
		if def == null or def.id == &"":
			push_warning("InventoryManager: bỏ qua '%s'." % file_name)
			continue
		assert(not defs.has(def.id), "Trùng id vật phẩm: %s" % def.id)
		defs[def.id] = def
	rng.randomize()


func get_def(item_id: StringName) -> ItemDef:
	return defs.get(item_id)


func count(item_id: StringName) -> int:
	return SaveManager.read_int(_section("stacks"), String(item_id))


func owns(item_id: StringName) -> bool:
	return count(item_id) > 0


## Các vật phẩm đang có (đã sắp xếp: độ hiếm giảm dần rồi tên).
func get_owned(kind: int = -1) -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for id in _section("stacks"):
		var def: ItemDef = defs.get(StringName(id))
		if def and count(def.id) > 0 and (kind < 0 or def.kind == kind):
			list.append(def)
	list.sort_custom(_compare_items)
	return list


## Mọi vật phẩm trong game (cho Codex / cửa hàng), sắp xếp như get_owned().
func get_all(kind: int = -1) -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for def: ItemDef in defs.values():
		if kind < 0 or def.kind == kind:
			list.append(def)
	list.sort_custom(_compare_items)
	return list


## Nhận vật phẩm. Skin đã có thì tự đổi thành Bụi.
## Trả về {"item": ItemDef, "duplicate": bool, "dust": int}.
func grant(item_id: StringName, amount: int, reason: String) -> Dictionary:
	var def := get_def(item_id)
	assert(def != null, "Vật phẩm không tồn tại: %s" % item_id)
	if def == null or amount <= 0:
		return {}
	if not def.is_stackable() and owns(item_id):
		var dust: int = Rarity.DUST_VALUES[def.rarity] * amount
		EconomyManager.add(EconomyManager.DUST, dust, "duplicate_%s" % item_id)
		return {"item": def, "duplicate": true, "dust": dust}
	var stacks := _section("stacks")
	stacks[String(item_id)] = 1 if not def.is_stackable() else count(item_id) + amount
	_section("new")[String(item_id)] = true
	_log(item_id, amount, reason)
	SaveManager.request_save()
	Events.item_granted.emit(item_id, amount)
	return {"item": def, "duplicate": false, "dust": 0}


## Bớt vật phẩm nếu đủ. Trả về true nếu thành công.
func consume(item_id: StringName, amount: int, reason: String) -> bool:
	if amount <= 0 or count(item_id) < amount:
		return false
	var left := count(item_id) - amount
	var stacks := _section("stacks")
	if left > 0:
		stacks[String(item_id)] = left
	else:
		stacks.erase(String(item_id))
		_section("new").erase(String(item_id))
		_unequip_item(item_id)
		_prepared().erase(String(item_id))
	_log(item_id, -amount, reason)
	SaveManager.request_save()
	return true


## Phân rã vật phẩm thành Bụi. Trả về lượng Bụi nhận được (0 nếu không đủ đồ).
func salvage(item_id: StringName, amount: int = 1) -> int:
	var def := get_def(item_id)
	if def == null or not consume(item_id, amount, "salvage"):
		return 0
	var dust: int = Rarity.DUST_VALUES[def.rarity] * amount
	EconomyManager.add(EconomyManager.DUST, dust, "salvage_%s" % item_id)
	return dust


# --- Skin --------------------------------------------------------------------------

func equip_skin(item_id: StringName) -> bool:
	var def := get_def(item_id)
	if def == null or def.kind != ItemDef.Kind.SKIN or not owns(item_id):
		return false
	_section("equipped")[String(def.tower_id)] = String(item_id)
	SaveManager.request_save()
	return true


func unequip_skin(tower_id: StringName) -> void:
	_section("equipped").erase(String(tower_id))
	SaveManager.request_save()


## Skin đang dùng cho một loại tháp (null = mặc định).
func get_equipped_skin(tower_id: StringName) -> ItemDef:
	var item_id: Variant = _section("equipped").get(String(tower_id))
	if item_id == null or not owns(StringName(item_id)):
		return null
	return get_def(StringName(item_id))


func is_equipped(item_id: StringName) -> bool:
	var def := get_def(item_id)
	return def != null and get_equipped_skin(def.tower_id) == def


# --- Đồ tiêu hao -------------------------------------------------------------------

func get_prepared() -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for id in _prepared():
		var def := get_def(StringName(id))
		if def and owns(def.id):
			list.append(def)
	return list


func is_prepared(item_id: StringName) -> bool:
	return String(item_id) in _prepared()


## Bật / tắt "dùng ở ván sau" cho một món tiêu hao. Trả về trạng thái mới.
func toggle_prepared(item_id: StringName) -> bool:
	var prepared := _prepared()
	if is_prepared(item_id):
		prepared.erase(String(item_id))
	else:
		var def := get_def(item_id)
		if def == null or def.kind != ItemDef.Kind.CONSUMABLE or not owns(item_id) or prepared.size() >= MAX_PREPARED:
			return false
		prepared.append(String(item_id))
	SaveManager.request_save()
	return is_prepared(item_id)


## Gọi khi bắt đầu ván: tiêu thụ các món đã chuẩn bị và trả về tổng hiệu ứng
## {"bonus_gold_pct": float, "bonus_lives": float, "names": [String]}.
func use_prepared() -> Dictionary:
	var effects := {"bonus_gold_pct": 0.0, "bonus_lives": 0.0, "names": []}
	for def in get_prepared():
		if consume(def.id, 1, "used_in_match"):
			effects[String(def.effect)] = effects.get(String(def.effect), 0.0) + def.effect_value
			effects.names.append(def.display_name)
	# Món nào đã dùng hết thì bỏ khỏi danh sách chuẩn bị.
	for id in _prepared().duplicate():
		if not owns(StringName(id)):
			_prepared().erase(id)
	return effects


# --- Đồ rơi ------------------------------------------------------------------------

## Chọn ngẫu nhiên một vật phẩm rơi được (bậc theo trọng số; bậc không có đồ thì lùi xuống).
func roll_drop(luck: float = 0.0) -> ItemDef:
	var tier := Rarity.roll(rng, luck)
	while tier >= 0:
		var pool: Array[ItemDef] = []
		for def: ItemDef in defs.values():
			if def.droppable and def.rarity == tier:
				pool.append(def)
		if not pool.is_empty():
			return pool[rng.randi_range(0, pool.size() - 1)]
		tier -= 1
	return null


## Thưởng đồ cuối ván. Trả về danh sách kết quả grant() (để bảng kết quả hiển thị).
func grant_match_drops(result: Dictionary) -> Array[Dictionary]:
	var drop_count := 1
	var luck := 0.0
	if result.endless:
		drop_count += mini(int(result.waves_survived / ENDLESS_WAVES_PER_DROP), ENDLESS_MAX_DROPS - 1)
		luck = minf(result.waves_survived / 30.0, 1.0)
	elif result.won:
		drop_count += 1
		luck = 0.3
	if result.waves_survived == 0 and not result.won:
		return []
	var drops: Array[Dictionary] = []
	for i in drop_count:
		var def := roll_drop(luck)
		if def:
			drops.append(grant(def.id, 1, "match_drop"))
	return drops


# --- NEW ---------------------------------------------------------------------------

func is_new(item_id: StringName) -> bool:
	return _section("new").has(String(item_id))


func mark_seen(item_id: StringName) -> void:
	if _section("new").erase(String(item_id)):
		SaveManager.request_save()


func get_new_count() -> int:
	return _section("new").size()


# --- Nội bộ ------------------------------------------------------------------------

func _section(key: String) -> Dictionary:
	var inventory := SaveManager.section("inventory")
	if not inventory.get(key) is Dictionary:
		inventory[key] = {}
	return inventory[key]


func _prepared() -> Array:
	var inventory := SaveManager.section("inventory")
	if not inventory.get("prepared") is Array:
		inventory["prepared"] = []
	return inventory["prepared"]


func _unequip_item(item_id: StringName) -> void:
	var equipped := _section("equipped")
	for tower_id in equipped.keys():
		if equipped[tower_id] == String(item_id):
			equipped.erase(tower_id)


func _log(item_id: StringName, delta: int, reason: String) -> void:
	var inventory := SaveManager.section("inventory")
	var log: Array = inventory.get("log", [])
	log.append({"item": String(item_id), "delta": delta, "reason": reason})
	if log.size() > EconomyManager.LOG_SIZE:
		log = log.slice(log.size() - EconomyManager.LOG_SIZE)
	inventory["log"] = log


func _compare_items(a: ItemDef, b: ItemDef) -> bool:
	if a.rarity != b.rarity:
		return a.rarity > b.rarity
	if a.kind != b.kind:
		return a.kind < b.kind
	return a.display_name < b.display_name
