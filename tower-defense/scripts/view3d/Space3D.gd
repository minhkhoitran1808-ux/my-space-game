class_name Space3D
extends RefCounted
## Quy đổi giữa mô phỏng 2D (pixel) và cảnh 3D (mét).
##
## Toàn bộ luật chơi vẫn chạy trên 2D; lớp hiển thị 3D chỉ "soi" lại. Quy ước:
## 1 ô lưới = 64 px = 2 m  =>  1 m = 32 px. Điểm 2D (x, y) nằm ở (x / 32, h, y / 32):
## mặt đất là mặt phẳng y = 0, trục 2D "y xuống" thành trục 3D +Z (về phía người xem).

const PX_PER_M := 32.0


static func to_3d(position_2d: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(position_2d.x / PX_PER_M, height, position_2d.y / PX_PER_M)


## Bỏ độ cao, chỉ giữ X / Z.
static func to_2d(position_3d: Vector3) -> Vector2:
	return Vector2(position_3d.x, position_3d.z) * PX_PER_M


static func px_to_m(pixels: float) -> float:
	return pixels / PX_PER_M


## Góc quay quanh trục Y để một vật nhìn theo hướng 2D (mặc định vật nhìn về -Z).
static func yaw_of(direction_2d: Vector2) -> float:
	return atan2(-direction_2d.x, -direction_2d.y)
