class_name CityFx
extends Node3D
## 8.3b: şehir ışık ve efektleri: yanan araç / çöp ateşi (alev, duman, kıvılcım, titreyen ışık),
## neon, sokak lambası ampulü ve konisi, kamera çevresinde kül. Tek tek kapatma: Tuning.FEATURE_CITY_*.
## CityGreybox'un omni ışıklarını bulup canlandırır; yeni omni sayısı Quality omni_lights sınırına tabi.

var _fires: Array[CityFire] = []
var _fire_lights: Array[OmniLight3D] = []
var _fire_base: Array[Vector3] = []
var _fire_energy: Array[float] = []
var _lamp_lights: Array[OmniLight3D] = []
var _lamp_energy: Array[float] = []
var _bulbs: Array[StandardMaterial3D] = []
var _cones: Array[SpotLight3D] = []
var _neon: CityNeon = null
var _ash: GPUParticles3D = null
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
var _lamp_flicker: BrokenFlicker = BrokenFlicker.new(3)
var _base_omni_count: int = 0


func _ready() -> void:
	name = "CityFx"
	_noise.frequency = 1.0
	_base_omni_count = _sibling_omnis().size()
	_build_fires()
	_build_lamps()
	if Tuning.FEATURE_CITY_NEON:
		_neon = CityNeon.new()
		add_child(_neon)
	if Tuning.FEATURE_CITY_ASH:
		_build_ash()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


func _process(delta: float) -> void:
	_time += delta
	_flicker_fires()
	_flicker_lamp(delta)
	_follow_camera()


func _sibling_omnis() -> Array[OmniLight3D]:
	var out: Array[OmniLight3D] = []
	for c: Node in get_parent().get_children():
		if c is OmniLight3D:
			out.append(c as OmniLight3D)
	return out


func _find_omni(pos: Vector3) -> OmniLight3D:
	for light: OmniLight3D in _sibling_omnis():
		if light.position.distance_to(pos) < 0.05:
			return light
	return null


func _fire_spots() -> Array[Vector3]:
	return CityProps.FIRE_SPOTS if Tuning.FEATURE_CITY_PROPS else CityGreybox.FIRE_CARS


func _build_fires() -> void:
	if not Tuning.FEATURE_CITY_FIRE_FX:
		return
	for p: Vector3 in _fire_spots():
		_add_fire(p, 1.0)
		var light: OmniLight3D = _find_omni(p + Vector3(0.0, 2.2, 0.0))
		if light != null:
			_fire_lights.append(light)
			_fire_base.append(light.position)
			_fire_energy.append(light.light_energy)
	for p: Vector3 in Tuning.CITY_TRASH_FIRES:
		_add_fire(p, Tuning.CITY_TRASH_FIRE_SCALE)


func _add_fire(pos: Vector3, size_mul: float) -> void:
	var fire: CityFire = CityFire.new(size_mul)
	fire.position = pos
	add_child(fire)
	_fires.append(fire)


func _build_lamps() -> void:
	var count: int = CityGreybox.LAMP_SPOTS.size()
	for i: int in count:
		var head: Vector3 = CityGreybox.LAMP_SPOTS[i] + Vector3(0.0, CityGreybox.LAMP_HEIGHT, 0.0)
		var weak: bool = i == count - 1
		var bulb: MeshInstance3D = MeshInstance3D.new()
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		bulb.mesh = sphere
		var mat: StandardMaterial3D = CityFxAssets.emissive(CityGreybox.LAMP_COLOR, Tuning.CITY_LAMP_BULB_ENERGY)
		bulb.material_override = mat
		bulb.position = head - Vector3(0.0, 0.05, 0.0)
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(bulb)
		if weak:
			_bulbs.append(mat)
			var light: OmniLight3D = _find_omni(head)
			if light != null:
				_lamp_lights.append(light)
				_lamp_energy.append(light.light_energy)
		if Tuning.FEATURE_CITY_LAMP_CONES:
			_add_cone(head, weak)


func _add_cone(head: Vector3, weak: bool) -> void:
	var cone: SpotLight3D = SpotLight3D.new()
	cone.position = head
	cone.rotation_degrees.x = -90.0
	cone.light_color = CityGreybox.LAMP_COLOR
	cone.light_energy = Tuning.CITY_LAMP_CONE_ENERGY * (Tuning.CITY_LAMP_WEAK_FACTOR if weak else 1.0)
	cone.spot_range = Tuning.CITY_LAMP_CONE_RANGE
	cone.spot_angle = Tuning.CITY_LAMP_CONE_ANGLE
	cone.light_volumetric_fog_energy = 1.0
	add_child(cone)
	_cones.append(cone)


func _build_ash() -> void:
	_ash = GPUParticles3D.new()
	_ash.lifetime = 9.0
	_ash.local_coords = false
	_ash.visibility_aabb = AABB(-Tuning.CITY_ASH_BOX, Tuning.CITY_ASH_BOX * 2.0)
	_ash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ash.draw_pass_1 = CityFxAssets.quad(0.07)
	_ash.material_override = CityFxAssets.particle_material(false)
	var m: ParticleProcessMaterial = ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Tuning.CITY_ASH_BOX
	m.direction = Vector3(0.3, -0.2, 0.1)
	m.spread = 180.0
	m.initial_velocity_min = 0.05
	m.initial_velocity_max = 0.3
	m.gravity = Vector3(0.03, -0.05, 0.0)
	m.color_ramp = CityFxAssets.ramp([0.0, 0.2, 0.8, 1.0], [Color(0.8, 0.7, 0.6, 0.0), Color(0.8, 0.7, 0.6, 0.3), Color(0.8, 0.7, 0.6, 0.22), Color(0.8, 0.7, 0.6, 0.0)])
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.2
	_ash.process_material = m
	_ash.position = Vector3(0.0, 2.5, 0.0)
	add_child(_ash)


func _flicker_fires() -> void:
	for i: int in _fire_lights.size():
		var t: float = _time * Tuning.CITY_FIRE_FLICKER_SPEED + i * 17.0
		var n: float = _noise.get_noise_2d(t, i * 5.0) * 1.4
		_fire_lights[i].light_energy = _fire_energy[i] * (1.0 + clampf(n, -1.0, 1.0) * Tuning.CITY_FIRE_FLICKER)
		var wobble: Vector3 = Vector3(_noise.get_noise_2d(t * 1.3, 40.0), _noise.get_noise_2d(t * 1.1, 80.0) * 0.5, _noise.get_noise_2d(t * 1.7, 120.0))
		_fire_lights[i].position = _fire_base[i] + wobble * Tuning.CITY_FIRE_WOBBLE


## Zayıf lamba arada söner-yanar: ampul, omni ve koni birlikte.
func _flicker_lamp(delta: float) -> void:
	var k: float = _lamp_flicker.step(delta)
	for m: StandardMaterial3D in _bulbs:
		m.emission_energy_multiplier = Tuning.CITY_LAMP_BULB_ENERGY * k
	for i: int in _lamp_lights.size():
		_lamp_lights[i].light_energy = _lamp_energy[i] * k
	if not _cones.is_empty():
		_cones[_cones.size() - 1].light_energy = Tuning.CITY_LAMP_CONE_ENERGY * Tuning.CITY_LAMP_WEAK_FACTOR * k


## Kül kutusu kameranın baktığı zemin noktasında durur.
func _follow_camera() -> void:
	if _ash == null or not _ash.visible:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var fwd: Vector3 = -cam.global_transform.basis.z
	if fwd.y > -0.1:
		return
	_ash.global_position = cam.global_position + fwd * (-cam.global_position.y / fwd.y) + Vector3(0.0, 2.5, 0.0)


func _apply_quality(_profile_id: StringName) -> void:
	var level: int = Quality.get_value("city_fx")
	for fire: CityFire in _fires:
		fire.apply_level(level)
	if _ash != null:
		var n: int = Tuning.CITY_FX_ASH_AMOUNT[level]
		_ash.visible = n > 0
		_ash.emitting = n > 0
		if n > 0:
			_ash.amount = n
	for cone: SpotLight3D in _cones:
		cone.visible = level > 0
	if _neon != null:
		var budget: int = Quality.get_value("omni_lights") - _base_omni_count
		for i: int in _neon.lights.size():
			_neon.lights[i].visible = i < budget
