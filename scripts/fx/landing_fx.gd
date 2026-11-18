class_name LandingFx
extends Node3D
## Zıplayanın inişi: yerde genişleyen toz halkası ve yukarı savrulan toz parçacıkları.
## Seyrek olduğu için havuz yok (ExplosionFx gibi); bir kez oynar, kendini siler. Parçacık sayısı kalite profilinden.

const RING_TIME: float = 0.3
const DUST_LIFETIME: float = 0.6
const DUST_PER_AMOUNT: int = 3
const RING_COLOR: Color = Color(0.85, 0.78, 0.65)
const DUST_COLOR: Color = Color(0.62, 0.58, 0.52)


static func play(parent: Node, at: Vector3, radius: float) -> void:
	var fx: LandingFx = LandingFx.new()
	fx.name = "LandingFx"
	parent.add_child(fx)
	fx.global_position = at
	fx._start(radius)


func _start(radius: float) -> void:
	_add_ring(radius)
	_add_dust(radius)
	get_tree().create_timer(DUST_LIFETIME + 0.2).timeout.connect(queue_free)


func _add_ring(radius: float) -> void:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.44
	torus.outer_radius = 0.5
	torus.rings = 32
	torus.ring_segments = 6
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, 0.85)
	torus.material = material
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position.y = 0.06
	ring.scale = Vector3.ONE * radius * 0.4
	add_child(ring)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * radius * 2.2, RING_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "albedo_color:a", 0.0, RING_TIME)


func _add_dust(radius: float) -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE * 0.18
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = DUST_COLOR
	box.material = material
	var dust: CPUParticles3D = CPUParticles3D.new()
	dust.mesh = box
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.amount = int(Quality.get_value("spark_amount")) * DUST_PER_AMOUNT
	dust.lifetime = DUST_LIFETIME
	dust.direction = Vector3.UP
	dust.spread = 80.0
	dust.initial_velocity_min = radius * 1.0
	dust.initial_velocity_max = radius * 2.6
	dust.gravity = Vector3(0.0, -6.0, 0.0)
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.6
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)
	dust.emitting = true
