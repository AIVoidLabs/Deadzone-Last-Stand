class_name WeaponVisual
extends Node3D
## Süzülen silahın görüntüsü: nişan yönüne yumuşak dönüş, hafif yukarı aşağı salınım, ateşte geri tepme.
## Silah mantığına dokunmaz; Weapon'ın aim değerini okur ve fired sinyalini dinler.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const MODELS: PackedScene = preload("res://assets/models/weapons/weapons.glb")
const FLASH_SHADER_PATH: Shader = preload("res://assets/shaders/muzzle_flash.gdshader")
const MUZZLE_LIGHT_COLOR: Color = Color(1.0, 0.7, 0.35)
## Parlamanın namlu ucundan öne taşma payı (m).
const FLASH_FORWARD: float = 0.08

var _weapon: Weapon
var _pivot: Node3D
var _recoil: float = 0.0
var _bob_phase: float = 0.0
var _time: float = 0.0
var _flash: MeshInstance3D
var _light: OmniLight3D
var _flash_left: float = 0.0


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
	_update_flash(delta)


func _on_fired(_direction: Vector2) -> void:
	_recoil = 1.0
	if _flash == null:
		return
	_flash_left = Tuning.MUZZLE_FLASH_TIME
	_flash.visible = true
	_flash.set_instance_shader_parameter(&"angle", randf() * TAU)
	_flash.scale = Vector3.ONE * Tuning.MUZZLE_FLASH_SIZE * randf_range(0.8, 1.2)
	_light.visible = Quality.get_value("muzzle_light")


func _update_flash(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left -= delta
	var strength: float = clampf(_flash_left / Tuning.MUZZLE_FLASH_TIME, 0.0, 1.0)
	_flash.set_instance_shader_parameter(&"strength", strength)
	_light.light_energy = Tuning.MUZZLE_LIGHT_ENERGY * strength
	if _flash_left <= 0.0:
		_flash.visible = false
		_light.visible = false


## Namlu ucunda parlama karesi ve kısa nokta ışığı; ateşe kadar gizli.
func _build_flash(muzzle_z: float) -> void:
	var quad: QuadMesh = QuadMesh.new()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FLASH_SHADER_PATH
	quad.material = material
	_flash = MeshInstance3D.new()
	_flash.mesh = quad
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash.position = Vector3(0.0, 0.0, muzzle_z + FLASH_FORWARD)
	_flash.visible = false
	_pivot.add_child(_flash)
	_light = OmniLight3D.new()
	_light.light_color = MUZZLE_LIGHT_COLOR
	_light.omni_range = Tuning.MUZZLE_LIGHT_RANGE
	_light.shadow_enabled = false
	_light.position = _flash.position
	_light.visible = false
	_pivot.add_child(_light)


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
	if Tuning.FEATURE_MUZZLE_FLASH:
		_build_flash(source.mesh.get_aabb().end.z * mesh.scale.z)
	scene.free()
