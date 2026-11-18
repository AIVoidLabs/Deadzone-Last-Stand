class_name ExplosionFx
extends Node3D
## Bomba patlaması: yerde genişleyen şok halkası, turuncu parlama küresi ve fırlayan kıvılcımlar.
## Patlama seyrek olduğu için havuz yok (MergeBurst gibi); bir kez oynar, kendini siler. Sayı kalite profilinden.

const RING_TIME: float = 0.35
const FLASH_TIME: float = 0.14
const SPARK_LIFETIME: float = 0.7
const SPARKS_PER_AMOUNT: int = 4
const COLOR: Color = Color(1.0, 0.55, 0.15)


static func play(parent: Node, at: Vector3, radius: float) -> void:
	var fx: ExplosionFx = ExplosionFx.new()
	fx.name = "ExplosionFx"
	parent.add_child(fx)
	fx.global_position = at
	fx._start(radius)


func _start(radius: float) -> void:
	_add_flash(radius)
	_add_ring(radius)
	_add_sparks(radius)
	get_tree().create_timer(SPARK_LIFETIME + 0.2).timeout.connect(queue_free)


func _unshaded(alpha: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(COLOR.r, COLOR.g, COLOR.b, alpha)
	return material


func _add_flash(radius: float) -> void:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 6
	var material: StandardMaterial3D = _unshaded(0.4)
	sphere.material = material
	var flash: MeshInstance3D = MeshInstance3D.new()
	flash.mesh = sphere
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.position.y = 0.5
	flash.scale = Vector3.ONE * radius * 0.4
	add_child(flash)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * radius * 1.3, FLASH_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "albedo_color:a", 0.0, FLASH_TIME)


func _add_ring(radius: float) -> void:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.46
	torus.outer_radius = 0.5
	torus.rings = 32
	torus.ring_segments = 6
	var material: StandardMaterial3D = _unshaded(0.8)
	torus.material = material
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position.y = 0.08
	ring.scale = Vector3.ONE * radius * 0.5
	add_child(ring)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * radius * 2.0, RING_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "albedo_color:a", 0.0, RING_TIME)


func _add_sparks(radius: float) -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE * 0.05
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = COLOR.lerp(Color.WHITE, 0.4)
	box.material = material
	var sparks: CPUParticles3D = CPUParticles3D.new()
	sparks.mesh = box
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = int(Quality.get_value("spark_amount")) * SPARKS_PER_AMOUNT
	sparks.lifetime = SPARK_LIFETIME
	sparks.direction = Vector3.UP
	sparks.spread = 70.0
	sparks.initial_velocity_min = radius * 1.2
	sparks.initial_velocity_max = radius * 3.0
	sparks.gravity = Vector3(0.0, -9.0, 0.0)
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.6
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)
	sparks.emitting = true
