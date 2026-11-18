class_name MergeBurst
extends Node3D
## Silah birleşince: kademe renginde genişleyen halka + kıvılcım patlaması. Bir kez oynar, sonra kendini siler.
## Birleşme seyrek olduğu için havuz yok. Sayı kalite profilinden (spark_amount).

const RING_TIME: float = 0.5
const RING_END_SCALE: float = 1.5
const SPARK_LIFETIME: float = 0.55
const SPARKS_PER_AMOUNT: int = 3


static func play(parent: Node3D, color: Color) -> void:
	var burst: MergeBurst = MergeBurst.new()
	burst.name = "MergeBurst"
	parent.add_child(burst)
	burst._start(color)


func _start(color: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.9)
	_add_ring(material)
	_add_sparks(color)
	get_tree().create_timer(SPARK_LIFETIME + 0.2).timeout.connect(queue_free)


func _add_ring(material: StandardMaterial3D) -> void:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.47
	torus.outer_radius = 0.5
	torus.rings = 24
	torus.ring_segments = 6
	torus.material = material
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.scale = Vector3.ONE * 0.3
	add_child(ring)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * RING_END_SCALE, RING_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "albedo_color:a", 0.0, RING_TIME)


func _add_sparks(color: Color) -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE * 0.025
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color.lerp(Color.WHITE, 0.4)
	box.material = material
	var sparks: CPUParticles3D = CPUParticles3D.new()
	sparks.mesh = box
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = int(Quality.get_value("spark_amount")) * SPARKS_PER_AMOUNT
	sparks.lifetime = SPARK_LIFETIME
	sparks.direction = Vector3.UP
	sparks.spread = 180.0
	sparks.initial_velocity_min = 0.8
	sparks.initial_velocity_max = 2.0
	sparks.gravity = Vector3(0.0, -4.0, 0.0)
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.4
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)
	sparks.emitting = true
