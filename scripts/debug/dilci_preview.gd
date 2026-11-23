extends Node3D
## Dilci klip önizlemesi (Aşama V.4): her klip bir modelde, üç çeşit sırayla; altında klip adı.
## Aç: godot --path . res://scenes/debug/dilci_preview.tscn [-- --capture=build/shots/dilci.png] [--capture-seconds=S]
## Hareketli: powershell -File tools/preview_movie.ps1 -Name dilci -Scene res://scenes/debug/dilci_preview.tscn

const MODEL: PackedScene = preload("res://assets/models/characters/zombie_dilci.glb")
const CLIPS: Array[StringName] = [&"idle", &"walk", &"windup", &"lash", &"pull", &"stagger", &"death_a", &"spawn"]
## Tek seferlik klipler araya bekleme koyarak tekrar eder (sn).
const ONE_SHOT_GAP: float = 0.6
const SPACING: float = 1.5
const PER_ROW: int = 4
const ROW_GAP: float = 2.4

const SHADER: Shader = preload("res://assets/shaders/zombie_vc.gdshader")
## Önizlemede dilin uzandığı mesafe (m).
const TONGUE_REACH: float = 2.5

var _pull_started: Dictionary = {}

var _shared: ShaderMaterial
## --focus=N: kamera N. klibin modeline yakından bakar (-1 hepsi).
var _focus: int = -1
var _positions: Array[Vector3] = []
var _players: Array[AnimationPlayer] = []
var _tongues: Array[DilciTongue] = []
var _models: Array[Node3D] = []
## --no-tongue: yordamsal dil eklenmez.
var _with_tongue: bool = true
var _capture_path: String = ""
var _capture_seconds: float = 2.0
var _time: float = 0.0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture_path = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-seconds="):
			_capture_seconds = arg.trim_prefix("--capture-seconds=").to_float()
		elif arg.begins_with("--focus="):
			_focus = arg.trim_prefix("--focus=").to_int()
		elif arg == "--no-tongue":
			_with_tongue = false
	# iki sıra: üstte hareket, altta saldırı ve tepkiler
	for i: int in CLIPS.size():
		var column: int = i % PER_ROW
		@warning_ignore("integer_division")
		var row: int = i / PER_ROW
		_add_model(i, Vector3((column - (PER_ROW - 1) * 0.5) * SPACING, 0.0, -row * ROW_GAP))
	_add_environment()


func _add_model(index: int, at: Vector3) -> void:
	var model: Node3D = MODEL.instantiate() as Node3D
	add_child(model)
	model.position = at
	_positions.append(at)
	# çeşitler: her modelde birini bırak
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	for m: int in meshes.size():
		var mesh: MeshInstance3D = meshes[m] as MeshInstance3D
		mesh.visible = m == index % meshes.size()
		mesh.material_override = _material()
	var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_players.append(player)
	_models.append(model)
	if _with_tongue:
		var tongue: DilciTongue = DilciTongue.new()
		add_child(tongue)
		tongue.setup(model, model.find_child("GeneralSkeleton", true, false) as Skeleton3D)
		tongue.set_active(true)
		_tongues.append(tongue)
	player.animation_finished.connect(_on_finished.bind(player))
	_play(index)
	var label: Label3D = Label3D.new()
	label.text = CLIPS[index]
	label.position = at + Vector3(0.0, 0.02, 0.7)
	label.rotation_degrees.x = -90.0
	label.pixel_size = 0.003
	add_child(label)


func _material() -> ShaderMaterial:
	if _shared == null:
		_shared = ShaderMaterial.new()
		_shared.shader = SHADER
	return _shared


func _on_finished(_clip: StringName, player: AnimationPlayer) -> void:
	await get_tree().create_timer(ONE_SHOT_GAP).timeout
	_play(_players.find(player))


## Klibi başlatır; dil klibe uyar (hazırlıkta boğaza çekilir, şaklamada fırlar, çekişte tutunur).
func _play(index: int) -> void:
	_players[index].play(CLIPS[index])
	if not _with_tongue:
		return
	var tongue: DilciTongue = _tongues[index]
	var model: Node3D = _models[index]
	var ahead: Vector3 = model.global_position + model.global_transform.basis.z * TONGUE_REACH + Vector3(0.0, 1.0, 0.0)
	match CLIPS[index]:
		&"windup":
			tongue.set_windup(true)
		&"lash":
			tongue.set_windup(false)
			tongue.on_event({"shoot": true, "to": ahead, "time": TONGUE_REACH / 16.0, "hold": 0.3})
		&"pull":
			if not _pull_started.has(index):
				_pull_started[index] = true
				tongue.on_event({"shoot": true, "to": ahead, "time": TONGUE_REACH / 16.0})


func _add_environment() -> void:
	var cam: Camera3D = Camera3D.new()
	cam.position = Vector3(0.0, 3.6, 4.6)
	cam.rotation_degrees.x = -30.0
	cam.fov = 52.0
	add_child(cam)
	if _focus >= 0 and _focus < _positions.size():
		var target: Vector3 = _positions[_focus] + Vector3(0.0, 1.35, 0.0)
		cam.position = target + Vector3(0.7, 0.15, 1.1)
		cam.look_at(target)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var env: WorldEnvironment = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.13, 0.15)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	add_child(env)
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(20.0, 8.0)
	ground.mesh = plane
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.22)
	ground.material_override = mat
	add_child(ground)


func _process(delta: float) -> void:
	if _capture_path == "":
		return
	_time += delta
	if _time < _capture_seconds:
		return
	var path: String = ProjectSettings.globalize_path("res://").path_join(_capture_path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE ", _capture_path)
	get_tree().quit()


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"ui_cancel"):
		get_tree().quit()
