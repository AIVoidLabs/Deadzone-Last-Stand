class_name CityFire
extends Node3D
## 8.3e: tek ateş noktası: küçük parlak alev dilleri, yerde kor, yukarı kıvılcım, duman şeritleri, kül ve zemine sahte ışık.
## size_mul küçük (çöp) ateş için; extents alev çıkış kutusu (vitrin için geniş); lift alev yüksekliği (m).

const FLAME_FADE: Array[Color] = [Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)]
## Duman şeridi: altta ateşle aydınlık turuncu, yukarı koyu gri; alfa düşük.
const WISP_COLORS: Array[Color] = [Color(0.45, 0.18, 0.07, 0.0), Color(0.32, 0.14, 0.07, 1.0), Color(0.12, 0.11, 0.11, 0.9), Color(0.07, 0.07, 0.08, 0.0)]
const SPARK_COLORS: Array[Color] = [Color(1.0, 0.95, 0.6, 1.0), Color(1.0, 0.5, 0.12, 0.9), Color(0.8, 0.1, 0.0, 0.0)]

var flame: GPUParticles3D
var wisps: GPUParticles3D
var sparks: GPUParticles3D
var ash: GPUParticles3D
var embers: MultiMeshInstance3D
var _size_mul: float = 1.0
var _extents: Vector3 = Vector3(0.9, 0.05, 0.45)
var _lift: float = 0.9
var _ember_max: int = 0


func _init(size_mul: float = 1.0, extents: Vector3 = Vector3(0.9, 0.05, 0.45), lift: float = Tuning.CITY_FIRE_FLAME_HEIGHT) -> void:
	_size_mul = size_mul
	_extents = extents
	_lift = lift


func _ready() -> void:
	flame = _flame()
	wisps = _wisps()
	sparks = _sparks()
	ash = _ash()
	for p: GPUParticles3D in [flame, wisps, sparks, ash]:
		add_child(p)
	embers = _embers()
	add_child(embers)
	if Tuning.FEATURE_CITY_FAKE_LIGHT:
		var radius: float = Tuning.CITY_FIRE_GLOW_RADIUS * (0.3 + 0.7 * _size_mul) + _extents.x
		add_child(CityFxAssets.glow_quad(Vector3.ZERO, radius, Color(1.0, 0.3, 0.06), Tuning.CITY_FIRE_GLOW_ENERGY * (0.6 + 0.4 * _size_mul), Tuning.CITY_FIRE_GLOW_FLICKER))
		# alevin altında küçük, çok parlak sıcak nokta
		add_child(CityFxAssets.glow_quad(Vector3.ZERO, 1.1 * _size_mul + _extents.x, Color(1.0, 0.6, 0.2), 1.6, 0.4))


## Seviye 0/1/2: adetler tabloda; 0 = o parçacık kapalı. Sahte ışık her seviyede açık.
func apply_level(level: int) -> void:
	_set_amount(flame, Tuning.CITY_FX_FLAME_AMOUNT[level])
	_set_amount(wisps, Tuning.CITY_FX_SMOKE_AMOUNT[level] if Tuning.FEATURE_CITY_FIRE_FX else 0)
	_set_amount(sparks, Tuning.CITY_FX_SPARK_AMOUNT[level])
	_set_amount(ash, Tuning.CITY_FX_ASH_AMOUNT[level] if Tuning.FEATURE_CITY_ASH else 0)
	var n: int = roundi(Tuning.CITY_FX_EMBER_AMOUNT[level] * _size_mul * (_extents.x + 1.0) / 1.9)
	embers.multimesh.visible_instance_count = clampi(n, 0, _ember_max)
	embers.visible = n > 0


func _set_amount(p: GPUParticles3D, base: int) -> void:
	var n: int = roundi(base * _size_mul * (1.0 + (_extents.x - 0.9) * 0.4))
	p.emitting = n > 0
	p.visible = n > 0
	if n > 0:
		p.amount = n


func _base(lifetime: float, mesh: Mesh, mat: Material) -> GPUParticles3D:
	var p: GPUParticles3D = GPUParticles3D.new()
	p.lifetime = lifetime
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-10, -1, -10), Vector3(20, 14, 20))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.draw_pass_1 = mesh
	p.material_override = mat
	p.position.y = _lift
	return p


func _box_material(extents: Vector3) -> ParticleProcessMaterial:
	var m: ParticleProcessMaterial = ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = extents
	m.direction = Vector3.UP
	return m


func _flame() -> GPUParticles3D:
	var mesh: QuadMesh = CityFxAssets.tall_quad(Tuning.CITY_FLAME_WIDTH, Tuning.CITY_FLAME_HEIGHT)
	var p: GPUParticles3D = _base(Tuning.CITY_FLAME_LIFETIME, mesh, CityFxAssets.flame_material())
	var m: ParticleProcessMaterial = _box_material(_extents * Vector3(1.0, 1.0, 1.0))
	m.spread = 12.0
	m.initial_velocity_min = 0.1
	m.initial_velocity_max = 0.7
	m.gravity = Vector3(0.15, 0.6, 0.0)
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.scale_min = 0.7 * _size_mul + 0.2
	m.scale_max = 1.5 * _size_mul + 0.2
	m.scale_curve = CityFxAssets.scale_curve([Vector2(0.0, 0.6), Vector2(0.3, 1.0), Vector2(1.0, 0.3)])
	m.color_ramp = CityFxAssets.ramp([0.0, 0.1, 0.8, 1.0], FLAME_FADE)
	p.process_material = m
	return p


func _wisps() -> GPUParticles3D:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(2.2, 4.5)
	var p: GPUParticles3D = _base(Tuning.CITY_SMOKE_LIFETIME, mesh, CityFxAssets.wisp_material())
	p.position.y = _lift + 0.4
	var m: ParticleProcessMaterial = ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.3 + _extents.x * 0.3
	m.direction = Vector3.UP
	m.spread = 10.0
	m.particle_flag_align_y = true
	m.initial_velocity_min = 1.3 * _size_mul + 0.4
	m.initial_velocity_max = 2.0 * _size_mul + 0.5
	m.gravity = Tuning.CITY_SMOKE_WIND
	m.scale_min = 0.8 * _size_mul + 0.3
	m.scale_max = 1.2 * _size_mul + 0.4
	m.scale_curve = CityFxAssets.scale_curve([Vector2(0.0, 0.5), Vector2(1.0, 1.9)])
	m.color_ramp = CityFxAssets.ramp([0.0, 0.1, 0.5, 1.0], WISP_COLORS)
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.5
	m.turbulence_noise_scale = 2.5
	p.process_material = m
	return p


func _sparks() -> GPUParticles3D:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(Tuning.CITY_SPARK_WIDTH, Tuning.CITY_SPARK_LENGTH)
	var p: GPUParticles3D = _base(1.8, mesh, CityFxAssets.spark_material())
	var m: ParticleProcessMaterial = _box_material(_extents * 0.7)
	m.spread = 40.0
	m.particle_flag_align_y = true
	m.initial_velocity_min = 2.0 + _size_mul
	m.initial_velocity_max = 4.0 + 2.0 * _size_mul
	m.gravity = Vector3(1.2, -0.6, 0.5)
	m.scale_min = 0.7
	m.scale_max = 1.5
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 1.6
	m.turbulence_noise_scale = 1.5
	m.color_ramp = CityFxAssets.ramp([0.0, 0.6, 1.0], SPARK_COLORS)
	p.process_material = m
	return p


## Kül: ateşin üstünde yavaş yükselen, rüzgârla yatan ince koyu benekler.
func _ash() -> GPUParticles3D:
	var p: GPUParticles3D = _base(4.0, CityFxAssets.quad(0.06), CityFxAssets.particle_material(false))
	var m: ParticleProcessMaterial = _box_material(_extents + Vector3(0.4, 0.2, 0.4))
	m.spread = 50.0
	m.initial_velocity_min = 0.4
	m.initial_velocity_max = 1.2
	m.gravity = Vector3(0.6, 0.2, 0.2)
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.8
	m.color_ramp = CityFxAssets.ramp([0.0, 0.2, 0.8, 1.0], [Color(1.0, 0.5, 0.2, 0.0), Color(0.55, 0.3, 0.18, 0.7), Color(0.18, 0.15, 0.14, 0.45), Color(0.1, 0.1, 0.1, 0.0)])
	p.process_material = m
	return p


## Yerde parlayan kor noktaları: bir MultiMesh, her nokta kendi fazında yanıp söner.
func _embers() -> MultiMeshInstance3D:
	_ember_max = roundi(Tuning.CITY_FX_EMBER_AMOUNT[2] * _size_mul * (_extents.x + 1.0) / 1.9) + 1
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = CityFxAssets.flat_quad(1.0)
	mm.instance_count = _ember_max
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(position.x * 100.0) + int(position.z * 31.0) + 7
	var spread: float = Tuning.CITY_FIRE_EMBER_RADIUS * (0.6 + 0.4 * _size_mul)
	for i: int in _ember_max:
		var pos: Vector3 = Vector3(rng.randf_range(-1.0, 1.0) * (_extents.x + spread), 0.12, rng.randf_range(-1.0, 1.0) * (_extents.z + spread))
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(0.14, 0.34)), pos))
	var mi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = CityFxAssets.ember_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
