extends Node
## GameManager (Autoload / Singleton).
##
## Giữ trạng thái toàn cục của một ván chơi: vàng, mạng sống của nhà chính,
## wave hiện tại và trạng thái game. Các hệ thống khác KHÔNG sửa biến trực tiếp
## mà gọi hàm (spend_gold, add_gold, lose_lives...) và lắng nghe signal để cập nhật.
##
## Lưu ý: không đặt class_name vì tên Autoload "GameManager" đã là tên toàn cục.

## Phát ra mỗi khi số vàng thay đổi.
signal gold_changed(gold: int)
## Phát ra mỗi khi mạng sống của nhà chính thay đổi.
signal lives_changed(lives: int)
## Phát ra khi wave hiện tại hoặc tổng số wave thay đổi.
signal wave_changed(current_wave: int, total_waves: int)
## Phát ra khi trạng thái game thay đổi (PLAYING -> VICTORY / DEFEAT).
signal state_changed(state: GameState)

enum GameState { PLAYING, VICTORY, DEFEAT }

const STARTING_GOLD := 150
const STARTING_LIVES := 20

var gold: int = STARTING_GOLD: set = _set_gold
var lives: int = STARTING_LIVES: set = _set_lives
var current_wave: int = 0
var total_waves: int = 0
var state: GameState = GameState.PLAYING: set = _set_state


## Đưa mọi chỉ số về giá trị ban đầu. Gọi khi bắt đầu (hoặc chơi lại) một ván.
func reset(wave_count: int = 0) -> void:
	gold = STARTING_GOLD
	lives = STARTING_LIVES
	current_wave = 0
	total_waves = wave_count
	wave_changed.emit(current_wave, total_waves)
	state = GameState.PLAYING


func is_playing() -> bool:
	return state == GameState.PLAYING


# --- Vàng ---------------------------------------------------------------------

func can_afford(amount: int) -> bool:
	return gold >= amount


## Trừ vàng nếu đủ. Trả về true nếu giao dịch thành công.
func spend_gold(amount: int) -> bool:
	if not can_afford(amount):
		return false
	gold -= amount
	return true


func add_gold(amount: int) -> void:
	if amount != 0:
		gold += amount


# --- Mạng sống ----------------------------------------------------------------

## Gọi khi địch chạm tới nhà chính. Hết mạng => thua.
func lose_lives(amount: int) -> void:
	if not is_playing():
		return
	lives -= amount
	if lives <= 0:
		state = GameState.DEFEAT


# --- Wave ---------------------------------------------------------------------

func set_current_wave(wave_number: int) -> void:
	current_wave = wave_number
	wave_changed.emit(current_wave, total_waves)


## Gọi khi đã vượt qua toàn bộ wave.
func win() -> void:
	if is_playing():
		state = GameState.VICTORY


# --- Setter (phát signal khi giá trị đổi) -------------------------------------

func _set_gold(value: int) -> void:
	gold = maxi(value, 0)
	gold_changed.emit(gold)


func _set_lives(value: int) -> void:
	lives = maxi(value, 0)
	lives_changed.emit(lives)


func _set_state(value: GameState) -> void:
	if state == value:
		return
	state = value
	state_changed.emit(state)
