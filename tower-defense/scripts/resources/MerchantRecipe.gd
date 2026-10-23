class_name MerchantRecipe
extends Resource
## Một đề nghị đổi đồ cố định của thương nhân NPC (file .tres trong res://resources/merchant/).
##
## give / receive: {khoá: số lượng}. Khoá là "coins", "dust" hoặc id vật phẩm (ItemDef.id).
## receive còn nhận khoá đặc biệt "random_skin:<bậc>" (vd "random_skin:3" = một skin Sử thi
## ngẫu nhiên, ưu tiên skin chưa có). Tỉ giá do người thiết kế quyết định, không có thị trường.

@export var id: StringName = &""
@export var title: String = ""
@export var give: Dictionary = {}
@export var receive: Dictionary = {}
## Thứ tự hiển thị.
@export var order: int = 0
