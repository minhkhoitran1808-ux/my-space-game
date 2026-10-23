class_name EnemyData
extends Resource
## Dữ liệu cấu hình cho một loại địch.
##
## Muốn thêm loại địch mới: tạo file .tres mới trong res://resources/enemies/
## (chuột phải > New Resource > EnemyData) rồi chỉnh chỉ số trong Inspector.
## WaveManager tự quét thư mục này, nên trong file wave chỉ cần ghi "id".

## Hình dạng vẽ tạm khi chưa có sprite.
enum Shape { CIRCLE, SQUARE, TRIANGLE, DIAMOND, BAT }

## Mã định danh, dùng trong các file data/waves/*.json. Phải duy nhất.
@export var id: StringName = &"basic"
@export var display_name: String = "Địch"

@export_group("Chỉ số")
@export var max_health: float = 60.0
## Tốc độ di chuyển (pixel / giây).
@export var speed: float = 90.0
## Vàng nhận được khi tiêu diệt.
@export var reward: int = 8
## Số mạng nhà chính bị trừ khi địch đi tới cuối đường.
@export var damage_to_base: int = 1

@export_group("Di chuyển")
## Địch bay: đi theo làn trên không (thẳng tới nhà chính) và chỉ trúng đòn của
## tháp / kỹ năng bắn được mục tiêu trên không.
@export var is_flying: bool = false

@export_group("Kháng")
## Giảm sát thương Vật lý (0.6 = giảm 60%).
@export_range(0.0, 0.9, 0.05) var armor: float = 0.0
## Giảm sát thương Phép.
@export_range(0.0, 0.9, 0.05) var magic_resist: float = 0.0
## Giảm hiệu quả làm chậm (0.5 = chỉ chịu một nửa).
@export_range(0.0, 1.0, 0.05) var slow_resistance: float = 0.0

@export_group("Khi chết")
## Loại địch sinh ra khi con này chết (để trống nếu không có).
@export var spawn_on_death: EnemyData
@export var spawn_on_death_count: int = 0

@export_group("Hiển thị")
@export var color: Color = Color(0.85, 0.25, 0.25)
@export var radius: float = 14.0
@export var shape: Shape = Shape.CIRCLE

@export_group("Scene")
## Scene sẽ được instantiate khi spawn (gốc phải là Enemy / PathFollow2D).
@export var scene: PackedScene


## Tỉ lệ sát thương bị giảm theo loại sát thương.
func get_resistance(damage_type: DamageInfo.Type) -> float:
	match damage_type:
		DamageInfo.Type.PHYSICAL:
			return armor
		DamageInfo.Type.MAGIC:
			return magic_resist
		_:
			return 0.0
