class_name TowerView
extends Node3D
## Hình 3D của một tháp (hoặc ghost tháp): chỉ "soi" lại Tower (2D).
##
## Cây node:  TowerView (vị trí ô, độ cao đồi)
##            └── Visual   (đế + thân theo loại tháp, hoặc TowerData.visual_scene)
##                ├── Turret  (nòng, xoay theo hướng bắn)
##                └── vòng cấp: L2 = 1 vòng bạc, L3 = 2 vòng vàng, cấp 4 = 3 vòng + vòng màu nhánh
## Màu thân lấy từ TowerData.color (khớp màu nút xây ở HUD); skin (meta) thay màu thân / viền.

const BASE_SIZE := Vector3(1.6, 0.3, 1.6)
const BASE_COLOR := Color("#757575")
const RING_SILVER := Color("#CFD8DC")
const RING_GOLD := Color("#FFC107")
const BRANCH_A_COLOR := Color("#FF7043")
const BRANCH_B_COLOR := Color("#26C6DA")
const POLE_COLOR := Color("#EEEEEE")
const MINE_COLOR := Color("#5D4037")
const NUGGET_COLOR := Color("#FFC107")
const BUFF_COLOR := Color("#FFD54F")
## Tỉ lệ phóng theo cấp 1..4.
const LEVEL_SCALE := [1.0, 1.0, 1.08, 1.15, 1.2]
const AIM_TURN_SPEED := 18.0

var tower: Tower
var data: TowerData
## Bán kính thân (mét) để đặt vòng cấp ôm quanh thân.
var body_radius := 0.4
## Số vòng cấp đã dựng (test đọc).
var ring_count := 0

var _visual: Node3D
var _turret: Node3D
var _buff: MeshInstance3D
var _select_ring: MeshInstance3D
var _pop := 0.0


## Dựng hình cho một cấp tháp. skin: ItemDef skin (có thể null). ghost: không đổ bóng.
func build(p_data: TowerData, skin: ItemDef = null, ghost_material: Material = null) -> void:
	data = p_data
	name = "TowerView"
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var body_color := skin.skin_color if skin else data.color
	var accent := skin.skin_accent if skin else data.color.darkened(0.35)
	var body_mat: Material = Shapes3D.glow(body_color) if skin and skin.pattern == ItemDef.Pattern.GLOW else Shapes3D.lit(body_color)
	var shadow := ghost_material == null

	_part(Shapes3D.box(BASE_SIZE), Shapes3D.lit(BASE_COLOR), Vector3(0, BASE_SIZE.y * 0.5, 0), shadow)
	var top := BASE_SIZE.y
	if data.visual_scene:
		_visual.add_child(data.visual_scene.instantiate())
	elif data.aura_radius > 0.0:
		# Cờ hiệu: cột trắng + lá cờ (nằm theo trục X để camera thấy rõ).
		_part(Shapes3D.cylinder(0.06, 0.06, 2.3, 8), Shapes3D.lit(POLE_COLOR), Vector3(0, top + 1.15, 0), shadow)
		_part(Shapes3D.box(Vector3(0.62, 0.4, 0.05)), body_mat, Vector3(0.34, top + 2.05, 0), shadow)
		body_radius = 0.12
	elif data.gold_per_wave > 0:
		# Mỏ vàng: miệng mỏ nâu + vài cục vàng.
		_part(Shapes3D.box(Vector3(1.1, 0.45, 1.1)), Shapes3D.lit(MINE_COLOR), Vector3(0, top + 0.22, 0), shadow)
		for at: Vector3 in [Vector3(-0.22, 0, -0.1), Vector3(0.2, 0, -0.18), Vector3(0.0, 0, 0.22)]:
			_part(Shapes3D.sphere(0.17), Shapes3D.lit(NUGGET_COLOR), at + Vector3(0, top + 0.55, 0), shadow)
		body_radius = 0.6
	else:
		match data.id:
			&"cannon":
				# Pháo: trụ rộng thấp + vòm + nòng dày.
				_part(Shapes3D.cylinder(0.5, 0.62, 0.7), body_mat, Vector3(0, top + 0.35, 0), shadow)
				_make_turret(top + 0.85)
				_turret_part(Shapes3D.sphere(0.32), Shapes3D.lit(accent), Vector3.ZERO, shadow)
				_barrel(Shapes3D.cylinder(0.14, 0.16, 0.85), accent, 0.5, shadow)
				body_radius = 0.62
			&"frost":
				# Băng: khối pha lê xoay 45°, hơi trong.
				var crystal := _part(Shapes3D.box(Vector3(0.75, 1.35, 0.75)), Shapes3D.lit(Color(body_color, 0.85)),
						Vector3(0, top + 0.68, 0), shadow)
				crystal.rotation.y = PI * 0.25
				_part(Shapes3D.sphere(0.16), Shapes3D.glow(body_color.lightened(0.6)), Vector3(0, top + 1.5, 0), false)
				body_radius = 0.55
			&"mage":
				# Phép: nón tím + quả cầu phát sáng trên đỉnh.
				_part(Shapes3D.cylinder(0.0, 0.5, 1.8), body_mat, Vector3(0, top + 0.9, 0), shadow)
				_part(Shapes3D.sphere(0.24), Shapes3D.glow(body_color.lightened(0.45)), Vector3(0, top + 1.95, 0), false)
				body_radius = 0.42
			_:
				# Cung thủ (và tháp lạ): trụ cao mảnh + đầu vuông + nòng.
				_part(Shapes3D.cylinder(0.28, 0.34, 1.5), body_mat, Vector3(0, top + 0.75, 0), shadow)
				_make_turret(top + 1.6)
				_turret_part(Shapes3D.box(Vector3(0.5, 0.3, 0.5)), Shapes3D.lit(accent), Vector3.ZERO, shadow)
				_barrel(Shapes3D.box(Vector3(0.12, 0.12, 0.6)), accent, 0.3, shadow)
				body_radius = 0.36

	_build_level_rings(top)
	_visual.scale = Vector3.ONE * LEVEL_SCALE[clampi(data.level, 1, 4)]

	_buff = Shapes3D.instance(Shapes3D.cylinder(0.0, 0.14, 0.24, 4), Shapes3D.glow(BUFF_COLOR), false)
	_buff.name = "Buff"
	_buff.rotation.x = PI # Mũi tên chĩa xuống.
	_buff.position = Vector3(0.6, 2.6, -0.6)
	_buff.visible = false
	add_child(_buff)

	# Viền trắng quanh đế khi tháp đang được chọn.
	_select_ring = Shapes3D.instance(Shapes3D.ring(1.08, 1.2), Shapes3D.glow(Color.WHITE), false)
	_select_ring.name = "SelectRing"
	_select_ring.scale = Vector3(1.0, 0.25, 1.0)
	_select_ring.position.y = 0.05
	_select_ring.visible = false
	add_child(_select_ring)

	if ghost_material:
		for node: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
			node.material_override = ghost_material
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Gắn vào một tháp thật. ground_height: độ cao mặt đất ở ô (đồi).
func bind(p_tower: Tower, ground_height: float) -> void:
	tower = p_tower
	position = Space3D.to_3d(tower.global_position, ground_height)
	_pop = 0.0
	if _turret:
		_turret.rotation.y = Space3D.yaw_of(Vector2.from_angle(tower.get_aim_angle()))
	sync(0.0)


## Hiệu ứng "nảy" khi vừa xây / nâng cấp.
func play_pop() -> void:
	if not VisualSettings.reduced_motion:
		_pop = 0.25


func sync(delta: float) -> void:
	if _turret:
		var desired := Space3D.yaw_of(Vector2.from_angle(tower.get_aim_angle()))
		_turret.rotation.y = lerp_angle(_turret.rotation.y, desired, minf(1.0, delta * AIM_TURN_SPEED))
	_buff.visible = tower.get_damage_multiplier() > 1.0
	_select_ring.visible = tower.show_range
	if _pop > 0.0:
		_pop = maxf(_pop - delta, 0.0)
		var bump := 1.0 + sin(_pop / 0.25 * PI) * 0.12
		_visual.scale = Vector3.ONE * LEVEL_SCALE[clampi(data.level, 1, 4)] * bump


## Hướng nòng hiện tại (radian quanh Y) — test đọc.
func get_turret_yaw() -> float:
	return _turret.rotation.y if _turret else 0.0


## Điểm đầu nòng (toạ độ thế giới) để vẽ tia / đạn.
func get_muzzle_position() -> Vector3:
	if _turret:
		return _turret.global_position + _turret.global_transform.basis.z * -0.6
	return global_position + Vector3(0, 1.6, 0)


func _build_level_rings(top: float) -> void:
	ring_count = 0
	var colors: Array[Color] = []
	match data.level:
		2:
			colors = [RING_SILVER]
		3:
			colors = [RING_GOLD, RING_GOLD]
		4:
			var branch_color := BRANCH_B_COLOR if data.resource_path.ends_with("b.tres") else BRANCH_A_COLOR
			colors = [RING_GOLD, RING_GOLD, branch_color]
	for i in colors.size():
		var radius := body_radius + 0.04
		_part(Shapes3D.ring(radius, radius + 0.09), Shapes3D.lit(colors[i]), Vector3(0, top + 0.18 + i * 0.16, 0), false)
		ring_count += 1


func _make_turret(height: float) -> void:
	_turret = Node3D.new()
	_turret.name = "Turret"
	_turret.position = Vector3(0, height, 0)
	_visual.add_child(_turret)


func _turret_part(mesh: Mesh, mat: Material, at: Vector3, shadow: bool) -> MeshInstance3D:
	var node := Shapes3D.instance(mesh, mat, shadow)
	node.position = at
	_turret.add_child(node)
	return node


## Nòng nằm ngang chĩa về -Z của turret. offset: khoảng cách từ tâm turret tới giữa nòng.
func _barrel(mesh: Mesh, color: Color, offset: float, shadow: bool) -> void:
	var barrel := _turret_part(mesh, Shapes3D.lit(color.darkened(0.2)), Vector3(0, 0, -offset), shadow)
	if mesh is CylinderMesh:
		barrel.rotation.x = PI * 0.5


func _part(mesh: Mesh, mat: Material, at: Vector3, shadow: bool) -> MeshInstance3D:
	var node := Shapes3D.instance(mesh, mat, shadow)
	node.position = at
	_visual.add_child(node)
	return node
