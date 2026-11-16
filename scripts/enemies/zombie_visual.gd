class_name ZombieVisual
extends Node3D
## Zombi görüntüsü: ortak iskeletli model + animasyon (Tuning.FEATURE_ZOMBIE_MODEL kapalıysa kutu).
## Görünüm (gövde çeşidi + renk şeması) ZombieLook ile rastgele seçilir; vuruş parlaması örnek başına.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const MODEL: PackedScene = preload("res://assets/models/characters/zombie_walker.glb")
const BOX_WIDTH_FACTOR: float = 1.6

static var _box_meshes: Dictionary = {}
static var _materials: Dictionary = {}

var _meshes: Array[MeshInstance3D] = []
var _animation: AnimationPlayer
var _walk_clips: Array = []
var _flash_left: float = 0.0


func _init() -> void:
	if Tuning.FEATURE_ZOMBIE_MODEL:
		_build_model()
	else:
		_build_box()
	set_process(false)


func _ready() -> void:
	var body: Zombie = get_parent() as Zombie
	body.event.connect(_on_event)
	body.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	_flash_left -= delta
	if _flash_left <= 0.0:
		_set_flash(0.0)
		set_process(false)


func _on_event(event_name: StringName, data: Dictionary) -> void:
	match event_name:
		&"configure":
			_apply_kind(data)
		&"hit":
			if Tuning.FEATURE_HIT_FLASH:
				_flash_left = Tuning.HIT_FLASH_TIME
				_set_flash(1.0)
				set_process(true)


func _on_state_changed(new_state: int, _old_state: int) -> void:
	if new_state == Zombie.State.CHASE:
		_start_walk()
		return
	_flash_left = 0.0
	_set_flash(0.0)
	set_process(false)
	# Havuzdaki (görünmeyen) zombi animasyon hesaplamasın.
	if _animation != null:
		_animation.stop()


func _set_flash(value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(&"flash", value)


func _build_model() -> void:
	var model: Node3D = MODEL.instantiate() as Node3D
	add_child(model)
	_meshes.append(ZombieLook.apply_random(model))
	_animation = AnimationPlayer.new()
	model.add_child(_animation)
	var skeleton: Skeleton3D = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	_animation.add_animation_library(ZombieClips.LIBRARY_NAME, ZombieClips.library(skeleton))


func _build_box() -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	add_child(mesh)
	_meshes.append(mesh)


func _apply_kind(row: Dictionary) -> void:
	var height: float = row["height"]
	if _animation == null:
		var box: MeshInstance3D = _meshes[0]
		box.mesh = _box_mesh_for(row)
		box.material_override = _material_for(row)
		box.position.y = height * 0.5
		return
	var size: float = randf_range(1.0 - Tuning.ZOMBIE_SCALE_VARIANCE, 1.0 + Tuning.ZOMBIE_SCALE_VARIANCE)
	scale = Vector3.ONE * (size * height / Tuning.CHARACTER_MODEL_HEIGHT)
	_walk_clips = row["anim_walk"]


## Yürüyüşü rastgele bir kareden ve biraz farklı hızda başlatır; sürü aynı adımda yürümez.
func _start_walk() -> void:
	if _animation == null or _walk_clips.is_empty():
		return
	var variance: float = Tuning.ZOMBIE_ANIM_SPEED_VARIANCE
	_animation.speed_scale = randf_range(1.0 - variance, 1.0 + variance)
	_animation.play(ZombieClips.full_name(_walk_clips.pick_random()))
	_animation.seek(randf() * _animation.current_animation_length)


static func _material_for(row: Dictionary) -> ShaderMaterial:
	var id: StringName = row["id"]
	if not _materials.has(id):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = FLASH_SHADER
		material.set_shader_parameter(&"albedo", row["color"])
		_materials[id] = material
	return _materials[id]


static func _box_mesh_for(row: Dictionary) -> BoxMesh:
	var id: StringName = row["id"]
	if not _box_meshes.has(id):
		var radius: float = row["radius"]
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(radius * BOX_WIDTH_FACTOR, row["height"], radius * BOX_WIDTH_FACTOR)
		_box_meshes[id] = box
	return _box_meshes[id]
