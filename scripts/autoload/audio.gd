extends Node
## Ses havuzu: sabit sayıda oynatıcı, her ses SoundData satırından. Oyun kodu yalnız Audio.play(id) çağırır.
## Sesler "SFX" veri yolundan çıkar (ileride ayarlardaki ses düzeyi buraya bağlanır).

const BUS: StringName = &"SFX"

## Açılıştan beri çalınan ses sayısı (debug paneli).
var played_total: int = 0

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
## Her oynatıcının şu an çaldığı ses (boşsa &"").
var _playing_id: Array[StringName] = []
var _limiter: VoiceLimiter = VoiceLimiter.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	# Oyun sonu duraklamasında son sesler kesilmesin.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not Tuning.FEATURE_SFX:
		return
	_rng.randomize()
	_ensure_bus()
	_load_streams()
	for i: int in Tuning.SFX_POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)
		_playing_id.append(&"")


func play(id: StringName) -> void:
	if not Tuning.FEATURE_SFX or not _streams.has(id):
		return
	var row: Dictionary = SoundData.get_row(id)
	var now: float = Time.get_ticks_usec() / 1000000.0
	if not _limiter.request(id, now, _count_playing(id), row["max_voices"], row["min_interval"]):
		return
	var index: int = _free_player()
	if index < 0:
		return
	var variants: Array = _streams[id]
	var player: AudioStreamPlayer = _players[index]
	player.stream = variants[_rng.randi() % variants.size()]
	player.volume_db = row["volume_db"]
	player.pitch_scale = VoiceLimiter.pitch(row["pitch_variance"], _rng.randf())
	_playing_id[index] = id
	player.play()
	played_total += 1


## Debug paneli için: şu an çalan ses sayısı.
func active_voices() -> int:
	var count: int = 0
	for player: AudioStreamPlayer in _players:
		if player.playing:
			count += 1
	return count


func _count_playing(id: StringName) -> int:
	var count: int = 0
	for i: int in _players.size():
		if _playing_id[i] == id and _players[i].playing:
			count += 1
	return count


func _free_player() -> int:
	for i: int in _players.size():
		if not _players[i].playing:
			return i
	return -1


func _load_streams() -> void:
	for id: StringName in SoundData.TABLE:
		var row: Dictionary = SoundData.TABLE[id]
		if not row["enabled"]:
			continue
		var variants: Array[AudioStream] = []
		for file: String in row["files"]:
			var stream: AudioStream = load(SoundData.path_of(file)) as AudioStream
			if stream == null:
				push_error("Ses yüklenemedi: %s" % SoundData.path_of(file))
				continue
			variants.append(stream)
		if not variants.is_empty():
			_streams[id] = variants


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS)
	AudioServer.set_bus_send(index, &"Master")
