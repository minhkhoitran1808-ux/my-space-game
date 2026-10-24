class_name GameView
extends RefCounted
## Cầu nối giữa mô phỏng 2D và cách đang hiển thị (2D hoặc 3D).
##
## Camera 3D là trực giao (ortho), không xoay quanh Y, nên phép chiếu mặt đất (y = 0) lên màn hình
## là một phép biến đổi AFFINE. Gán ma trận đó (ground_transform) làm transform của các node 2D
## vẽ / nhận chuột trên mặt đất (BuildManager, TowerRangeDisplay, FxManager, AbilityManager...)
## thì toạ độ cục bộ của chúng chính là toạ độ mô phỏng:
##   - make_input_local(event).position = điểm mặt đất dưới con trỏ (raycast toán học, không cần physics);
##   - vòng tròn vẽ ở toạ độ mô phỏng hiện ra thành elip nằm đúng trên mặt đất 3D.
## Ở chế độ 2D, camera = null và mọi thứ là ma trận đơn vị như trước.

## Camera 3D đang dùng (null = chế độ 2D).
static var camera: FixedCamera = null
## Hàm chọn tháp theo vị trí màn hình (3D: tháp cao nên click vào thân tháp thay vì ô dưới chân).
static var tower_picker: Callable = Callable()


static func is_3d() -> bool:
	return camera != null and is_instance_valid(camera)


## Ma trận: toạ độ mô phỏng (pixel) -> toạ độ màn hình. Chế độ 2D: ma trận đơn vị.
static func ground_transform() -> Transform2D:
	if not is_3d():
		return Transform2D.IDENTITY
	var origin := camera.unproject_position(Vector3.ZERO)
	var x_axis := camera.unproject_position(Space3D.to_3d(Vector2(100.0, 0.0))) - origin
	var y_axis := camera.unproject_position(Space3D.to_3d(Vector2(0.0, 100.0))) - origin
	return Transform2D(x_axis / 100.0, y_axis / 100.0, origin)


## Vị trí màn hình của một điểm mô phỏng ở độ cao height (mét).
static func sim_to_screen(position: Vector2, height: float = 0.0) -> Vector2:
	if not is_3d():
		return position
	return camera.unproject_position(Space3D.to_3d(position, height))


## Điểm mô phỏng dưới một vị trí màn hình (trên mặt đất).
static func screen_to_sim(screen_position: Vector2) -> Vector2:
	if not is_3d():
		return screen_position
	var hit: Variant = camera.screen_to_ground(screen_position)
	return Space3D.to_2d(hit) if hit != null else screen_position


## Tỉ lệ để chữ vẽ trong không gian mặt đất hiện ra thẳng, đúng cỡ (bù phần mặt đất bị nén).
static func text_unsquash() -> Vector2:
	var t := ground_transform()
	return Vector2(1.0 / t.x.length(), 1.0 / t.y.length())


## Vẽ chữ ở toạ độ mô phỏng nhưng giữ đúng cỡ chữ trên màn hình (dùng trong _draw của node mặt đất).
static func draw_text(canvas: CanvasItem, font: Font, at: Vector2, text: String, size: int, color: Color,
		outline_color: Color = Color(0, 0, 0, 0), outline_size: int = 0) -> void:
	canvas.draw_set_transform(at, 0.0, text_unsquash())
	if outline_size > 0:
		canvas.draw_string_outline(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline_size, outline_color)
	canvas.draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	canvas.draw_set_transform(Vector2.ZERO)
