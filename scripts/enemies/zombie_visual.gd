class_name ZombieVisual
extends Node3D
## Zombi görüntüsü (şimdilik kutu). Aşama 5'te ortak iskeletli model buraya takılır.
## Malzeme ve mesh türe göre paylaşılır; vuruş parlaması örnek başına.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const WIDTH_FACTOR: float = 1.6

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}

var _mesh_instance: MeshInstance3D
var _flash_left: float = 0.0


func _init() -> void:
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
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
	if new_state != Zombie.State.CHASE:
		_flash_left = 0.0
		_set_flash(0.0)
		set_process(false)


func _set_flash(value: float) -> void:
	_mesh_instance.set_instance_shader_parameter(&"flash", value)


func _apply_kind(row: Dictionary) -> void:
	var id: StringName = row["id"]
	var height: float = row["height"]
	if not _meshes.has(id):
		var radius: float = row["radius"]
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(radius * WIDTH_FACTOR, height, radius * WIDTH_FACTOR)
		_meshes[id] = box
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = FLASH_SHADER
		mat.set_shader_parameter(&"albedo", row["color"])
		_materials[id] = mat
	_mesh_instance.mesh = _meshes[id]
	_mesh_instance.material_override = _materials[id]
	_mesh_instance.position.y = height * 0.5
