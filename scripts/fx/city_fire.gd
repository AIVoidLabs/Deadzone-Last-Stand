class_name CityFire
extends Node3D
## 8.3b: tek ateş noktası: alev, duman sütunu, kıvılcım parçacıkları. size_mul küçük (çöp) ateş için.

const FLAME_COLORS: Array[Color] = [Color(1.0, 0.8, 0.35, 0.0), Color(1.0, 0.5, 0.12, 0.5), Color(0.9, 0.2, 0.04, 0.3), Color(0.4, 0.05, 0.0, 0.0)]
const SMOKE_COLORS: Array[Color] = [Color(0.3, 0.12, 0.05, 0.0), Color(0.12, 0.08, 0.07, 0.5), Color(0.05, 0.05, 0.06, 0.35), Color(0.05, 0.05, 0.06, 0.0)]

var flame: GPUParticles3D
var smoke: GPUParticles3D
var sparks: GPUParticles3D
var _size_mul: float = 1.0


func _init(size_mul: float = 1.0) -> void:
	_size_mul = size_mul


func _ready() -> void:
	flame = _flame()
	smoke = _smoke()
	sparks = _sparks()
	smoke.position.y = Tuning.CITY_FIRE_FLAME_HEIGHT * _size_mul + 0.3
	for p: GPUParticles3D in [flame, smoke, sparks]:
		add_child(p)


## Seviye 0/1/2: adetler tabloda; 0 = o parçacık kapalı.
func apply_level(level: int) -> void:
	_set_amount(flame, Tuning.CITY_FX_FLAME_AMOUNT[level])
	_set_amount(smoke, Tuning.CITY_FX_SMOKE_AMOUNT[level] if Tuning.FEATURE_CITY_FIRE_FX else 0)
	_set_amount(sparks, Tuning.CITY_FX_SPARK_AMOUNT[level])


func _set_amount(p: GPUParticles3D, base: int) -> void:
	var n: int = roundi(base * _size_mul)
	p.emitting = n > 0
	p.visible = n > 0
	if n > 0:
		p.amount = n


func _base(lifetime: float, additive: bool, size: float) -> GPUParticles3D:
	var p: GPUParticles3D = GPUParticles3D.new()
	p.lifetime = lifetime
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-8, -1, -8), Vector3(16, 24, 16))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.draw_pass_1 = CityFxAssets.quad(size)
	p.material_override = CityFxAssets.particle_material(additive)
	return p


func _flame() -> GPUParticles3D:
	var p: GPUParticles3D = _base(0.8, true, 1.0)
	p.position.y = Tuning.CITY_FIRE_FLAME_HEIGHT * _size_mul
	var m: ParticleProcessMaterial = ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(0.8, 0.05, 0.4) * _size_mul
	m.direction = Vector3.UP
	m.spread = 14.0
	m.initial_velocity_min = 0.7
	m.initial_velocity_max = 1.6
	m.gravity = Vector3(0.0, 0.8, 0.0)
	m.scale_min = 0.8 * _size_mul
	m.scale_max = 1.5 * _size_mul
	m.scale_curve = CityFxAssets.scale_curve([Vector2(0.0, 0.7), Vector2(0.3, 1.0), Vector2(1.0, 0.1)])
	m.color_ramp = CityFxAssets.ramp([0.0, 0.2, 0.6, 1.0], FLAME_COLORS)
	p.process_material = m
	return p


func _smoke() -> GPUParticles3D:
	var p: GPUParticles3D = _base(Tuning.CITY_SMOKE_LIFETIME, false, 1.0)
	var m: ParticleProcessMaterial = ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.4 * _size_mul
	m.direction = Vector3.UP
	m.spread = 8.0
	m.initial_velocity_min = 1.4
	m.initial_velocity_max = 2.2
	m.gravity = Tuning.CITY_SMOKE_WIND
	m.scale_min = 1.4 * _size_mul
	m.scale_max = 2.2 * _size_mul
	m.scale_curve = CityFxAssets.scale_curve([Vector2(0.0, 0.4), Vector2(1.0, 3.2)])
	m.color_ramp = CityFxAssets.ramp([0.0, 0.15, 0.6, 1.0], SMOKE_COLORS)
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.6
	m.turbulence_noise_scale = 3.0
	p.process_material = m
	return p


func _sparks() -> GPUParticles3D:
	var p: GPUParticles3D = _base(1.6, true, 0.09)
	p.position.y = Tuning.CITY_FIRE_FLAME_HEIGHT * _size_mul
	var m: ParticleProcessMaterial = ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(0.6, 0.1, 0.35) * _size_mul
	m.direction = Vector3.UP
	m.spread = 35.0
	m.initial_velocity_min = 1.5
	m.initial_velocity_max = 4.0
	m.gravity = Vector3(0.3, -1.5, 0.1)
	m.scale_min = 0.6
	m.scale_max = 1.2
	m.color_ramp = CityFxAssets.ramp([0.0, 0.7, 1.0], [Color(1.0, 0.8, 0.3, 1.0), Color(1.0, 0.4, 0.1, 0.8), Color(0.8, 0.1, 0.0, 0.0)])
	p.process_material = m
	return p
