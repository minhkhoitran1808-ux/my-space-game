extends Node
## GameManager (Autoload / Singleton).
##
## Giữ trạng thái toàn cục của một ván chơi: vàng, mạng sống của nhà chính,
## wave hiện tại và trạng thái game. Các hệ thống khác KHÔNG sửa biến trực tiếp
## mà gọi hàm (spend_gold, add_gold, lose_lives...) và lắng nghe signal để cập nhật.
##
## Ngoài ra giữ màn chơi đang chọn và là nơi DUY NHẤT đổi scene
## (start_level, go_to_level_select...), để luồng màn hình nằm gọn một chỗ.
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
## Phát ra khi đổi tốc độ game (x1, x2, x3).
signal game_speed_changed(speed: float)

enum GameState { PLAYING, VICTORY, DEFEAT }
## Độ khó: nhân máu địch, đổi máu nhà chính và hệ số thưởng meta.
enum Difficulty { EASY, NORMAL, HARD }

const DIFFICULTY_NAMES := ["Dễ", "Thường", "Khó"]
const DIFFICULTY_HP := [0.8, 1.0, 1.3]
## Máu nhà chính so với LevelData.starting_lives (20 -> 30 / 20 / 10).
const DIFFICULTY_LIVES := [1.5, 1.0, 0.5]
const DIFFICULTY_REWARD := [1.0, 1.3, 1.7]

const STARTING_GOLD := 200
const STARTING_LIVES := 20
## Các mức tốc độ người chơi có thể chọn (phím F / nút trên HUD).
const GAME_SPEEDS: Array[float] = [1.0, 2.0, 3.0]
## Tỉ lệ máu còn lại tối thiểu để đạt 3 sao / 2 sao (qua màn là có ít nhất 1 sao).
const THREE_STAR_LIVES_RATIO := 0.8
const TWO_STAR_LIVES_RATIO := 0.4

const LEVEL_CATALOG: LevelCatalog = preload("res://resources/levels/catalog.tres")
const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/menus/LevelSelect.tscn"
const GAME_SCENE := "res://scenes/main/Main.tscn"

var gold: int = STARTING_GOLD: set = _set_gold
var lives: int = STARTING_LIVES: set = _set_lives
var current_wave: int = 0
var total_waves: int = 0
var state: GameState = GameState.PLAYING: set = _set_state
var game_speed: float = 1.0
var starting_lives: int = STARTING_LIVES
## Màn đang chơi. Null = chưa chọn (vd chạy thẳng Main.tscn bằng F6) => dùng màn đầu tiên.
var current_level: LevelData = null
## true = đang chơi chế độ vô tận của current_level.
var endless_mode: bool = false
## Độ khó của ván (màn chọn màn đặt trước khi vào trận).
var difficulty: Difficulty = Difficulty.NORMAL

## Test hook: mở khoá mọi tháp bất kể tiến độ chiến dịch.
var unlock_all_towers := false
## Debug (Ctrl+3): nhà chính không mất máu.
var debug_invincible := false
## Tạm dừng chiến thuật (phím P): game đứng yên nhưng vẫn xây / bán / nâng cấp / đổi cách nhắm.
## Khác menu tạm dừng (Esc): khi menu mở thì không ra lệnh được.
var tactical_pause := false

## Test hook: true thì các hàm chuyển cảnh chỉ ghi lại scene được yêu cầu, không đổi thật.
var block_scene_changes := false
var last_requested_scene: String = ""


## Đưa mọi chỉ số về giá trị ban đầu. Gọi khi bắt đầu (hoặc chơi lại) một ván.
func reset(wave_count: int = 0, p_starting_gold: int = STARTING_GOLD, p_starting_lives: int = STARTING_LIVES) -> void:
	starting_lives = p_starting_lives
	gold = p_starting_gold
	lives = p_starting_lives
	current_wave = 0
	total_waves = wave_count
	wave_changed.emit(current_wave, total_waves)
	set_game_speed(1.0)
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
	if not is_playing() or debug_invincible:
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


## Số sao đạt được dựa trên số máu còn lại (0 nếu chưa thắng).
func calculate_stars() -> int:
	if state != GameState.VICTORY:
		return 0
	var ratio := float(lives) / maxf(starting_lives, 1.0)
	if ratio >= THREE_STAR_LIVES_RATIO:
		return 3
	if ratio >= TWO_STAR_LIVES_RATIO:
		return 2
	return 1


# --- Màn chơi + chuyển cảnh ------------------------------------------------------

func get_current_level() -> LevelData:
	if current_level == null:
		current_level = LEVEL_CATALOG.levels[0]
	return current_level


func get_next_level() -> LevelData:
	return LEVEL_CATALOG.get_next_level(get_current_level())


## Màn mở khoá một loại tháp (null nếu tháp luôn mở sẵn).
func get_unlock_level(tower_data: TowerData) -> LevelData:
	for level in LEVEL_CATALOG.levels:
		if level.unlocks_tower and level.unlocks_tower.id == tower_data.id:
			return level
	return null


## Tháp đã được mở khoá chưa (qua màn mở khoá ở bất kỳ độ khó nào).
func is_tower_unlocked(tower_data: TowerData) -> bool:
	if unlock_all_towers:
		return true
	var level := get_unlock_level(tower_data)
	return level == null or SaveManager.get_stars(level.id) > 0


## Hệ số máu địch của độ khó hiện tại.
func get_hp_multiplier() -> float:
	return DIFFICULTY_HP[difficulty]


## Máu nhà chính của một màn ở độ khó hiện tại.
func get_starting_lives(level: LevelData) -> int:
	return maxi(roundi(level.starting_lives * DIFFICULTY_LIVES[difficulty]), 1)


func start_level(level: LevelData, endless: bool = false) -> void:
	current_level = level
	endless_mode = endless
	_change_scene(GAME_SCENE)


## Chơi lại đúng màn và đúng chế độ (thường / vô tận) hiện tại.
func restart_level() -> void:
	start_level(get_current_level(), endless_mode)


func go_to_level_select() -> void:
	_change_scene(LEVEL_SELECT_SCENE)


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)


func _change_scene(path: String) -> void:
	last_requested_scene = path
	if block_scene_changes:
		return
	# Rời trận thì bỏ pause và trả tốc độ về x1.
	get_tree().paused = false
	set_game_speed(1.0)
	get_tree().change_scene_to_file(path)


# --- Tốc độ game ---------------------------------------------------------------

## Đổi tốc độ toàn game bằng Engine.time_scale (ảnh hưởng mọi delta và Timer).
func set_game_speed(speed: float) -> void:
	game_speed = speed
	Engine.time_scale = speed
	game_speed_changed.emit(game_speed)


## Chuyển sang mức tốc độ kế tiếp: x1 -> x2 -> x3 -> x1.
func cycle_game_speed() -> void:
	var index := GAME_SPEEDS.find(game_speed)
	set_game_speed(GAME_SPEEDS[(index + 1) % GAME_SPEEDS.size()])


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
