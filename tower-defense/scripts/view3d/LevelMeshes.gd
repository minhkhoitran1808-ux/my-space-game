class_name LevelMeshes
extends RefCounted
## Dựng mesh cho cảnh 3D từ dữ liệu 2D của bản đồ: dải đường đi, khối đa giác (đồi, bùn).
## Mọi hàm nhận toạ độ 2D (pixel) và trả về mesh ở toạ độ 3D (mét).
## Mọi tam giác được tự xếp đúng chiều theo pháp tuyến mong muốn (Godot lấy chiều kim đồng hồ
## làm mặt trước), nên không bị tối do lật mặt.


## Dải đường đi bề rộng width_px dọc một Path2D, nằm ở độ cao height.
## Mỗi đoạn nhỏ là một hình chữ nhật, mỗi điểm gãy của curve thêm một đĩa tròn để bo góc
## (giống cách Ground vẽ bản 2D).
static func path_ribbon(paths: Array[Path2D], width_px: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := Space3D.px_to_m(width_px) * 0.5
	for path in paths:
		var baked := path.curve.get_baked_points()
		for i in baked.size() - 1:
			var a := Space3D.to_3d(path.to_global(baked[i]), height)
			var b := Space3D.to_3d(path.to_global(baked[i + 1]), height)
			if a.is_equal_approx(b):
				continue
			var side := (b - a).cross(Vector3.UP).normalized() * half
			_quad(st, a - side, a + side, b + side, b - side, Vector3.UP)
		for i in path.curve.point_count:
			_disc(st, Space3D.to_3d(path.to_global(path.curve.get_point_position(i)), height), half, 16)
	return st.commit()


## Khối lăng trụ đứng từ một đa giác 2D (toạ độ toàn cục, pixel): mặt trên ở top, mặt bên
## xuống tới y = 0. top gần 0 thì chỉ dựng mặt trên (mảng phẳng).
static func polygon_prism(points: PackedVector2Array, top: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(points)
	for i in range(0, indices.size(), 3):
		_tri(st, Space3D.to_3d(points[indices[i]], top), Space3D.to_3d(points[indices[i + 1]], top),
				Space3D.to_3d(points[indices[i + 2]], top), Vector3.UP)
	if top > 0.05:
		for i in points.size():
			var a := Space3D.to_3d(points[i], top)
			var b := Space3D.to_3d(points[(i + 1) % points.size()], top)
			var normal := (b - a).cross(Vector3.UP).normalized()
			# Hướng mặt bên ra ngoài bất kể đa giác vẽ theo chiều nào.
			var probe := (points[i] + points[(i + 1) % points.size()]) * 0.5 + Vector2(normal.x, normal.z) * 2.0
			if Geometry2D.is_point_in_polygon(probe, points):
				normal = -normal
			_quad(st, a, b, Vector3(b.x, 0.0, b.z), Vector3(a.x, 0.0, a.z), normal)
	return st.commit()


## Mặt phẳng ngang hình chữ nhật (tâm, kích thước theo mét).
static func flat_quad(center: Vector3, size: Vector2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := size.x * 0.5
	var hz := size.y * 0.5
	_quad(st, center + Vector3(-hx, 0, -hz), center + Vector3(-hx, 0, hz),
			center + Vector3(hx, 0, hz), center + Vector3(hx, 0, -hz), Vector3.UP)
	return st.commit()


## Hai tam giác của tứ giác lồi a-b-c-d, mặt trước hướng theo normal.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	_tri(st, a, b, c, normal)
	_tri(st, a, c, d, normal)


## Một tam giác, tự đảo thứ tự đỉnh để mặt trước (chiều kim đồng hồ khi nhìn từ phía normal)
## hướng theo normal.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	st.set_normal(normal)
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var swap := b
		b = c
		c = swap
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _disc(st: SurfaceTool, center: Vector3, radius: float, segments: int) -> void:
	for i in segments:
		var a := TAU * i / segments
		var b := TAU * (i + 1) / segments
		_tri(st, center, center + Vector3(cos(a), 0.0, sin(a)) * radius,
				center + Vector3(cos(b), 0.0, sin(b)) * radius, Vector3.UP)
