class_name EnergyRing
extends MeshInstance3D
## Zırhın yansıttığı enerji çemberi: silahlar bunun üstünde durur. Yalnız görüntü; WeaponRig konumlar.

const SHADER: Shader = preload("res://assets/shaders/energy_ring.gdshader")
## Düzlemin halkadan taşan payı (m); parıltı kesilmesin.
const MARGIN: float = 0.3

var _material: ShaderMaterial


func _init() -> void:
	name = "EnergyRing"
	var plane: PlaneMesh = PlaneMesh.new()
	var half: float = Tuning.WEAPON_ORBIT_RADIUS + MARGIN
	plane.size = Vector2(half, half) * 2.0
	mesh = plane
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"half_size", half)
	_material.set_shader_parameter(&"radius", Tuning.WEAPON_ORBIT_RADIUS)
	_material.set_shader_parameter(&"color", Tuning.ENERGY_RING_COLOR)
	_material.set_shader_parameter(&"start_angle", deg_to_rad(Tuning.WEAPON_START_ANGLE_DEG))
	material_override = _material
	set_slot_count(0)


func set_slot_count(count: int) -> void:
	_material.set_shader_parameter(&"slot_count", float(count))
