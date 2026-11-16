class_name ImpactSparks
extends Node3D
## Mermi isabetinde kıvılcım patlaması. Sabit havuz, sırayla yeniden kullanılır (yaratıp yok etme yok).
## Kıvılcım sayısı kalite profilinden (spark_amount).

const POOL_SIZE: int = 24
const SPREAD_DEG: float = 55.0
const SPEED: Vector2 = Vector2(4.0, 9.0)
const LIFETIME: float = 0.22
const GRAVITY: Vector3 = Vector3(0.0, -12.0, 0.0)
## Kıvılcım hız yönünde uzanan ince çubuk (Y ekseni hız yönüne hizalanır).
const SIZE: Vector3 = Vector3(0.025, 0.2, 0.025)
const START_COLOR: Color = Color(1.0, 0.85, 0.4, 1.0)
const END_COLOR: Color = Color(1.0, 0.35, 0.05, 0.0)

var _pool: Array[CPUParticles3D] = []
var _next: int = 0


func _ready() -> void:
	name = "ImpactSparks"
	var mesh: BoxMesh = _spark_mesh()
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, START_COLOR)
	ramp.set_color(1, END_COLOR)
	for _i in POOL_SIZE:
		var sparks: CPUParticles3D = CPUParticles3D.new()
		sparks.emitting = false
		sparks.one_shot = true
		sparks.explosiveness = 1.0
		sparks.lifetime = LIFETIME
		sparks.local_coords = false
		sparks.mesh = mesh
		sparks.direction = Vector3.FORWARD
		sparks.spread = SPREAD_DEG
		sparks.gravity = GRAVITY
		sparks.initial_velocity_min = SPEED.x
		sparks.initial_velocity_max = SPEED.y
		sparks.particle_flag_align_y = true
		sparks.color_ramp = ramp
		add_child(sparks)
		_pool.append(sparks)
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


## direction: merminin gidiş yönü (XZ); kıvılcımlar geri sekerek saçılır.
func burst(at: Vector3, direction: Vector2) -> void:
	var sparks: CPUParticles3D = _pool[_next]
	_next = (_next + 1) % _pool.size()
	sparks.global_position = at
	var back: Vector3 = Vector3(-direction.x, 0.35, -direction.y).normalized()
	# CPUParticles3D yönü yerel eksende; düğümü geri sekme yönüne çevir.
	sparks.look_at(at + back, Vector3.UP)
	sparks.restart()


func _apply_quality(_profile: StringName) -> void:
	var amount: int = Quality.get_value("spark_amount")
	for sparks: CPUParticles3D in _pool:
		sparks.amount = amount


static func _spark_mesh() -> BoxMesh:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	# Toplamalı karışım: koyu zeminde de parlak görünür.
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.no_depth_test = false
	var box: BoxMesh = BoxMesh.new()
	box.size = SIZE
	box.material = material
	return box
