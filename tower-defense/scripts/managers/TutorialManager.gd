class_name TutorialManager
extends Node
## Hướng dẫn chơi lần đầu (màn 1, chế độ thường, khi chưa xem lần nào).
##
## Mỗi bước là một câu hướng dẫn + tên sự kiện sẽ hoàn thành bước đó. Main báo sự kiện
## bằng notify(&"tower_placed")..., TutorialManager không cần biết hệ thống nào phát ra.
## Bước có event rỗng sẽ tự xong sau AUTO_STEP_TIME giây.

## Phát ra khi đổi bước (text rỗng = hướng dẫn đã kết thúc).
signal step_changed(text: String, step_number: int, step_count: int)
signal finished

const DONE_FLAG := "tutorial_done"
const AUTO_STEP_TIME := 6.0

const STEPS := [
	{"text": "Chào mừng! Cung thủ đã được chọn sẵn ở thanh dưới. Click vào một ô cỏ cạnh đường để xây tháp.",
			"event": &"tower_placed"},
	{"text": "Tốt lắm! Xây thêm vài tháp nếu muốn, rồi bấm Space (hoặc nút góc phải) để gọi wave đầu tiên.",
			"event": &"wave_started"},
	{"text": "Tháp tự bắn địch trong tầm. Click vào một tháp đã xây để xem chỉ số của nó.",
			"event": &"tower_selected"},
	{"text": "Từ bảng này có thể Nâng cấp (U), Bán (X) và đổi cách chọn mục tiêu (T). Hãy thử nâng cấp một tháp.",
			"event": &"tower_upgraded"},
	{"text": "Khi nguy cấp hãy dùng kỹ năng: Q = Thiên thạch (chọn vùng), E = Băng giá (làm chậm toàn bản đồ).",
			"event": &"ability_cast"},
	{"text": "Xong phần hướng dẫn! Giữ vững nhà chính qua tất cả các wave. Chúc may mắn!", "event": &""},
]

var current_step := -1
var _auto_timer := 0.0


func is_active() -> bool:
	return current_step >= 0


## Bắt đầu hướng dẫn nếu người chơi chưa xem (hoặc force = true).
func start(force: bool = false) -> void:
	if SaveManager.get_flag(DONE_FLAG) and not force:
		return
	_go_to_step(0)


## Báo một sự kiện trong trận; nếu khớp với bước hiện tại thì sang bước sau.
func notify(event: StringName) -> void:
	if is_active() and STEPS[current_step].event == event:
		_go_to_step(current_step + 1)


func skip() -> void:
	_finish()


func _go_to_step(index: int) -> void:
	if index >= STEPS.size():
		_finish()
		return
	current_step = index
	_auto_timer = AUTO_STEP_TIME
	step_changed.emit(STEPS[index].text, index + 1, STEPS.size())


func _finish() -> void:
	if not is_active():
		return
	current_step = -1
	SaveManager.set_flag(DONE_FLAG, true)
	step_changed.emit("", 0, STEPS.size())
	finished.emit()


func _process(delta: float) -> void:
	if is_active() and STEPS[current_step].event == &"":
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			_go_to_step(current_step + 1)
