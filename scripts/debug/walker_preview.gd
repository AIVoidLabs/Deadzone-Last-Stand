extends Node3D
## Yürüyen oyun modeli önizlemesi (Aşama V.5): dört çeşit yan yana, köşe renkli zombie_vc ile.
## Aç: godot --path . res://scenes/debug/walker_preview.tscn [-- --capture=build/shots/walker_game_godot.png]
##   [--capture-seconds=S] [--gamecam] (oyun kamerası açısı ve uzaklığı, Tuning'den)
## Başlangıçta her çeşit için iskelet ve ağ bilgisini yazar (WALKER satırları).

const MODELS: Array[PackedScene] = [
	preload("res://assets/models/characters/zombie_walker_office.glb"),
	preload("res://assets/models/characters/zombie_walker_worker.glb"),
	preload("res://assets/models/characters/zombie_walker_skinny.glb"),
	preload("res://assets/models/characters/zombie_walker_civilian.glb"),
]
const NAMES: Array[String] = ["Office", "Worker", "Skinny", "Civilian"]
const SHADER: Shader = preload("res://assets/shaders/zombie_vc.gdshader")
const SPACING: float = 1.1

var _capture_path: String = ""
var _capture_seconds: float = 1.5
var _gamecam: bool = false
var _time: float = 0.0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture_path = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-seconds="):
			_capture_seconds = arg.trim_prefix("--capture-seconds=").to_float()
		elif arg == "--gamecam":
			_gamecam = true
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	for i: int in MODELS.size():
		var model: Node3D = MODELS[i].instantiate() as Node3D
		add_child(model)
		model.position = Vector3((i - (MODELS.size() - 1) * 0.5) * SPACING, 0.0, 0.0)
		_report(NAMES[i], model, material)
	_add_environment()


## Çeşidin iskeletini ve ağını yazar; ağa ortak malzemeyi verir.
func _report(variant: String, model: Node3D, material: ShaderMaterial) -> void:
	var skeleton: Skeleton3D = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	var bones: int = skeleton.get_bone_count() if skeleton != null else -1
	var tris: int = 0
	var height: float = 0.0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		mesh_instance.material_override = material
		var mesh: Mesh = mesh_instance.mesh
		for surface: int in mesh.get_surface_count():
			var indices: PackedInt32Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
			tris += indices.size() / 3
		height = maxf(height, mesh_instance.get_aabb().end.y)
	var head: int = skeleton.find_bone(&"Head") if skeleton != null else -1
	var jaw: int = skeleton.find_bone(&"jaw") if skeleton != null else -1
	print("WALKER %s: GeneralSkeleton %s, %d kemik, Head %d, jaw %d, %d üçgen, boy %.2f m" % [
		variant, "var" if skeleton != null else "YOK", bones, head, jaw, tris, height])


func _add_environment() -> void:
	var cam: Camera3D = Camera3D.new()
	if _gamecam:
		var pitch: float = deg_to_rad(Tuning.CAMERA_PITCH_DEG)
		cam.position = Vector3(0.0, sin(pitch), cos(pitch)) * Tuning.CAMERA_DISTANCE * 0.55
		cam.rotation_degrees.x = -Tuning.CAMERA_PITCH_DEG
		cam.fov = Tuning.CAMERA_FOV
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
	plane.size = Vector2(12.0, 8.0)
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
