class_name FixedCamera
extends Camera3D
## Camera 3D cố định: chiếu trực giao (Orthogonal), nghiêng PITCH_DEG, không xoay quanh Y.
##
## Căn khung để vùng chơi (GameConfig.BUILD_AREA) nằm gọn giữa thanh trên và thanh dưới
## của HUD ở mọi tỉ lệ màn hình; tự căn lại khi cửa sổ đổi kích thước.
## Ortho: mọi ô có cùng kích thước trên màn hình, vòng tầm bắn tròn đều ở mọi chỗ.

const PITCH_DEG := 55.0
## Chiều cao vật cao nhất (tháp cấp 4) để đỉnh tháp ở hàng trên cùng không bị cắt.
const MAX_OBJECT_HEIGHT := 2.6
## Lề mỗi bên (mét).
const MARGIN := 0.6
## Lùi camera khỏi tâm theo hướng nhìn (ortho: không đổi kích thước hình, chỉ cần nằm trong near / far).
const DISTANCE := 60.0

## Dải màn hình (pixel, theo kích thước gốc 1280×720) dành cho vùng chơi: trừ thanh trên / dưới.
var screen_band := Rect2(0, GameConfig.BUILD_AREA.position.y, 1280, GameConfig.BUILD_AREA.size.y)
## Rung màn hình (mét, cộng vào h_offset / v_offset).
var shake := Vector2.ZERO

var _base_offset := Vector2.ZERO


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	keep_aspect = KEEP_HEIGHT
	near = 0.5
	far = 200.0
	rotation = Vector3(-deg_to_rad(PITCH_DEG), 0.0, 0.0)
	get_viewport().size_changed.connect(fit)
	fit()


func _process(_delta: float) -> void:
	h_offset = _base_offset.x + shake.x
	v_offset = _base_offset.y + shake.y


## Tính lại size (chiều cao nhìn thấy, mét) và vị trí để vùng chơi vừa dải screen_band.
func fit() -> void:
	var area := GameConfig.BUILD_AREA
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var pitch := deg_to_rad(PITCH_DEG)
	var width_m := Space3D.px_to_m(area.size.x) + MARGIN * 2.0
	var depth_m := Space3D.px_to_m(area.size.y)
	var need_h := depth_m * sin(pitch) + MAX_OBJECT_HEIGHT * cos(pitch) + MARGIN * 2.0
	# Dải dành cho vùng chơi chỉ chiếm một phần chiều cao màn hình (phần còn lại là thanh UI).
	var band_fraction := screen_band.size.y / 720.0
	size = maxf(need_h / band_fraction, width_m / aspect)
	var center := Space3D.to_3d(area.get_center())
	global_position = center + global_transform.basis.z * DISTANCE
	# Tâm dải có thể lệch khỏi tâm màn hình: dời camera theo chiều dọc
	# (v_offset > 0 = camera lên => nội dung đi xuống trên màn hình).
	var band_center_y := screen_band.get_center().y / 720.0
	_base_offset = Vector2(0.0, (band_center_y - 0.5) * size)
	# Đỉnh tháp nhô lên làm khối hình lệch lên trên: đẩy nội dung xuống nửa phần nhô.
	_base_offset.y += MAX_OBJECT_HEIGHT * cos(pitch) * 0.5
	_process(0.0)


## Điểm trên mặt đất (y = 0) dưới một vị trí màn hình; null nếu tia không chạm đất.
func screen_to_ground(screen_position: Vector2) -> Variant:
	var origin := project_ray_origin(screen_position)
	var direction := project_ray_normal(screen_position)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
