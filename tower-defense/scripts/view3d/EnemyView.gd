class_name EnemyView
extends Node3D
## Hình 3D của một địch: chỉ "soi" lại Enemy (2D), không giữ luật chơi.
##
## Cây node:  EnemyView (vị trí, không xoay)
##            ├── Visual   (hình khối theo EnemyData.shape hoặc EnemyData.visual_scene; xoay theo hướng đi)
##            ├── HpBack / HpFill (thanh máu billboard, luôn vẽ trên cùng)
##            └── TintRing (vòng hiệu ứng dưới chân: làm chậm, thiêu đốt...)
## Kích thước lấy từ EnemyData.radius (pixel), không đọc từ mesh: thay model thật vẫn đúng tầm.
## Mỗi loại địch dùng một bộ mesh / material chung (Shapes3D) nên vẽ được theo lô.

const FLY_HEIGHT := 1.8
const NOSE_COLOR := Color("#263238")
const HELMET_COLOR := Color("#9E9E9E")
const SHIELD_COLOR := Color(0.67, 0.28, 0.74, 0.25) # #AB47BC, trong suốt
const CROSS_COLOR := Color("#F5F5F5")
const CROWN_COLOR := Color("#FFC107")
const BAR_WIDTH := 1.0
const BAR_HEIGHT := 0.13
const BAR_GAP := 0.35

var enemy: Enemy
## Chiều cao đỉnh hình (mét, chưa tính bay), để đặt thanh máu.
var top_height := 1.0

var _visual: Node3D
var _body_meshes: Array[MeshInstance3D] = []
var _wings: Array[Node3D] = []
var _hp_back: MeshInstance3D
var _hp_fill: MeshInstance3D
var _tint_ring: MeshInstance3D
var _bar_width := BAR_WIDTH
var _flash_level := -1
var _last_position := Vector2.INF
var _time := 0.0
## Chỉ đọc lại hiệu ứng / thanh máu khi chúng đổi (đỡ tốn khi có hàng trăm địch).
var _tints_dirty := true
var _shown_ratio := -1.0


## Dựng hình cho một loại địch (gọi một lần khi tạo; pool dùng lại cho cùng loại).
func build(data: EnemyData) -> void:
	name = "EnemyView"
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	if data.visual_scene:
		_visual.add_child(data.visual_scene.instantiate())
		top_height = data.radius / 16.0 + 0.4
	else:
		_build_blockout(data)
	for node in _visual.find_children("*", "MeshInstance3D", true, false):
		_body_meshes.append(node)

	_bar_width = BAR_WIDTH * (1.6 if data.elite else 1.0)
	_hp_back = Shapes3D.instance(Shapes3D.bar_quad(_bar_width + 0.06, BAR_HEIGHT + 0.06, false),
			Shapes3D.billboard(HealthBar.COLOR_BACKGROUND, 10), false)
	_hp_back.name = "HpBack"
	add_child(_hp_back)
	_hp_fill = Shapes3D.instance(Shapes3D.bar_quad(_bar_width, BAR_HEIGHT, true),
			Shapes3D.billboard(HealthBar.COLOR_HIGH, 11), false)
	_hp_fill.name = "HpFill"
	add_child(_hp_fill)

	_tint_ring = Shapes3D.instance(Shapes3D.ring(data.radius / 32.0 + 0.05, data.radius / 32.0 + 0.15),
			Shapes3D.glow(Color.WHITE), false)
	_tint_ring.name = "TintRing"
	_tint_ring.scale = Vector3(1.0, 0.3, 1.0)
	add_child(_tint_ring)


## Gắn vào một địch cụ thể (lấy từ pool ra).
func bind(p_enemy: Enemy) -> void:
	enemy = p_enemy
	_last_position = Vector2.INF
	_flash_level = -1
	_time = 0.0
	_tints_dirty = true
	_shown_ratio = -1.0
	enemy.status_effects.effects_changed.connect(_mark_tints_dirty)
	sync(0.0)


## Gỡ khỏi địch (trước khi trả về pool).
func unbind() -> void:
	if enemy and enemy.status_effects.effects_changed.is_connected(_mark_tints_dirty):
		enemy.status_effects.effects_changed.disconnect(_mark_tints_dirty)
	enemy = null


func _mark_tints_dirty() -> void:
	_tints_dirty = true


## Cập nhật theo trạng thái địch 2D. Gọi mỗi khung (sau khi địch đã di chuyển).
func sync(delta: float) -> void:
	_time += delta
	var data := enemy.data
	var pos_2d := enemy.global_position
	var height := 0.0
	if data.is_flying:
		height = FLY_HEIGHT + (0.0 if VisualSettings.reduced_motion else sin(_time * 4.0) * 0.08)
	position = Space3D.to_3d(pos_2d, height)

	# Hướng mặt theo chiều đi (lần đầu lấy theo tiếp tuyến đường).
	var direction := Vector2.ZERO
	if _last_position != Vector2.INF:
		direction = pos_2d - _last_position
	if direction.length_squared() < 0.0001:
		var path := enemy.get_parent() as Path2D
		if path and _last_position == Vector2.INF:
			var ahead := path.curve.sample_baked(minf(enemy.progress + 4.0, path.curve.get_baked_length()))
			direction = path.to_global(ahead) - pos_2d
	if direction.length_squared() > 0.0001:
		_visual.rotation.y = Space3D.yaw_of(direction)
	_last_position = pos_2d

	# Giật khi trúng đòn: nén / giãn quanh chân.
	var squash := enemy.hit_feedback.body_scale
	_visual.scale = Vector3(squash.x, squash.y, squash.x)
	for i in _wings.size():
		var flap := 0.0 if VisualSettings.reduced_motion else sin(_time * 14.0) * 0.5
		_wings[i].rotation.z = flap * (1.0 if i == 0 else -1.0)

	var flash_level := clampi(roundi(enemy.hit_feedback.flash_amount * VisualSettings.hit_flash_strength() * 4.0), 0, 4)
	if flash_level != _flash_level:
		_flash_level = flash_level
		var overlay := Shapes3D.flash_overlay(flash_level / 4.0)
		for mesh in _body_meshes:
			mesh.material_overlay = overlay

	var shown := enemy.health_bar.is_shown()
	_hp_back.visible = shown
	_hp_fill.visible = shown
	if shown:
		var ratio := clampf(enemy.health / maxf(enemy.max_health, 0.001), 0.0, 1.0)
		if ratio != _shown_ratio:
			_shown_ratio = ratio
			var bar_y := top_height + BAR_GAP
			_hp_back.position = Vector3(0.0, bar_y, 0.0)
			# Camera không xoay quanh Y nên trục X thế giới = trục ngang màn hình.
			_hp_fill.position = Vector3(-_bar_width * 0.5, bar_y, 0.0)
			_hp_fill.scale = Vector3(maxf(ratio, 0.001), 1.0, 1.0)
			_hp_fill.material_override = Shapes3D.billboard(HealthBar.color_for_ratio(ratio), 11)

	if _tints_dirty:
		_tints_dirty = false
		var tints := enemy.status_effects.get_tints()
		_tint_ring.visible = not tints.is_empty()
		if _tint_ring.visible:
			_tint_ring.material_override = Shapes3D.glow(Color(tints[0], 1.0))
	if _tint_ring.visible:
		_tint_ring.position.y = 0.05 - height


## Thanh máu có đang hiện không (test).
func is_health_bar_shown() -> bool:
	return _hp_fill.visible


## Hình khối mặc định theo EnemyData.shape (tài liệu mục 5.2: silhouette trước, màu sau).
func _build_blockout(data: EnemyData) -> void:
	var r := data.radius / 32.0 # Bán kính thân (mét): to hơn tài liệu một chút để đọc rõ ở ảnh thu nhỏ.
	var color := data.color
	match data.shape:
		EnemyData.Shape.SQUARE:
			var edge := r * 2.0
			_part(Shapes3D.box(Vector3(edge, edge, edge)), Shapes3D.lit(color), Vector3(0, edge * 0.5, 0))
			top_height = edge
		EnemyData.Shape.TRIANGLE:
			# Trinh sát: capsule nhỏ, nghiêng về phía trước 15°.
			var h := r * 3.0
			var body := _part(Shapes3D.capsule(r, h), Shapes3D.lit(color), Vector3(0, h * 0.5, 0))
			body.rotation.x = -deg_to_rad(15.0)
			top_height = h
		EnemyData.Shape.DIAMOND:
			# Boss: khối kim cương (khối cầu 4 múi = bát diện) lơ lửng, đội vương miện.
			var size := r * 1.25
			var diamond := _part(_diamond_mesh(size), Shapes3D.lit(color), Vector3(0, size * 1.1, 0))
			diamond.rotation.y = PI * 0.25
			for i in 3:
				var angle := TAU * i / 3.0
				_part(Shapes3D.cylinder(0.0, 0.12, 0.35, 6), Shapes3D.lit(CROWN_COLOR),
						Vector3(cos(angle) * 0.25, size * 2.1 + 0.15, sin(angle) * 0.25))
			top_height = size * 2.1 + 0.3
		EnemyData.Shape.BAT:
			var body_r := r * 0.75
			_part(Shapes3D.sphere(body_r), Shapes3D.lit(color), Vector3(0, body_r, 0))
			for side in [-1.0, 1.0]:
				var hinge := Node3D.new()
				hinge.position = Vector3(side * body_r * 0.6, body_r * 1.1, 0)
				_visual.add_child(hinge)
				var wing := Shapes3D.instance(Shapes3D.box(Vector3(r * 1.6, 0.05, r * 0.9)), Shapes3D.lit(color.darkened(0.25)))
				wing.position = Vector3(side * r * 0.8, 0, 0)
				hinge.add_child(wing)
				_wings.append(hinge)
			top_height = body_r * 2.0
		EnemyData.Shape.CROSS:
			var h := r * 3.4
			_part(Shapes3D.capsule(r, h), Shapes3D.lit(color), Vector3(0, h * 0.5, 0))
			# Dấu cộng trắng nằm trên đỉnh đầu (camera nhìn chéo từ trên thấy rõ).
			_part(Shapes3D.box(Vector3(r * 1.4, 0.06, r * 0.4)), Shapes3D.lit(CROSS_COLOR), Vector3(0, h + 0.02, 0))
			_part(Shapes3D.box(Vector3(r * 0.4, 0.06, r * 1.4)), Shapes3D.lit(CROSS_COLOR), Vector3(0, h + 0.02, 0))
			top_height = h
		EnemyData.Shape.BLOB:
			# Hồn ma: quả cầu mờ lơ lửng, đuôi nón phía sau.
			_part(Shapes3D.sphere(r), Shapes3D.lit(Color(color, 0.7)), Vector3(0, r + 0.35, 0), false)
			var tail := _part(Shapes3D.cylinder(r * 0.6, 0.0, r * 1.6, 8), Shapes3D.lit(Color(color, 0.5)),
					Vector3(0, r + 0.3, r * 1.1), false)
			tail.rotation.x = deg_to_rad(80.0)
			top_height = r * 2.0 + 0.35
		_:
			var h := r * 3.4
			_part(Shapes3D.capsule(r, h), Shapes3D.lit(color), Vector3(0, h * 0.5, 0))
			top_height = h
	# Mũi nhỏ phía trước (-Z) cho biết hướng đi.
	if data.shape != EnemyData.Shape.BLOB:
		_part(Shapes3D.box(Vector3(0.15, 0.15, 0.15)), Shapes3D.lit(NOSE_COLOR), Vector3(0, top_height * 0.55, -r - 0.05))
	# "Mũ giáp" = giáp vật lý dày, "khiên" trong suốt = kháng phép.
	if data.armor >= 0.5:
		_part(Shapes3D.box(Vector3(r * 1.7, 0.1, r * 1.3)), Shapes3D.lit(HELMET_COLOR), Vector3(0, top_height + 0.05, 0))
		top_height += 0.1
	if data.magic_resist >= 0.3:
		var shield_r := maxf(r * 1.3, top_height * 0.6)
		_part(Shapes3D.sphere(shield_r), Shapes3D.lit(SHIELD_COLOR), Vector3(0, top_height * 0.5, 0), false)


func _part(mesh: Mesh, mat: Material, at: Vector3, shadow: bool = true) -> MeshInstance3D:
	var node := Shapes3D.instance(mesh, mat, shadow)
	node.position = at
	_visual.add_child(node)
	return node


## Khối kim cương: khối cầu 4 múi 2 tầng = bát diện.
static func _diamond_mesh(radius: float) -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 4
	mesh.rings = 1
	return mesh
