class_name VisualPool
extends RefCounted
## Pool cho các node hiển thị 3D: lấy ra / trả lại thay vì tạo / xoá liên tục trong trận.
## Node trả lại được ẩn đi và giữ nguyên trong cây, lần sau dùng lại cho cùng một "loại" (key).

## Tổng số node đã thực sự tạo mới (test dùng để kiểm tra không tạo thêm sau khi làm nóng).
var created := 0

var _free: Dictionary = {} # key -> Array[Node3D]


## Lấy một node của loại key; hết thì gọi create (Callable trả về Node3D, đã có cha).
func acquire(key: Variant, create: Callable) -> Node3D:
	var stack: Array = _free.get(key, [])
	if not stack.is_empty():
		var node: Node3D = stack.pop_back()
		node.visible = true
		return node
	created += 1
	return create.call()


func release(key: Variant, node: Node3D) -> void:
	node.visible = false
	if not _free.has(key):
		_free[key] = []
	_free[key].append(node)


func free_count(key: Variant) -> int:
	return _free.get(key, []).size()
