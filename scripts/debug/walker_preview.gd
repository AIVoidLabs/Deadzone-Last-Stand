extends Node3D
## Yürüyen oyun modeli önizlemesi (Aşama V.5): dört çeşit yan yana, köşe renkli zombie_vc ile.
## Aç: godot --path . res://scenes/debug/walker_preview.tscn [-- --capture=build/shots/walker_game_godot.png]
##   [--capture-seconds=S] [--gamecam] (oyun kamerası açısı ve uzaklığı, Tuning'den)
##   [--clip=walk] dört çeşit aynı klibi oynar (tek seferlikler araya bekleme koyup tekrar eder)
##   [--clips] her klip bir modelde (iki sıra, çeşitler sırayla), altında klip adı
##   [--side] yakın yan kamera (ayak kayması için) [--move] modeller yürüyüş hızıyla ilerler, zeminde çizgiler
##   [--only=N] yalnız N. çeşit (0 Office, 1 Worker, 2 Skinny, 3 Civilian), yakın kamera
## Başlangıçta her çeşit için iskelet, ağ ve klip bilgisini yazar (WALKER satırları).
## Hareketli: powershell -File tools/preview_movie.ps1 -Name walker_clips -Scene res://scenes/debug/walker_preview.tscn -GameArgs "--clips"

const MODELS: Array[PackedScene] = [
	preload("res://assets/models/characters/zombie_walker_office.glb"),
	preload("res://assets/models/characters/zombie_walker_worker.glb"),
	preload("res://assets/models/characters/zombie_walker_skinny.glb"),
	preload("res://assets/models/characters/zombie_walker_civilian.glb"),
]
const NAMES: Array[String] = ["Office", "Worker", "Skinny", "Civilian"]
const CLIPS: Array[StringName] = [&"idle", &"walk", &"windup", &"attack", &"stagger", &"death_a", &"death_b", &"spawn"]
const SHADER: Shader = preload("res://assets/shaders/zombie_vc.gdshader")
const SPACING: float = 1.1
const PER_ROW: int = 4
const ROW_GAP: float = 2.4
const ONE_SHOT_GAP: float = 0.6
## walker_anims.py: basan ayağın geri kayma hızı (m/sn, bacak boyu 0.88 m için) ve bacak boyu referansı.
const WALK_SPEED: float = 0.85
const REF_LEG: float = 0.88
## --move: modeller bu aralıkta ilerleyip başa sarar (m).
const MOVE_SPAN: float = 4.0

var _capture_path: String = ""
var _capture_seconds: float = 1.5
var _gamecam: bool = false
var _side: bool = false
var _move: bool = false
var _clip: StringName = &""
var _grid: bool = false
var _only: int = -1
var _time: float = 0.0
var _material: ShaderMaterial
var _models: Array[Node3D] = []
var _speeds: Array[float] = []


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture_path = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-seconds="):
			_capture_seconds = arg.trim_prefix("--capture-seconds=").to_float()
		elif arg.begins_with("--clip="):
			_clip = StringName(arg.trim_prefix("--clip="))
		elif arg == "--clips":
			_grid = true
		elif arg == "--gamecam":
			_gamecam = true
		elif arg == "--side":
			_side = true
		elif arg == "--move":
			_move = true
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").to_int()
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	if _grid:
		for i: int in CLIPS.size():
			var column: int = i % PER_ROW
			@warning_ignore("integer_division")
			var row: int = i / PER_ROW
			# arka sıra yarım aralık kaydırılır: öndekilerin arkasında kalmasın
			var at: Vector3 = Vector3((column - (PER_ROW - 1) * 0.5 + row * 0.5) * 1.5, 0.0, -row * ROW_GAP)
			_add_model(i % MODELS.size(), at, CLIPS[i], i < MODELS.size())
			_add_label(CLIPS[i], at)
	elif _only >= 0:
		_add_model(_only, Vector3(-0.8 if _move and _side else 0.0, 0.0, 0.0), _clip, true)
	else:
		for i: int in MODELS.size():
			var x: float = (i - (MODELS.size() - 1) * 0.5) * SPACING
			_add_model(i, Vector3(x, 0.0, 0.0), _clip, true)
	_add_environment()


func _add_model(variant: int, at: Vector3, clip: StringName, report: bool) -> void:
	var model: Node3D = MODELS[variant].instantiate() as Node3D
	add_child(model)
	model.position = at
	if _side:
		model.rotation_degrees.y = 90.0     # profil: +X'e bakar
	if report:
		_report(NAMES[variant], model)
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = _material
	_models.append(model)
	_speeds.append(WALK_SPEED * _leg_length(model) / REF_LEG)
	var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null or clip == &"":
		return
	player.animation_finished.connect(_on_finished.bind(player, clip))
	player.play(clip)


func _on_finished(_name: StringName, player: AnimationPlayer, clip: StringName) -> void:
	await get_tree().create_timer(ONE_SHOT_GAP).timeout
	player.play(clip)
	player.seek(0.0, true)


func _leg_length(model: Node3D) -> float:
	var skeleton: Skeleton3D = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	if skeleton == null:
		return REF_LEG
	# içe aktarım kemikleri insansı profile göre yeniden adlandırır (thigh_r -> RightUpperLeg)
	var hip: Vector3 = skeleton.get_bone_global_rest(skeleton.find_bone(&"RightUpperLeg")).origin
	var knee: Vector3 = skeleton.get_bone_global_rest(skeleton.find_bone(&"RightLowerLeg")).origin
	var ankle: Vector3 = skeleton.get_bone_global_rest(skeleton.find_bone(&"RightFoot")).origin
	return hip.distance_to(knee) + knee.distance_to(ankle)


## Çeşidin iskeletini, ağını ve kliplerini yazar.
func _report(variant: String, model: Node3D) -> void:
	var skeleton: Skeleton3D = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	var bones: int = skeleton.get_bone_count() if skeleton != null else -1
	var tris: int = 0
	var height: float = 0.0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		for surface: int in mesh.get_surface_count():
			var indices: PackedInt32Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
			@warning_ignore("integer_division")
			tris += indices.size() / 3
		height = maxf(height, mesh_instance.get_aabb().end.y)
	var head: int = skeleton.find_bone(&"Head") if skeleton != null else -1
	var jaw: int = skeleton.find_bone(&"jaw") if skeleton != null else -1
	print("WALKER %s: GeneralSkeleton %s, %d kemik, Head %d, jaw %d, %d üçgen, boy %.2f m, bacak %.3f m" % [
		variant, "var" if skeleton != null else "YOK", bones, head, jaw, tris, height, _leg_length(model)])
	var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null:
		print("WALKER %s: AnimationPlayer YOK" % variant)
		return
	var parts: PackedStringArray = []
	for clip: StringName in player.get_animation_list():
		var anim: Animation = player.get_animation(clip)
		parts.append("%s %.3fs%s" % [clip, anim.length, " loop" if anim.loop_mode != Animation.LOOP_NONE else ""])
	print("WALKER %s klipler: %s" % [variant, ", ".join(parts)])


func _add_label(text: String, at: Vector3) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.position = at + Vector3(0.0, 0.02, 0.7)
	label.rotation_degrees.x = -90.0
	label.pixel_size = 0.003
	add_child(label)


func _add_environment() -> void:
	var cam: Camera3D = Camera3D.new()
	if _gamecam:
		var pitch: float = deg_to_rad(Tuning.CAMERA_PITCH_DEG)
		cam.position = Vector3(0.0, sin(pitch), cos(pitch)) * Tuning.CAMERA_DISTANCE * 0.55
		cam.rotation_degrees.x = -Tuning.CAMERA_PITCH_DEG
		cam.fov = Tuning.CAMERA_FOV
	elif _side and _only >= 0:
		cam.position = Vector3(0.0, 0.85, 3.2)
		cam.rotation_degrees.x = -3.0
		cam.fov = 40.0
	elif _side:
		cam.position = Vector3(0.0, 0.9, 5.2)
		cam.rotation_degrees.x = -4.0
		cam.fov = 40.0
	elif _grid:
		cam.position = Vector3(0.4, 3.9, 3.6)
		cam.rotation_degrees.x = -38.0
		cam.fov = 48.0
	else:
		cam.position = Vector3(0.0, 1.5, 4.6)
		cam.rotation_degrees.x = -8.0
		cam.fov = 45.0
	add_child(cam)
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
	plane.size = Vector2(20.0, 10.0)
	ground.mesh = plane
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.22)
	ground.material_override = mat
	add_child(ground)
	if _move or _side:
		_add_ground_lines()


## Zemine 0.25 m aralıklı çizgiler: basan ayağın yerde kayıp kaymadığı bunlara göre okunur.
func _add_ground_lines() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.45, 0.4)
	for i: int in range(-24, 25):
		var line: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.012, 0.002, 6.0)
		line.mesh = box
		line.material_override = mat
		line.position = Vector3(i * 0.25, 0.001, 0.0)
		add_child(line)


func _process(delta: float) -> void:
	if _move:
		var forward: Vector3 = Vector3(1.0, 0.0, 0.0) if _side else Vector3(0.0, 0.0, 1.0)
		for i: int in _models.size():
			var model: Node3D = _models[i]
			model.position += forward * _speeds[i] * delta
			var along: float = model.position.dot(forward)
			if along > MOVE_SPAN * 0.5:
				model.position -= forward * MOVE_SPAN
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
