class_name BossTrailFx
extends Node3D
## Boss hücumunun yanan yarık izinin görüntüsü (yalnız görüntü, havuzlu): EnemyManager.boss_event "trail" olayı bir yuvaya
## (slot) çatlak + turuncu parıltı düzlemi koyar (boss_trail shader), birkaç kor kıvılcımı yükselir; ömrün sonunda söner.
## Yuva sayısı boss satırındaki trail_max kadar (olaylarla büyür). Kıvılcım sayısı kalite profilinden (spark_amount).
## Hasar ve ömür BossTrail'de (kurallar); burada yalnız aynı ömür çizilir.

const SHADER: Shader = preload("res://assets/shaders/boss_trail.gdshader")
const HEIGHT: float = 0.04
## Düzlemin yarı boyu, parça yarıçapından bu kadar kat büyüktür (kenar yumuşaması taşmasın).
const PLANE_SCALE: float = 1.25
const EMBER_LIFETIME: float = 0.9
const EMBERS_PER_SPARK_AMOUNT: float = 0.3
const EMBER_COLOR: Color = Color(1.0, 0.55, 0.15)
## Parçalar üst üste binerken z-çakışmasın: yuva başına yükseklik farkı.
const SLOT_HEIGHT_STEP: float = 0.0004
## Kıvılcım yalnız parlaklık bu eşiğin üstündeyken çıkar (sönerken kesilir).
const EMBER_MIN_POWER: float = 0.3
const EMBER_SIZE: float = 0.09
## Kıvılcım yayılımı: kaynak küre yarıçapı (parça yarıçapı oranı), koni açısı (derece), hız aralığı, yerçekimi, ölçek aralığı.
const EMBER_RADIUS_FACTOR: float = 0.7
const EMBER_SPREAD: float = 25.0
const EMBER_SPEED_MIN: float = 0.6
const EMBER_SPEED_MAX: float = 1.6
const EMBER_RISE: float = 1.2
const EMBER_SCALE_MIN: float = 0.4
const EMBER_SCALE_MAX: float = 1.2
## Boss ölünce kalan izin sönme süresi (sn).
const STOP_FADE_TIME: float = 0.6

var _slots: Array[Dictionary] = []
var _mesh: PlaneMesh
var _material: ShaderMaterial
var _ember_mesh: BoxMesh
var _ember_material: StandardMaterial3D


func setup(enemies: EnemyManager) -> void:
	enemies.boss_event.connect(_on_boss_event)


func _ready() -> void:
	name = "BossTrailFx"
	_mesh = PlaneMesh.new()
	_mesh.size = Vector2(2.0, 2.0)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_ember_mesh = BoxMesh.new()
	_ember_mesh.size = Vector3.ONE * EMBER_SIZE
	_ember_material = StandardMaterial3D.new()
	_ember_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ember_material.albedo_color = EMBER_COLOR
	_ember_mesh.material = _ember_material
	set_process(false)


func _process(delta: float) -> void:
	var any: bool = false
	for slot: Dictionary in _slots:
		if float(slot["left"]) <= 0.0:
			continue
		slot["left"] = float(slot["left"]) - delta
		var plane: MeshInstance3D = slot["plane"]
		if float(slot["left"]) <= 0.0:
			plane.visible = false
			(slot["embers"] as CPUParticles3D).emitting = false
			continue
		any = true
		var power: float = BossTrail.intensity(float(slot["life"]) - float(slot["left"]), float(slot["life"]), float(slot["fade"]))
		plane.set_instance_shader_parameter(&"power", power)
		(slot["embers"] as CPUParticles3D).emitting = power > EMBER_MIN_POWER
	if not any:
		set_process(false)


func _on_boss_event(event_name: StringName, data: Dictionary) -> void:
	if event_name == &"trail_stop":
		_fade_out_now()
		return
	if event_name != &"trail":
		return
	var index: int = int(data["slot"])
	while _slots.size() <= index:
		_slots.append(_make_slot())
	var slot: Dictionary = _slots[index]
	var at: Vector3 = data["at"]
	var radius: float = float(data["radius"])
	slot["life"] = float(data["life"])
	slot["fade"] = float(data["fade"])
	slot["left"] = float(data["life"])
	var plane: MeshInstance3D = slot["plane"]
	plane.global_position = Vector3(at.x, HEIGHT + SLOT_HEIGHT_STEP * index, at.z)
	plane.scale = Vector3(radius * PLANE_SCALE, 1.0, radius * PLANE_SCALE)
	plane.set_instance_shader_parameter(&"seed", randf())
	plane.set_instance_shader_parameter(&"power", 1.0)
	plane.visible = true
	var embers: CPUParticles3D = slot["embers"]
	embers.global_position = Vector3(at.x, HEIGHT, at.z)
	embers.emission_sphere_radius = radius * EMBER_RADIUS_FACTOR
	embers.restart()
	embers.emitting = true
	set_process(true)


## Boss öldü: yanan parçalar kısa sürede (STOP_FADE_TIME) söner (hasar zaten BossTrail'de durdu).
func _fade_out_now() -> void:
	for slot: Dictionary in _slots:
		if float(slot["left"]) > 0.0:
			slot["fade"] = minf(float(slot["fade"]), STOP_FADE_TIME)
			slot["left"] = minf(float(slot["left"]), STOP_FADE_TIME)


func _make_slot() -> Dictionary:
	var plane: MeshInstance3D = MeshInstance3D.new()
	plane.mesh = _mesh
	plane.material_override = _material
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plane.visible = false
	add_child(plane)
	var embers: CPUParticles3D = CPUParticles3D.new()
	embers.mesh = _ember_mesh
	embers.amount = maxi(int(float(Quality.get_value("spark_amount")) * EMBERS_PER_SPARK_AMOUNT), 1)
	embers.lifetime = EMBER_LIFETIME
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.direction = Vector3.UP
	embers.spread = EMBER_SPREAD
	embers.initial_velocity_min = EMBER_SPEED_MIN
	embers.initial_velocity_max = EMBER_SPEED_MAX
	embers.gravity = Vector3(0.0, EMBER_RISE, 0.0)
	embers.scale_amount_min = EMBER_SCALE_MIN
	embers.scale_amount_max = EMBER_SCALE_MAX
	embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	embers.emitting = false
	add_child(embers)
	return {"plane": plane, "embers": embers, "life": 1.0, "fade": 0.5, "left": 0.0}
