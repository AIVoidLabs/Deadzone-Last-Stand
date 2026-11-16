class_name DashDust
extends RefCounted
## Dash sırasında askerin ayak hizasından çıkan toz izi. Tek örnek askere bağlı kalır,
## yalnız dash süresince yayar (yaratıp yok etme yok).

const COLOR: Color = Color(0.85, 0.82, 0.75, 0.7)
const PUFF_SIZE: float = 0.28
const HEIGHT: float = 0.15
const SPREAD_RADIUS: float = 0.25
const RISE_SPEED: Vector2 = Vector2(0.3, 1.0)
const SCALE_RANGE: Vector2 = Vector2(0.6, 1.4)


static func create() -> CPUParticles3D:
	var dust: CPUParticles3D = CPUParticles3D.new()
	dust.name = "DashDust"
	dust.emitting = false
	dust.amount = Tuning.DASH_DUST_AMOUNT
	dust.lifetime = Tuning.DASH_DUST_LIFETIME
	# Parçacıklar dünyada kalır; asker ilerledikçe arkada iz oluşur.
	dust.local_coords = false
	dust.position.y = HEIGHT
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = SPREAD_RADIUS
	dust.direction = Vector3.UP
	dust.spread = 60.0
	dust.gravity = Vector3.ZERO
	dust.initial_velocity_min = RISE_SPEED.x
	dust.initial_velocity_max = RISE_SPEED.y
	dust.scale_amount_min = SCALE_RANGE.x
	dust.scale_amount_max = SCALE_RANGE.y
	dust.color_ramp = _fade_ramp()
	dust.mesh = _puff_mesh()
	return dust


static func _fade_ramp() -> Gradient:
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, COLOR)
	ramp.set_color(1, Color(COLOR, 0.0))
	return ramp


static func _puff_mesh() -> QuadMesh:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(PUFF_SIZE, PUFF_SIZE)
	quad.material = material
	return quad
