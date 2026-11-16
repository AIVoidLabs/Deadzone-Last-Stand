extends Node3D
## Animasyon önizleme: her klip için bir manken, yan yana. Yalnız debug yapıda çalışır.
## Aç: godot --path . res://scenes/debug/anim_preview.tscn
## Ekran görüntüsü: ... -- --capture=build/shots/anim.png [--capture-seconds=1.0]
## Tuşlar: Esc çıkış.

const MANNEQUIN: PackedScene = preload("res://assets/models/characters/mannequin.glb")
const LIBRARIES: Dictionary = {
	&"ual1": preload("res://assets/models/anim/ual1.glb"),
	&"ual2": preload("res://assets/models/anim/ual2.glb"),
}
const COLUMNS: int = 7
const SPACING: Vector2 = Vector2(2.4, 3.0)
const LABEL_OFFSET: Vector3 = Vector3(0.0, 0.15, 1.0)
const LABEL_PIXEL_SIZE: float = 0.006
const GROUND_COLOR: Color = Color(0.2, 0.22, 0.25)
const CAMERA_FOV: float = 40.0
const CAMERA_PITCH_DEG: float = 42.0
const CAMERA_MARGIN: float = 1.1
const CAMERA_DEPTH_FACTOR: float = 0.3
const VIEW_ASPECT: float = 16.0 / 9.0
const DEFAULT_CAPTURE_SECONDS: float = 1.0

var _capture_path: String = ""
var _capture_seconds: float = DEFAULT_CAPTURE_SECONDS
var _time: float = 0.0


func _ready() -> void:
	if not OS.is_debug_build():
		get_tree().quit()
		return
	_read_args()
	var clips: Array[StringName] = _clip_names()
	var rows: int = ceili(float(clips.size()) / COLUMNS)
	for i: int in clips.size():
		_add_mannequin(clips[i], _slot_position(i, rows))
	_add_environment(rows)


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


func _read_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture_path = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-seconds="):
			_capture_seconds = arg.trim_prefix("--capture-seconds=").to_float()


## "kütüphane/klip" adları, kütüphane sırasıyla.
func _clip_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for library_name: StringName in LIBRARIES:
		var library: AnimationLibrary = LIBRARIES[library_name]
		for clip: StringName in library.get_animation_list():
			names.append(StringName("%s/%s" % [library_name, clip]))
	return names


func _slot_position(index: int, rows: int) -> Vector3:
	var column: int = index % COLUMNS
	@warning_ignore("integer_division")
	var row: int = index / COLUMNS
	var x: float = (column - (COLUMNS - 1) * 0.5) * SPACING.x
	var z: float = (row - (rows - 1) * 0.5) * SPACING.y
	return Vector3(x, 0.0, z)


func _add_mannequin(clip: StringName, at: Vector3) -> void:
	var model: Node3D = MANNEQUIN.instantiate() as Node3D
	model.position = at
	add_child(model)
	var player: AnimationPlayer = AnimationPlayer.new()
	model.add_child(player)
	for library_name: StringName in LIBRARIES:
		player.add_animation_library(library_name, LIBRARIES[library_name])
	player.play(clip)
	# Döngüsüz klipler bitince baştan oynasın ki önizlemede hep hareket olsun.
	player.animation_finished.connect(func(finished: StringName) -> void: player.play(finished))
	var label: Label3D = Label3D.new()
	label.text = String(clip).get_slice("/", 1)
	label.pixel_size = LABEL_PIXEL_SIZE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = at + LABEL_OFFSET
	add_child(label)


func _add_environment(rows: int) -> void:
	var extent: Vector2 = Vector2(COLUMNS * SPACING.x, rows * SPACING.y)
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = extent * 3.0
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = GROUND_COLOR
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = material
	add_child(ground)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)

	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = GROUND_COLOR.darkened(0.4)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.5
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	# Tüm ızgarayı kadraja alan uzaklık (yatay görüş açısına göre).
	var camera: Camera3D = Camera3D.new()
	camera.fov = CAMERA_FOV
	var half_width: float = extent.x * 0.5 * CAMERA_MARGIN
	var distance: float = half_width / (tan(deg_to_rad(CAMERA_FOV * 0.5)) * VIEW_ASPECT) + extent.y * CAMERA_DEPTH_FACTOR
	var pitch: float = deg_to_rad(CAMERA_PITCH_DEG)
	camera.position = Vector3(0.0, 1.0 + distance * sin(pitch), distance * cos(pitch))
	camera.rotation.x = -pitch
	add_child(camera)
