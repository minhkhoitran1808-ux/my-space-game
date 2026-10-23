extends Node
## ShopManager (Autoload): mọi chỗ tiêu Xu / Bụi / vật phẩm ngoài trận ("sink" của kinh tế).
##
## - Thương nhân NPC: đổi đồ theo công thức cố định (MerchantRecipe).
## - Ghép đồ: 5 món tiêu hao / nguyên liệu cùng bậc -> 1 món ngẫu nhiên bậc kế tiếp.
## - Cửa hàng hôm nay: 4 món, giá cố định theo bậc, đổi mới mỗi ngày (theo ngày hệ thống).
##   KHÔNG có cách trả tiền để đổi hàng sớm.
## - Nâng cấp vĩnh viễn: giá tăng dần (300 × 1.15^cấp) nhưng có GIỚI HẠN để màn chơi không
##   trở nên quá dễ: tối đa +10% vàng đầu ván và +2 máu nhà chính.
## Không có gì bán bằng tiền thật, không có vật phẩm ngẫu nhiên trả phí.

const RECIPES_FOLDER := "res://resources/merchant"
const FUSE_COUNT := 5
const SHOP_SLOTS := 4
## Giá cửa hàng theo bậc (Xu).
const SHOP_PRICES := [150, 300, 600, 1500, 4000]
const UPGRADE_BASE_COST := 300.0
const UPGRADE_COST_GROWTH := 1.15
## id -> {name, description, max_level, per_level, effect}
const UPGRADES := {
	&"treasury": {"name": "Kho bạc", "description": "+2% vàng đầu ván mỗi cấp.", "max_level": 5,
			"per_level": 2.0, "effect": &"bonus_gold_pct"},
	&"walls": {"name": "Tường thành", "description": "+1 máu nhà chính đầu ván mỗi cấp.", "max_level": 2,
			"per_level": 1.0, "effect": &"bonus_lives"},
}

## id -> MerchantRecipe
var recipes: Dictionary = {}
## Test hook: ngày giả lập ("YYYY-MM-DD"); rỗng = ngày hệ thống.
var date_override := ""
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	for file_name in ResourceLoader.list_directory(RECIPES_FOLDER):
		if file_name.ends_with(".tres"):
			var recipe := load(RECIPES_FOLDER.path_join(file_name)) as MerchantRecipe
			if recipe and recipe.id != &"":
				recipes[recipe.id] = recipe


func today() -> String:
	return date_override if not date_override.is_empty() else Time.get_date_string_from_system()


# --- Thương nhân ----------------------------------------------------------------------

func get_recipes() -> Array[MerchantRecipe]:
	var list: Array[MerchantRecipe] = []
	for recipe: MerchantRecipe in recipes.values():
		list.append(recipe)
	list.sort_custom(func(a: MerchantRecipe, b: MerchantRecipe) -> bool: return a.order < b.order)
	return list


## "" nếu đổi được, ngược lại là lý do (vd "Thiếu 2 Mảnh thép").
func get_trade_error(recipe: MerchantRecipe) -> String:
	for key: String in recipe.give:
		var need := int(recipe.give[key])
		var have := _amount_of(key)
		if have < need:
			return "Thiếu %d %s" % [need - have, display_name(key)]
	return ""


## Đổi đồ. Trả về danh sách kết quả nhận được (rỗng nếu không đổi được).
func trade(recipe: MerchantRecipe) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not get_trade_error(recipe).is_empty():
		return results
	for key: String in recipe.give:
		_take(key, int(recipe.give[key]), "merchant_%s" % recipe.id)
	for key: String in recipe.receive:
		for result in _give(key, int(recipe.receive[key]), "merchant_%s" % recipe.id):
			results.append(result)
	return results


## Tên hiển thị của một khoá trong give / receive.
func display_name(key: String) -> String:
	if key == "coins":
		return "Xu"
	if key == "dust":
		return "Bụi"
	if key.begins_with("random_skin:"):
		return "skin %s ngẫu nhiên" % Rarity.display_name(int(key.get_slice(":", 1)))
	var def := InventoryManager.get_def(StringName(key))
	return def.display_name if def else key


# --- Ghép đồ ------------------------------------------------------------------------

## Số món có thể đem ghép ở một bậc (chỉ tiêu hao + nguyên liệu; skin là độc nhất).
func get_fusable_count(tier: int) -> int:
	var total := 0
	for def in InventoryManager.get_owned():
		if def.is_stackable() and def.rarity == tier:
			total += InventoryManager.count(def.id)
	return total


func can_fuse(tier: int) -> bool:
	return tier < Rarity.Tier.LEGENDARY and get_fusable_count(tier) >= FUSE_COUNT


## Ghép 5 món bậc `tier` (ưu tiên món đang có nhiều nhất) -> 1 món ngẫu nhiên bậc kế tiếp.
func fuse(tier: int) -> Dictionary:
	if not can_fuse(tier):
		return {}
	var left := FUSE_COUNT
	while left > 0:
		var most: ItemDef = null
		for def in InventoryManager.get_owned():
			if def.is_stackable() and def.rarity == tier and (most == null or InventoryManager.count(def.id) > InventoryManager.count(most.id)):
				most = def
		var take := mini(left, InventoryManager.count(most.id))
		InventoryManager.consume(most.id, take, "fuse")
		left -= take
	var pool: Array[ItemDef] = []
	for def: ItemDef in InventoryManager.defs.values():
		if def.droppable and def.rarity == tier + 1:
			pool.append(def)
	return InventoryManager.grant(pool[rng.randi_range(0, pool.size() - 1)].id, 1, "fuse")


# --- Cửa hàng hôm nay -----------------------------------------------------------------

## 4 món bán hôm nay (cố định trong ngày, giống nhau mỗi lần mở).
func get_daily_offers() -> Array[ItemDef]:
	var day_rng := RandomNumberGenerator.new()
	day_rng.seed = hash("shop:" + today())
	var pool: Array[ItemDef] = []
	for def: ItemDef in InventoryManager.get_all():
		if def.droppable and def.kind != ItemDef.Kind.MATERIAL:
			pool.append(def)
	var offers: Array[ItemDef] = []
	var attempts := 0
	while offers.size() < SHOP_SLOTS and not pool.is_empty() and attempts < 500:
		attempts += 1
		# Chọn bậc theo trọng số rơi (hàng hiếm ít xuất hiện), rồi chọn món trong bậc đó.
		var tier := Rarity.roll(day_rng, 0.6)
		var candidates := pool.filter(func(def: ItemDef) -> bool: return def.rarity == tier)
		if candidates.is_empty():
			continue
		var pick: ItemDef = candidates[day_rng.randi_range(0, candidates.size() - 1)]
		offers.append(pick)
		pool.erase(pick)
	return offers


static func price_of(def: ItemDef) -> int:
	return SHOP_PRICES[def.rarity]


func is_bought(slot: int) -> bool:
	return slot in _shop_state().get("bought", [])


## Mua món ở ô `slot`. Trả về kết quả grant() (rỗng nếu không mua được).
func buy(slot: int) -> Dictionary:
	var offers := get_daily_offers()
	if slot < 0 or slot >= offers.size() or is_bought(slot):
		return {}
	var def := offers[slot]
	if not def.is_stackable() and InventoryManager.owns(def.id):
		return {}
	if not EconomyManager.spend(EconomyManager.COINS, price_of(def), "shop_%s" % def.id):
		return {}
	var bought: Array = _shop_state().get("bought", [])
	bought.append(slot)
	_shop_state()["bought"] = bought
	SaveManager.request_save()
	return InventoryManager.grant(def.id, 1, "shop")


func _shop_state() -> Dictionary:
	var shop := SaveManager.section("shop")
	if shop.get("day") != today():
		shop.clear()
		shop["day"] = today()
		shop["bought"] = []
	return shop


# --- Nâng cấp vĩnh viễn ---------------------------------------------------------------

func get_upgrade_level(id: StringName) -> int:
	return SaveManager.read_int(SaveManager.section("upgrades"), String(id))


## Giá nâng lên cấp kế tiếp (-1 nếu đã tối đa).
func get_upgrade_cost(id: StringName) -> int:
	var level := get_upgrade_level(id)
	if level >= UPGRADES[id].max_level:
		return -1
	return roundi(UPGRADE_BASE_COST * pow(UPGRADE_COST_GROWTH, level))


func buy_upgrade(id: StringName) -> bool:
	var cost := get_upgrade_cost(id)
	if cost < 0 or not EconomyManager.spend(EconomyManager.COINS, cost, "upgrade_%s" % id):
		return false
	SaveManager.section("upgrades")[String(id)] = get_upgrade_level(id) + 1
	SaveManager.request_save()
	return true


## Tổng hiệu ứng nâng cấp vĩnh viễn: {"bonus_gold_pct": float, "bonus_lives": float}.
func get_upgrade_bonuses() -> Dictionary:
	var bonuses := {"bonus_gold_pct": 0.0, "bonus_lives": 0.0}
	for id: StringName in UPGRADES:
		var upgrade: Dictionary = UPGRADES[id]
		bonuses[String(upgrade.effect)] += get_upgrade_level(id) * upgrade.per_level
	return bonuses


# --- Nội bộ --------------------------------------------------------------------------

func _amount_of(key: String) -> int:
	if key == "coins" or key == "dust":
		return EconomyManager.get_amount(StringName(key))
	return InventoryManager.count(StringName(key))


func _take(key: String, amount: int, reason: String) -> void:
	if key == "coins" or key == "dust":
		EconomyManager.spend(StringName(key), amount, reason)
	else:
		InventoryManager.consume(StringName(key), amount, reason)


func _give(key: String, amount: int, reason: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if key == "coins" or key == "dust":
		EconomyManager.add(StringName(key), amount, reason)
		return results
	if key.begins_with("random_skin:"):
		var tier := int(key.get_slice(":", 1))
		for i in amount:
			var unowned: Array[ItemDef] = []
			var any: Array[ItemDef] = []
			for def: ItemDef in InventoryManager.defs.values():
				if def.kind == ItemDef.Kind.SKIN and def.droppable and def.rarity == tier:
					any.append(def)
					if not InventoryManager.owns(def.id):
						unowned.append(def)
			var pool := unowned if not unowned.is_empty() else any
			if not pool.is_empty():
				results.append(InventoryManager.grant(pool[rng.randi_range(0, pool.size() - 1)].id, 1, reason))
		return results
	results.append(InventoryManager.grant(StringName(key), amount, reason))
	return results
