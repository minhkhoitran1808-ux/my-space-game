extends Node
## AudioManager (Autoload): phát hiệu ứng âm thanh theo TÊN.
##
##   AudioManager.play(&"enemy_death")
##
## Tìm file res://assets/audio/<tên>.ogg / .wav / .mp3. Nếu chưa có file thì im lặng,
## không báo lỗi; nên chỉ cần thả file âm thanh đúng tên vào assets/audio/ là game tự có tiếng.
## Danh sách tên đang dùng: xem SOUND_NAMES bên dưới (và README).

## Các tên âm thanh mà game đang phát (để tham khảo khi thêm file).
const SOUND_NAMES := [
	"shoot_archer", "shoot_cannon", "shoot_frost", "shoot_mage", "explosion",
	"enemy_death", "base_hit", "build", "upgrade", "sell",
	"wave_start", "wave_complete", "victory", "defeat",
	"ability_meteor", "ability_freeze",
]
const AUDIO_FOLDER := "res://assets/audio"
const EXTENSIONS := ["ogg", "wav", "mp3"]
## Số âm thanh có thể phát cùng lúc.
const POOL_SIZE := 12
## Cùng một âm thanh không phát lại trong khoảng này (giây) để tránh ồn khi bắn liên tục.
const MIN_REPEAT_INTERVAL := 0.06

## 0.0 - 1.0
var volume: float = 0.8:
	set(value):
		volume = clampf(value, 0.0, 1.0)
		for player in _players:
			player.volume_db = linear_to_db(volume)

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {} # StringName -> AudioStream (null = không có file)
var _last_played: Dictionary = {} # StringName -> thời điểm phát gần nhất (ms)


func _ready() -> void:
	# Vẫn phát được tiếng khi game tạm dừng (vd âm thanh của menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = linear_to_db(volume)
		add_child(player)
		_players.append(player)


## Phát âm thanh theo tên. Trả về true nếu thực sự có tiếng được phát.
func play(sound_name: StringName, pitch_variation: float = 0.05) -> bool:
	var stream := _get_stream(sound_name)
	if stream == null:
		return false

	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound_name, -100000)) < MIN_REPEAT_INTERVAL * 1000.0:
		return false
	_last_played[sound_name] = now

	var player := _get_free_player()
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()
	return true


func has_sound(sound_name: StringName) -> bool:
	return _get_stream(sound_name) != null


func _get_stream(sound_name: StringName) -> AudioStream:
	if not _streams.has(sound_name):
		_streams[sound_name] = null
		for extension in EXTENSIONS:
			var path := "%s/%s.%s" % [AUDIO_FOLDER, sound_name, extension]
			if ResourceLoader.exists(path):
				_streams[sound_name] = load(path)
				break
	return _streams[sound_name]


## Ưu tiên player đang rảnh; nếu tất cả đều bận thì dùng lại player đầu tiên.
func _get_free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0]
