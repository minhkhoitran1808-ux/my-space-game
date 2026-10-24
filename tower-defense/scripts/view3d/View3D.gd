class_name View3D
extends Node3D
## Lớp hiển thị 3D của một trận: "soi" lại mô phỏng 2D bằng hình khối (blockout).
##
## Không chứa luật chơi. Main tạo node này, gọi setup() sau khi nạp bản đồ; bật / tắt bằng
## set_active() (chế độ 2D thì ẩn đi, mô phỏng vẫn chạy như cũ).
##
## Cảnh: WorldEnvironment + đèn mặt trời + FixedCamera + mặt đất ô cờ nhạt + dải đường đi
## + địa hình (bùn / đồi / đá) + nhà chính. Đơn vị (địch, tháp, đạn) do UnitSync thêm vào.

const GROUND_SHADER := preload("res://shaders/ground_grid.gdshader")

const PATH_COLOR := Color("#C8B898")
const PATH_BORDER_COLOR := Color("#9A8B6C")
const BASE_COLOR := Color(0.3, 0.55, 0.9)
const MUD_COLOR := Color("#4E3D2A")
const MUD_DOT_COLOR := Color("#3A2D1E")
const HILL_TOP_COLOR := Color("#829A78")
const HILL_SIDE_COLOR := Color("#5E7357")
const ROCK_COLOR := Color("#8E8C84")
## Độ cao mặt trên của đồi (mét). Tháp đặt trên đồi đứng ở độ cao này.
const HILL_HEIGHT := 0.35
const BACKGROUND_COLOR := Color("#1F2A22")

var camera: FixedCamera
var sun: DirectionalLight3D
var map: GameMap
## Đồng bộ đơn vị (địch, tháp, đạn); Main tạo qua setup_units().
var units: UnitSync
## Các node 2D vẽ / nhận chuột trên mặt đất: khi 3D bật, transform của chúng được gán bằng
## phép chiếu mặt đất -> màn hình (GameView.ground_transform) mỗi khung.
var ground_space_nodes: Array[Node2D] = []

## Mỗi màu một material dùng chung (để Godot gộp vẽ được).
static var _materials: Dictionary = {}


func setup(p_map: GameMap) -> void:
	map = p_map
	name = "View3D"
	# Vẫn vẽ / cập nhật khi tạm dừng (tạm dừng chiến thuật vẫn cho xây, nâng cấp).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_environment()
	_build_ground()
	_build_terrain()
	_build_base()
	apply_settings()


func _exit_tree() -> void:
	if GameView.camera == camera:
		GameView.camera = null
		GameView.tower_picker = Callable()
	_materials.clear()
	Shapes3D.clear_cache()


func _process(_delta: float) -> void:
	if visible:
		_apply_ground_transform()


## Bắt đầu đồng bộ đơn vị của trận.
func setup_units(waves: WaveManager, build: BuildManager, range_display: TowerRangeDisplay) -> void:
	units = UnitSync.new()
	add_child(units)
	units.setup(self, waves, build, range_display)


## Bật / tắt cả cảnh 3D (camera, đèn, mesh) và cách quy đổi chuột / hình 2D.
func set_active(active: bool) -> void:
	visible = active
	camera.current = active
	GameView.camera = camera if active else null
	GameView.tower_picker = pick_tower if active else Callable()
	if units:
		units.set_active(active)
	camera.fit()
	_apply_ground_transform()


## Tháp có thân che vị trí màn hình (đoạn từ chân tới đỉnh tháp trên màn hình), gần nhất trước.
func pick_tower(screen_position: Vector2) -> Tower:
	var best: Tower = null
	var best_distance := INF
	# Bán kính chọn ~ nửa bề rộng đế tháp, đổi ra pixel màn hình.
	var reach := (camera.unproject_position(Vector3(0.8, 0, 0)) - camera.unproject_position(Vector3.ZERO)).length()
	for tower: Tower in get_tree().get_nodes_in_group(Tower.GROUP):
		var ground := ground_height_at(tower.global_position)
		var foot := camera.unproject_position(Space3D.to_3d(tower.global_position, ground))
		var head := camera.unproject_position(Space3D.to_3d(tower.global_position, ground + 2.2))
		var closest := Geometry2D.get_closest_point_to_segment(screen_position, foot, head)
		var distance := closest.distance_to(screen_position)
		if distance <= reach and distance < best_distance:
			best = tower
			best_distance = distance
	return best


func _apply_ground_transform() -> void:
	var xform := GameView.ground_transform() if visible else Transform2D.IDENTITY
	for node in ground_space_nodes:
		if is_instance_valid(node):
			node.transform = xform


## Bóng đổ theo cài đặt.
func apply_settings() -> void:
	sun.shadow_enabled = VisualSettings.shadows_3d


## Độ cao mặt đất tại một điểm 2D (đồi cao hơn).
func ground_height_at(position_2d: Vector2) -> float:
	return HILL_HEIGHT if map.get_terrain_at(position_2d) == GameMap.TERRAIN_HILL else 0.0


## Material đơn giản dùng chung theo (màu, không chịu sáng, hai mặt).
static func material(color: Color, unshaded: bool = false, double_sided: bool = false) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [color.to_html(), unshaded, double_sided]
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.metallic_specular = 0.0 # Không bóng loáng: màu giữ đúng như thiết kế dưới mọi góc đèn.
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if double_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_materials[key] = mat
	return mat


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BACKGROUND_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.light_energy = 0.5
	sun.shadow_opacity = 0.6
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

	camera = FixedCamera.new()
	camera.name = "FixedCamera"
	add_child(camera)


func _build_ground() -> void:
	# Mặt đất rộng hơn hẳn màn hình để không lộ mép ở màn hình rộng.
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(120.0, 80.0)
	ground.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	ground.material_override = mat
	ground.position = Space3D.to_3d(Vector2(640, 360))
	add_child(ground)

	var paths := map.get_paths()
	_add_mesh("PathBorder", LevelMeshes.path_ribbon(paths, GameConfig.PATH_WIDTH + 8.0, 0.004),
			material(PATH_BORDER_COLOR, false, true))
	_add_mesh("Path", LevelMeshes.path_ribbon(paths, GameConfig.PATH_WIDTH, 0.008),
			material(PATH_COLOR, false, true))


func _build_terrain() -> void:
	for points: PackedVector2Array in map.get_terrain_polygons(GameMap.TERRAIN_HILL):
		var hill := _add_mesh("Hill", LevelMeshes.polygon_prism(points, HILL_HEIGHT), material(HILL_SIDE_COLOR, false, true))
		# Mặt trên sáng hơn mặt bên: phủ thêm một mảng phẳng ngay trên đỉnh.
		hill.add_child(_mesh_instance(LevelMeshes.polygon_prism(points, HILL_HEIGHT + 0.002), material(HILL_TOP_COLOR, false, true)))
	for points: PackedVector2Array in map.get_terrain_polygons(GameMap.TERRAIN_MUD):
		var mud := _add_mesh("Mud", LevelMeshes.polygon_prism(points, 0.012), material(MUD_COLOR, false, true))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(points)
		var bounds := _bounds(points)
		var dot_mesh := CylinderMesh.new()
		dot_mesh.top_radius = 0.09
		dot_mesh.bottom_radius = 0.09
		dot_mesh.height = 0.02
		for i in int(bounds.get_area() / 500.0):
			var dot := bounds.position + Vector2(rng.randf(), rng.randf()) * bounds.size
			if Geometry2D.is_point_in_polygon(dot, points):
				var dot_instance := _mesh_instance(dot_mesh, material(MUD_DOT_COLOR))
				dot_instance.position = Space3D.to_3d(dot, 0.02)
				dot_instance.scale = Vector3.ONE * rng.randf_range(0.7, 1.4)
				mud.add_child(dot_instance)
	for points: PackedVector2Array in map.get_terrain_polygons(GameMap.TERRAIN_ROCK):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(points)
		var bounds := _bounds(points)
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.45
		rock_mesh.height = 0.6
		for i in 3:
			var at := bounds.position + Vector2(rng.randf_range(0.25, 0.75), rng.randf_range(0.25, 0.75)) * bounds.size
			var rock := _mesh_instance(rock_mesh, material(ROCK_COLOR))
			rock.name = "Rock"
			rock.position = Space3D.to_3d(at, 0.15)
			rock.scale = Vector3(rng.randf_range(0.8, 1.3), rng.randf_range(0.8, 1.2), rng.randf_range(0.8, 1.3))
			rock.rotation.y = rng.randf() * TAU
			add_child(rock, true)


func _build_base() -> void:
	var base := Node3D.new()
	base.name = "Base"
	base.position = Space3D.to_3d(map.get_base_position())
	add_child(base)
	var body := BoxMesh.new()
	body.size = Vector3(1.6, 1.2, 1.6)
	var body_instance := _mesh_instance(body, material(BASE_COLOR))
	body_instance.position.y = 0.6
	base.add_child(body_instance)
	var roof := PrismMesh.new()
	roof.size = Vector3(1.9, 0.7, 1.9)
	var roof_instance := _mesh_instance(roof, material(BASE_COLOR.darkened(0.35)))
	roof_instance.position.y = 1.55
	base.add_child(roof_instance)
	var label := Label3D.new()
	label.text = "NHÀ CHÍNH"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0012
	label.font_size = 28
	label.outline_size = 8
	label.position = Vector3(-0.6, 2.4, 0.0)
	base.add_child(label)


func _add_mesh(node_name: String, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var instance := _mesh_instance(mesh, mat)
	instance.name = node_name
	add_child(instance, true) # Trùng tên thì Godot đặt tên dễ đọc: Mud, Mud2...
	return instance


func _mesh_instance(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	return instance


func _bounds(points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds
