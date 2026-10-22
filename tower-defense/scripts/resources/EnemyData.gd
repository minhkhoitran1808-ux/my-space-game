class_name EnemyData
extends Resource
## Dữ liệu cấu hình cho một loại địch.
##
## Muốn thêm loại địch mới: tạo file .tres mới trong res://resources/enemies/
## (chuột phải > New Resource > EnemyData) rồi chỉnh chỉ số trong Inspector.

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

@export_group("Hiển thị")
@export var color: Color = Color(0.85, 0.25, 0.25)
@export var radius: float = 14.0

@export_group("Scene")
## Scene sẽ được instantiate khi spawn (gốc phải là Enemy / PathFollow2D).
@export var scene: PackedScene
