class_name UnitSync
extends Node3D
## Đồng bộ đơn vị 2D -> hình 3D: địch, tháp, đạn, tia bắn, sóng toả.
##
## Chỉ NGHE signal của mô phỏng (WaveManager.enemy_spawned, BuildManager.tower_*, Tower.fired,
## projectile container) rồi mỗi khung chép vị trí / trạng thái sang hình 3D. Mọi hình lấy từ
## VisualPool theo loại nên trong trận gần như không tạo node mới.
## Chạy sau cùng trong khung (process_priority cao) để đọc vị trí đã cập nhật của đơn vị.

const BEAM_TIME := 0.08
const GHOST_VALID := Color(0.337, 0.706, 0.914, 0.45) # #56B4E9
const GHOST_INVALID := Color(0.835, 0.369, 0.0, 0.45) # #D55E00
const PULSE_TIME := 0.24
const SHOT_HEIGHT := 1.0
const PROJECTILE_HEIGHT := 1.1

var view: View3D
var pool := VisualPool.new()
var build_manager: BuildManager
var range_display: TowerRangeDisplay
## Ghost 3D đang hiện (null = không) và key pool của nó.
var ghost: TowerView
var _ghost_key := ""
## Chỉ dựng / đồng bộ hình khi cảnh 3D đang bật (chế độ 2D không tốn gì).
var active := false

var _enemies: Dictionary = {} # Enemy -> EnemyView
var _towers: Dictionary = {} # Tower -> TowerView
var _projectiles: Dictionary = {} # Projectile -> MeshInstance3D
## Hiệu ứng ngắn: {node, key, age, life, kind}
var _effects: Array[Dictionary] = []


func setup(p_view: View3D, waves: WaveManager, build: BuildManager, p_range_display: TowerRangeDisplay) -> void:
	view = p_view
	build_manager = build
	range_display = p_range_display
	name = "UnitSync"
	process_priority = 100
	waves.enemy_spawned.connect(track_enemy)
	build.tower_placed.connect(track_tower)
	build.tower_upgraded.connect(_on_tower_upgraded)
	build.projectile_container.child_entered_tree.connect(func(node: Node) -> void:
		if node is Projectile:
			track_projectile(node))


func get_enemy_view(enemy: Enemy) -> EnemyView:
	return _enemies.get(enemy)


func get_tower_view(tower: Tower) -> TowerView:
	return _towers.get(tower)


func get_projectile_view(projectile: Projectile) -> MeshInstance3D:
	return _projectiles.get(projectile)


func active_enemy_count() -> int:
	return _enemies.size()


func active_effect_count() -> int:
	return _effects.size()


## Bật / tắt đồng bộ. Tắt: trả mọi hình về pool. Bật: dựng hình cho các đơn vị đang có.
func set_active(on: bool) -> void:
	if on == active:
		return
	if not on:
		for enemy: Enemy in _enemies.keys():
			enemy.tree_exiting.disconnect(_untrack_enemy.bind(enemy))
			_untrack_enemy(enemy)
		for tower: Tower in _towers.keys():
			tower.fired.disconnect(_on_tower_fired.bind(tower))
			tower.tree_exiting.disconnect(_untrack_tower.bind(tower))
			_untrack_tower(tower)
		for projectile: Projectile in _projectiles.keys():
			projectile.tree_exiting.disconnect(_untrack_projectile.bind(projectile))
			_untrack_projectile(projectile)
		for effect in _effects:
			pool.release(effect.key, effect.node)
		_effects.clear()
		if ghost:
			pool.release(_ghost_key, ghost)
			ghost = null
			_ghost_key = ""
	active = on
	if on:
		for enemy: Enemy in get_tree().get_nodes_in_group(Enemy.GROUP):
			if view.map.is_ancestor_of(enemy) and enemy.is_alive():
				track_enemy(enemy)
		for tower in build_manager.get_towers():
			track_tower(tower)
		for node in build_manager.projectile_container.get_children():
			if node is Projectile:
				track_projectile(node)


func track_enemy(enemy: Enemy) -> void:
	if not active:
		return
	var view_node := pool.acquire(enemy.data, func() -> Node3D:
		var created := EnemyView.new()
		add_child(created)
		created.build(enemy.data)
		return created) as EnemyView
	view_node.bind(enemy)
	_enemies[enemy] = view_node
	enemy.tree_exiting.connect(_untrack_enemy.bind(enemy), CONNECT_ONE_SHOT)


func track_tower(tower: Tower) -> void:
	if not active:
		return
	_attach_tower_view(tower)
	tower.fired.connect(_on_tower_fired.bind(tower))
	tower.tree_exiting.connect(_untrack_tower.bind(tower), CONNECT_ONE_SHOT)


## Lấy hình đúng cấp / skin của tháp từ pool và gắn vào tháp.
func _attach_tower_view(tower: Tower) -> void:
	var key := _tower_key(tower)
	var view_node := pool.acquire(key, func() -> Node3D:
		var created := TowerView.new()
		add_child(created)
		created.build(tower.data, tower.skin)
		return created) as TowerView
	view_node.set_meta("pool_key", key)
	view_node.bind(tower, view.ground_height_at(tower.global_position))
	view_node.play_pop()
	_towers[tower] = view_node


func track_projectile(projectile: Projectile) -> void:
	if not active:
		return
	var radius := 0.2 if projectile.splash_radius > 0.0 else 0.12
	var key := "projectile%s|%s" % [radius, projectile.color.to_html()]
	var node := pool.acquire(key, func() -> Node3D:
		var created := Shapes3D.instance(Shapes3D.sphere(radius), Shapes3D.glow(projectile.color), false)
		add_child(created)
		return created)
	node.set_meta("pool_key", key)
	_projectiles[projectile] = node
	_place_projectile(projectile, node)
	projectile.tree_exiting.connect(_untrack_projectile.bind(projectile), CONNECT_ONE_SHOT)


func _process(delta: float) -> void:
	if not active:
		return
	for enemy: Enemy in _enemies:
		_enemies[enemy].sync(delta)
	for tower: Tower in _towers:
		_towers[tower].sync(delta)
	for projectile: Projectile in _projectiles:
		_place_projectile(projectile, _projectiles[projectile])
	for i in range(_effects.size() - 1, -1, -1):
		var effect := _effects[i]
		effect.age += delta
		if effect.age >= effect.life:
			pool.release(effect.key, effect.node)
			_effects.remove_at(i)
		elif effect.kind == &"pulse":
			var t: float = effect.age / effect.life
			var radius: float = lerpf(0.3, effect.radius, t)
			effect.node.scale = Vector3(radius, 1.0, radius)
	_update_ghost()


## Ghost 3D: hình tháp sắp xây, trong suốt xanh (đặt được) / cam (không), theo ô dưới con trỏ.
## Trạng thái và vị trí lấy từ TowerRangeDisplay (một nguồn chung với vòng tầm bắn).
func _update_ghost() -> void:
	var data := build_manager.selected_tower_data
	var key := ""
	if data and build_manager.is_building() and range_display.is_ghost_visible():
		key = "ghost|%s|%s" % [data.resource_path, range_display.is_placement_valid()]
	if key != _ghost_key:
		if ghost:
			pool.release(_ghost_key, ghost)
			ghost = null
		_ghost_key = key
		if not key.is_empty():
			var valid := key.ends_with("true")
			ghost = pool.acquire(key, func() -> Node3D:
				var created := TowerView.new()
				add_child(created)
				created.build(data, InventoryManager.get_equipped_skin(data.id),
						Shapes3D.glow(GHOST_VALID if valid else GHOST_INVALID))
				return created) as TowerView
	if ghost:
		var at := range_display.get_ghost_position()
		ghost.position = Space3D.to_3d(at, view.ground_height_at(at))


func _place_projectile(projectile: Projectile, node: Node3D) -> void:
	node.position = Space3D.to_3d(projectile.global_position, PROJECTILE_HEIGHT)


func _on_tower_fired(target: Enemy, _damage: float, tower: Tower) -> void:
	if not active:
		return
	match tower.data.attack_type:
		TowerData.AttackType.HITSCAN:
			_spawn_beam(tower, target)
		TowerData.AttackType.PULSE:
			_spawn_pulse(tower)


## Tia bắn tức thời: hộp mảnh nối đầu nòng (hoặc đỉnh tháp) với mục tiêu, tắt sau BEAM_TIME.
func _spawn_beam(tower: Tower, target: Enemy) -> void:
	var color := tower.data.color.lightened(0.4)
	var key := "beam%s" % color.to_html()
	var beam := pool.acquire(key, func() -> Node3D:
		var created := Shapes3D.instance(Shapes3D.box(Vector3.ONE), Shapes3D.glow(color), false)
		add_child(created)
		return created)
	var tower_view: TowerView = _towers.get(tower)
	var from := tower_view.global_position + Vector3(0, 1.8, 0) if tower_view else Space3D.to_3d(tower.global_position, 1.8)
	var enemy_view: EnemyView = _enemies.get(target)
	var to := enemy_view.global_position + Vector3(0, enemy_view.top_height * 0.5, 0) if enemy_view \
			else Space3D.to_3d(target.global_position, SHOT_HEIGHT)
	var length := from.distance_to(to)
	beam.position = (from + to) * 0.5
	if length > 0.01:
		beam.look_at_from_position(beam.position, to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.FORWARD)
	beam.scale = Vector3(0.08, 0.08, maxf(length, 0.01))
	_effects.append({"node": beam, "key": key, "age": 0.0, "life": BEAM_TIME, "kind": &"beam"})


## Sóng toả: vòng dẹt nở từ tháp ra hết tầm bắn.
func _spawn_pulse(tower: Tower) -> void:
	var color := Color(tower.data.color.lightened(0.3), 0.7)
	var key := "pulse%s" % color.to_html()
	var ring := pool.acquire(key, func() -> Node3D:
		var created := Shapes3D.instance(Shapes3D.ring(0.92, 1.0), Shapes3D.glow(color), false)
		add_child(created)
		return created)
	ring.position = Space3D.to_3d(tower.global_position, 0.15 + view.ground_height_at(tower.global_position))
	ring.scale = Vector3(0.3, 1.0, 0.3)
	_effects.append({"node": ring, "key": key, "age": 0.0, "life": PULSE_TIME, "kind": &"pulse",
			"radius": Space3D.px_to_m(tower.get_range())})


func _on_tower_upgraded(tower: Tower) -> void:
	if not active:
		return
	# Cấp mới có hình khác (vòng cấp, kích thước): trả hình cũ, lấy hình của cấp mới.
	var old: TowerView = _towers.get(tower)
	if old:
		old.tower = null
		pool.release(old.get_meta("pool_key"), old)
		_towers.erase(tower)
	_attach_tower_view(tower)


func _untrack_enemy(enemy: Enemy) -> void:
	var node: EnemyView = _enemies.get(enemy)
	if node:
		_enemies.erase(enemy)
		node.unbind()
		pool.release(enemy.data, node)


func _untrack_tower(tower: Tower) -> void:
	var node: TowerView = _towers.get(tower)
	if node:
		_towers.erase(tower)
		node.tower = null
		pool.release(node.get_meta("pool_key"), node)


func _untrack_projectile(projectile: Projectile) -> void:
	var node: Node3D = _projectiles.get(projectile)
	if node:
		_projectiles.erase(projectile)
		pool.release(node.get_meta("pool_key"), node)


## Mỗi cấp / nhánh / skin là một hình riêng trong pool.
func _tower_key(tower: Tower) -> String:
	return "%s|%s" % [tower.data.resource_path, tower.skin.id if tower.skin else &""]
