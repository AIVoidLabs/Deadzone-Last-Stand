extends Node3D
## Zombi galerisi: önde her gövde çeşidi (bekleme), arkada aynıları başka renk şemasıyla (yürüyüş).
## Yalnız debug yapıda.
## Aç: godot --path . res://scenes/debug/zombie_gallery.tscn [-- --capture=build/shots/zombies.png]
## Klip seti: ... -- --clips → ZombieClipData tablosundaki her klip bir zombide, adıyla.
## Tür: ... -- --kind=runner|tank|walker (varsayılan walker). Boy karşılaştırması: ... -- --lineup
## (her türden üç çeşit yan yana, gerçek oyun boylarında).
## Tuşlar: Esc çıkış.

const FRONT_CLIP: StringName = &"idle"
const BACK_CLIP: StringName = &"walk_a"
const CLIPS_YAW_DEG: float = 30.0
const LABEL_OFFSET: Vector3 = Vector3(0.0, 0.1, 1.1)
const LABEL_PIXEL_SIZE: float = 0.006
const SPACING: float = 1.3
const BACK_ROW_Z: float = -3.0
const BACK_ROW_YAW_DEG: float = 50.0
const GROUND_COLOR: Color = Color(0.3, 0.32, 0.36)
const CAMERA_FOV: float = 35.0
const CAMERA_POSITION: Vector3 = Vector3(0.0, 4.6, 11.5)
const CAMERA_PITCH_DEG: float = 22.0
const DEFAULT_CAPTURE_SECONDS: float = 1.0

var _capture_path: String = ""
var _capture_seconds: float = DEFAULT_CAPTURE_SECONDS
var _time: float = 0.0
var _show_clips: bool = false
var _kind: StringName = &"walker"
var _lineup: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		get_tree().quit()
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture_path = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-seconds="):
			_capture_seconds = arg.trim_prefix("--capture-seconds=").to_float()
		elif arg == "--clips":
			_show_clips = true
		elif arg.begins_with("--kind="):
			_kind = StringName(arg.trim_prefix("--kind="))
		elif arg == "--lineup":
			_lineup = true
	_add_environment()
	if _lineup:
		_add_lineup()
		return
	if _show_clips:
		_add_clip_row()
		return
	var probe: Node3D = _scene(_kind).instantiate() as Node3D
	var variants: int = ZombieLook.variant_count(probe)
	probe.free()
	for i: int in variants:
		var x: float = (i - (variants - 1) * 0.5) * SPACING
		_add_zombie(_kind, i, i, Vector3(x, 0.0, 0.0), 0.0, FRONT_CLIP)
		# Arka sıra: aynı gövdeler, başka renk şemalarıyla.
		_add_zombie(_kind, i, i + 3, Vector3(x, 0.0, BACK_ROW_Z), BACK_ROW_YAW_DEG, BACK_CLIP)


func _scene(kind: StringName) -> PackedScene:
	return ZombieVisual.MODELS[kind]


## Tüm türler yan yana: oyundaki gerçek boy oranları ve yürüyüş / koşu klipleri.
func _add_lineup() -> void:
	var kinds: Array = [&"walker", &"runner", &"jumper", &"tongue", &"tank"]
	for k: int in kinds.size():
		for i: int in 2:
			var at: Vector3 = Vector3((k * 2 + i - 4.5) * 1.7, 0.0, 0.0)
			var row: Dictionary = EnemyData.get_row(kinds[k])
			_add_zombie(kinds[k], i, i + k, at, 20.0, (row["anim_walk"] as Array)[0])


func _add_clip_row() -> void:
	var clips: Array = ZombieClipData.TABLE.keys()
	for i: int in clips.size():
		var at: Vector3 = Vector3((i - (clips.size() - 1) * 0.5) * SPACING, 0.0, 0.0)
		_add_zombie(_kind, i, i * 3, at, CLIPS_YAW_DEG, clips[i])
		var label: Label3D = Label3D.new()
		label.text = String(clips[i])
		label.pixel_size = LABEL_PIXEL_SIZE
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.position = at + LABEL_OFFSET
		add_child(label)


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


func _add_zombie(kind: StringName, variant: int, scheme: int, at: Vector3, yaw_deg: float, clip: StringName) -> void:
	var model: Node3D = _scene(kind).instantiate() as Node3D
	ZombieLook.apply(model, variant, scheme)
	model.scale = Vector3.ONE * (float(EnemyData.get_row(kind)["height"]) / Tuning.CHARACTER_MODEL_HEIGHT)
	model.position = at
	model.rotation_degrees.y = yaw_deg
	add_child(model)
	var player: AnimationPlayer = AnimationPlayer.new()
	model.add_child(player)
	var skeleton: Skeleton3D = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	player.add_animation_library(ZombieClips.LIBRARY_NAME, ZombieClips.library(skeleton))
	var full: StringName = ZombieClips.full_name(clip)
	player.play(full)
	# Döngüsüz klipler bitince baştan oynasın ki önizlemede hep hareket olsun.
	player.animation_finished.connect(func(_finished: StringName) -> void: player.play(full))
	if not _show_clips:
		player.seek(variant * 0.37)


func _add_environment() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
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
	environment.background_color = GROUND_COLOR.darkened(0.5)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.5
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var camera: Camera3D = Camera3D.new()
	camera.fov = CAMERA_FOV
	camera.position = CAMERA_POSITION
	camera.rotation_degrees.x = -CAMERA_PITCH_DEG
	add_child(camera)
