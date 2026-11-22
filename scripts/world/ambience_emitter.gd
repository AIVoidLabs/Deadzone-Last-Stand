class_name AmbienceEmitter
extends RefCounted
## 3B döngü yayıcıları. Konumlar ateş/neon/direk kodunun kendi yerleşiminden gelir: her kaynak
## kendi yerinde AmbienceEmitter.attach çağırır, koordinat ikinci kez yazılmaz.

const GROUP: StringName = &"ambience_emitters"
const LISTENER_GROUP: StringName = &"ambience_listener"


## parent'ın altına kind satırının (AmbienceData.EMITTERS) yayıcısını local_pos'a koyar.
static func attach(parent: Node3D, kind: StringName, local_pos: Vector3) -> void:
	if not (Tuning.FEATURE_SFX_AMBIENCE and Tuning.FEATURE_SFX_AMBIENCE_EMITTERS):
		return
	if not AmbienceData.EMITTERS.has(kind):
		push_error("Bilinmeyen ortam yayıcısı: %s" % kind)
		return
	var row: Dictionary = AmbienceData.EMITTERS[kind]
	AudioBuses.ensure()
	var stream: AudioStream = AmbienceStream.load_stream(row["file"], true)
	if stream == null:
		return
	# konumdan türetilen sabit "rastgelelik" (statik RNG çıkışta sızıntı yapar)
	var roll_a: float = float(absi(hash(local_pos) + Tuning.AMBIENCE_SEED) % 1000) / 1000.0
	var roll_b: float = float(absi(hash(local_pos) * 31 + Tuning.AMBIENCE_SEED) % 1000) / 1000.0
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = AmbienceData.BUS
	player.volume_db = row["volume_db"]
	player.unit_size = row["unit_size"]
	player.max_distance = row["max_distance"]
	player.attenuation_model = row["attenuation"] as AudioStreamPlayer3D.AttenuationModel
	player.pitch_scale = VoiceLimiter.pitch(row["pitch_variance"], roll_a)
	player.position = local_pos
	player.add_to_group(GROUP)
	parent.add_child(player)
	# rastgele başlangıç: aynı türden yayıcılar birbirine faz kilitli olmasın
	if player.is_inside_tree():
		player.play(roll_b * stream.get_length())


## Debug paneli: x = yayıcı sayısı, y = dinleyicinin max_distance içinde kalanlar.
static func counts(tree: SceneTree) -> Vector2i:
	var listener: Node3D = tree.get_first_node_in_group(LISTENER_GROUP) as Node3D
	var total: int = 0
	var audible: int = 0
	for node: Node in tree.get_nodes_in_group(GROUP):
		var player: AudioStreamPlayer3D = node as AudioStreamPlayer3D
		if player == null:
			continue
		total += 1
		if listener != null and player.global_position.distance_to(listener.global_position) <= player.max_distance:
			audible += 1
	return Vector2i(total, audible)
