class_name WeaponVisual
extends Node3D
## Süzülen silahın görüntüsü: nişan yönüne yumuşak dönüş, hafif yukarı aşağı salınım, ateşte geri tepme.
## Silah mantığına dokunmaz; Weapon'ın aim değerini okur ve fired sinyalini dinler.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const MODELS: PackedScene = preload("res://assets/models/weapons/weapons.glb")

var _weapon: Weapon
var _pivot: Node3D
var _recoil: float = 0.0
var _bob_phase: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_weapon = get_parent() as Weapon
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	_build_model()
	_weapon.fired.connect(_on_fired)
	_bob_phase = randf() * TAU
	rotation.y = atan2(_weapon.aim.x, _weapon.aim.y)


func _process(delta: float) -> void:
	_time += delta
	var target_yaw: float = atan2(_weapon.aim.x, _weapon.aim.y)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-Tuning.WEAPON_AIM_SHARPNESS * delta))
	_recoil = _recoil * exp(-Tuning.WEAPON_RECOIL_RECOVER * delta)
	var kick: float = float(_weapon.row["recoil"]) * _recoil
	var bob: float = sin(_time * Tuning.WEAPON_BOB_SPEED + _bob_phase) * Tuning.WEAPON_BOB_HEIGHT
	# Model +Z'ye bakar: geri tepme -Z yönünde, namlu yukarı kalkar (-X ekseninde dönüş).
	_pivot.position = Vector3(0.0, bob, -kick)
	_pivot.rotation.x = -deg_to_rad(Tuning.WEAPON_RECOIL_PITCH_DEG) * _recoil


func _on_fired(_direction: Vector2) -> void:
	_recoil = 1.0


func _build_model() -> void:
	var scene: Node3D = MODELS.instantiate() as Node3D
	var source: MeshInstance3D = scene.find_child(String(_weapon.row["model"]), true, false) as MeshInstance3D
	assert(source != null, "Silah modeli bulunamadı: %s" % _weapon.row["model"])
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = source.mesh
	mesh.scale = Vector3.ONE * float(_weapon.row["model_scale"])
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FLASH_SHADER
	material.set_shader_parameter(&"albedo", Color.WHITE)
	var base: BaseMaterial3D = source.mesh.surface_get_material(0) as BaseMaterial3D
	if base != null:
		material.set_shader_parameter(&"albedo_texture", base.albedo_texture)
	mesh.material_override = material
	_pivot.add_child(mesh)
	scene.free()
