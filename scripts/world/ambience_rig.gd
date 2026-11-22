class_name AmbienceRig
extends Node3D
## Ortam ses düzeneği: askeri izleyen AudioListener3D (3B sesler kamerayla değil askerle ölçülür),
## konumsuz rüzgar / şehir uğultusu döngüleri ve uzak tek seferlik sesler (AmbienceScheduler).
## Düğüm dönmez: dinleyici yönü sabit kalır (kamera sabit açılı), askerin dönüşü panlamayı bozmaz.

var target: Node3D = null
var _scheduler: AmbienceScheduler = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _listener: AudioListener3D = null
## Uzak sesler için sabit oynatıcı havuzu (her seferinde yaratılmaz).
var _distant_players: Array[AudioStreamPlayer3D] = []


func _ready() -> void:
	name = "AmbienceRig"
	if not Tuning.FEATURE_SFX_AMBIENCE:
		return
	AudioBuses.ensure()
	_rng.seed = Tuning.AMBIENCE_SEED + 1
	_listener = AudioListener3D.new()
	_listener.add_to_group(AmbienceEmitter.LISTENER_GROUP)
	add_child(_listener)
	_listener.make_current()
	if Tuning.FEATURE_SFX_AMBIENCE_BEDS:
		for row: Dictionary in AmbienceData.BEDS:
			_add_bed(row)
	if Tuning.FEATURE_SFX_AMBIENCE_DISTANT:
		_build_distant_pool()
		_scheduler = AmbienceScheduler.new(AmbienceData.distant_weights(), Tuning.AMBIENCE_DISTANT_INTERVAL_MIN, Tuning.AMBIENCE_DISTANT_INTERVAL_MAX, Tuning.AMBIENCE_SEED + 2)


func _process(delta: float) -> void:
	if target != null:
		global_position = target.global_position
	if _scheduler == null:
		return
	var index: int = _scheduler.step(delta)
	if index >= 0:
		_play_distant(AmbienceData.DISTANT[index], _scheduler.last_angle)


## Kapanışta çalan akışlar ses sunucusunda asılı kalmasın (Audio autoload'ıyla aynı yöntem; çıkışta ara sıra ObjectDB uyarısı çıkabilir).
func _exit_tree() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		for node: Node in tree.get_nodes_in_group(AmbienceEmitter.GROUP):
			_release(node)
	for node: Node in get_children():
		_release(node)


func _release(node: Node) -> void:
	if node is AudioStreamPlayer3D:
		(node as AudioStreamPlayer3D).stop()
		(node as AudioStreamPlayer3D).stream = null
	elif node is AudioStreamPlayer:
		(node as AudioStreamPlayer).stop()
		(node as AudioStreamPlayer).stream = null


func _add_bed(row: Dictionary) -> void:
	var stream: AudioStream = AmbienceStream.load_stream(row["file"], true)
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = AmbienceData.BUS
	player.volume_db = row["volume_db"]
	add_child(player)
	player.play(_rng.randf() * stream.get_length())


func _build_distant_pool() -> void:
	for i: int in Tuning.AMBIENCE_DISTANT_POOL_SIZE:
		var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		player.bus = AmbienceData.BUS
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED  # düzey sabit, yön panlamayla duyulur
		add_child(player)
		_distant_players.append(player)


## Uzak ses: askerden sabit uzaklıkta, rastgele yönde; boş havuz oynatıcısı yoksa atlanır.
func _play_distant(row: Dictionary, angle: float) -> void:
	for player: AudioStreamPlayer3D in _distant_players:
		if player.playing:
			continue
		var stream: AudioStream = AmbienceStream.load_stream(row["file"], false)
		if stream == null:
			return
		player.stream = stream
		player.volume_db = row["volume_db"]
		player.pitch_scale = VoiceLimiter.pitch(row["pitch_variance"], _rng.randf())
		player.position = Vector3(cos(angle), 0.0, sin(angle)) * Tuning.AMBIENCE_DISTANT_DISTANCE
		player.play()
		return
