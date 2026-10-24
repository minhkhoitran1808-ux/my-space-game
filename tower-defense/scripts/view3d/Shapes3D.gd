class_name Shapes3D
extends RefCounted
## Hình khối và material DÙNG CHUNG cho cảnh 3D.
##
## Mỗi bộ tham số chỉ tạo một mesh / một material rồi dùng lại cho mọi đơn vị, để renderer
## gộp được lệnh vẽ (tài liệu "Optimizing 3D performance": cùng mesh + cùng material).
## Không bao giờ duplicate() material để đổi màu từng con; hiệu ứng riêng (nháy trúng đòn,
## thanh máu) dùng một vài material dựng sẵn theo mức.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func box(size: Vector3) -> BoxMesh:
	return _mesh("box%s" % size, func() -> Mesh:
		var mesh := BoxMesh.new()
		mesh.size = size
		return mesh)


static func cylinder(top_radius: float, bottom_radius: float, height: float, segments: int = 16) -> CylinderMesh:
	return _mesh("cyl%s|%s|%s|%s" % [top_radius, bottom_radius, height, segments], func() -> Mesh:
		var mesh := CylinderMesh.new()
		mesh.top_radius = top_radius
		mesh.bottom_radius = bottom_radius
		mesh.height = height
		mesh.radial_segments = segments
		mesh.rings = 1
		return mesh)


static func capsule(radius: float, height: float) -> CapsuleMesh:
	return _mesh("cap%s|%s" % [radius, height], func() -> Mesh:
		var mesh := CapsuleMesh.new()
		mesh.radius = radius
		mesh.height = height
		mesh.radial_segments = 16
		mesh.rings = 4
		return mesh)


static func sphere(radius: float) -> SphereMesh:
	return _mesh("sph%s" % radius, func() -> Mesh:
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 16
		mesh.rings = 8
		return mesh)


## Vòng dẹt nằm ngang (vòng cấp tháp, vòng hiệu ứng dưới chân địch).
static func ring(inner: float, outer: float) -> TorusMesh:
	return _mesh("tor%s|%s" % [inner, outer], func() -> Mesh:
		var mesh := TorusMesh.new()
		mesh.inner_radius = inner
		mesh.outer_radius = outer
		mesh.rings = 24
		mesh.ring_segments = 6
		return mesh)


## Quad dùng cho thanh máu; left_anchored: gốc ở mép trái để co giãn theo tỉ lệ máu.
static func bar_quad(width: float, height: float, left_anchored: bool) -> QuadMesh:
	return _mesh("quad%s|%s|%s" % [width, height, left_anchored], func() -> Mesh:
		var mesh := QuadMesh.new()
		mesh.size = Vector2(width, height)
		if left_anchored:
			mesh.center_offset = Vector3(width * 0.5, 0.0, 0.0)
		return mesh)


## Material chịu sáng, không bóng (màu đúng như thiết kế). alpha < 1 thì trong suốt.
static func lit(color: Color) -> StandardMaterial3D:
	return _material("lit%s" % color.to_html(), func() -> StandardMaterial3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 1.0
		mat.metallic_specular = 0.0
		if color.a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		return mat)


## Material tự phát sáng (không chịu bóng tối): đầu tháp Phép, đạn, tia.
static func glow(color: Color) -> StandardMaterial3D:
	return _material("glow%s" % color.to_html(), func() -> StandardMaterial3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if color.a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		return mat)


## Material luôn quay về camera, vẽ đè lên mọi thứ (thanh máu). priority: lớp vẽ (lớn = trên).
static func billboard(color: Color, priority: int) -> StandardMaterial3D:
	return _material("bb%s|%d" % [color.to_html(), priority], func() -> StandardMaterial3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.billboard_keep_scale = true
		mat.no_depth_test = true
		mat.render_priority = priority
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		return mat)


## Lớp phủ nháy trắng khi trúng đòn: chia 4 mức để vẫn dùng chung material.
static func flash_overlay(amount: float) -> StandardMaterial3D:
	var level := clampi(roundi(amount * 4.0), 0, 4)
	if level == 0:
		return null
	return _material("flash%d" % level, func() -> StandardMaterial3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1, level / 4.0 * 0.85)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		return mat)


## Một MeshInstance3D với mesh + material dùng chung. shadow: có đổ bóng không.
static func instance(mesh: Mesh, mat: Material, shadow: bool = true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## Bỏ cache (View3D gọi khi rời trận, để không giữ resource tới lúc thoát game).
static func clear_cache() -> void:
	_meshes.clear()
	_materials.clear()


static func _mesh(key: String, create: Callable) -> Mesh:
	if not _meshes.has(key):
		_meshes[key] = create.call()
	return _meshes[key]


static func _material(key: String, create: Callable) -> StandardMaterial3D:
	if not _materials.has(key):
		_materials[key] = create.call()
	return _materials[key]
