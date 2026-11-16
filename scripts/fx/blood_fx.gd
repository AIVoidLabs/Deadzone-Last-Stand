class_name BloodFx
extends Node3D
## Stilize kan: isabette küçük, ölümde büyük sıçrama (havuzlu parçacık) ve yerde solan lekeler
## (tek MultiMesh, halka tampon). Sayılar kalite profilinden: blood_amount, decal_max.

const DECAL_SHADER: Shader = preload("res://assets/shaders/blood_decal.gdshader")
const SPLASH_POOL: int = 24
const SPLASH_HEIGHT: float = 1.15
const SPLASH_SPREAD_DEG: float = 40.0
const SPLASH_SPEED: Vector2 = Vector2(2.0, 5.0)
const SPLASH_LIFETIME: float = 0.45
const SPLASH_GRAVITY: Vector3 = Vector3(0.0, -14.0, 0.0)
const DROP_SIZE: float = 0.07
const BLOOD_COLOR: Color = Color(0.36, 0.02, 0.03)
const DECAL_Y: float = 0.012
## Üst üste binen lekeler titreşmesin diye her lekeye eklenen küçük yükseklik farkı.
const DECAL_LAYER_STEP: float = 0.0004
const DECAL_LAYERS: int = 8
const DECAL_SIZE_HIT: Vector2 = Vector2(0.35, 0.6)
const DECAL_SIZE_KILL: Vector2 = Vector2(0.8, 1.2)

var _splashes: Array[CPUParticles3D] = []
var _next_splash: int = 0
var _decals: MultiMeshInstance3D
var _decal_born: PackedFloat32Array = PackedFloat32Array()
var _next_decal: int = 0
var _time: float = 0.0


func _ready() -> void:
	name = "BloodFx"
	_build_splashes()
	if Tuning.FEATURE_BLOOD_DECALS:
		_build_decals()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


func _process(delta: float) -> void:
	_time += delta
	if _decals != null:
		_fade_decals()


## at: zombinin yerdeki konumu; direction: merminin gidiş yönü (kan bu yöne saçılır).
func on_enemy_damaged(at: Vector3, direction: Vector2, _amount: float, killed: bool) -> void:
	_splash(at, direction, killed)
	if _decals == null:
		return
	if killed:
		_add_decal(at, direction, DECAL_SIZE_KILL, 0.4)
	elif randf() < Tuning.BLOOD_DECAL_CHANCE_HIT:
		_add_decal(at, direction, DECAL_SIZE_HIT, 0.9)


func _splash(at: Vector3, direction: Vector2, big: bool) -> void:
	var splash: CPUParticles3D = _splashes[_next_splash]
	_next_splash = (_next_splash + 1) % _splashes.size()
	var origin: Vector3 = at + Vector3.UP * SPLASH_HEIGHT
	splash.global_position = origin
	splash.look_at(origin + Vector3(direction.x, 0.25, direction.y).normalized(), Vector3.UP)
	var base: int = Quality.get_value("blood_amount")
	splash.amount = base * Tuning.BLOOD_KILL_MULTIPLIER if big else base
	splash.restart()


## Lekeyi vuruş yönünde, zombinin biraz ötesine bırakır. reach: yönde ne kadar ileri (m, en çok).
func _add_decal(at: Vector3, direction: Vector2, size_range: Vector2, reach: float) -> void:
	var count: int = _decals.multimesh.instance_count
	var index: int = _next_decal
	_next_decal = (_next_decal + 1) % count
	var offset: Vector2 = direction * randf_range(0.1, reach)
	var size: float = randf_range(size_range.x, size_range.y)
	var basis: Basis = Basis(Vector3.UP, randf() * TAU).scaled(Vector3(size, 1.0, size))
	var y: float = DECAL_Y + DECAL_LAYER_STEP * float(index % DECAL_LAYERS)
	_decals.multimesh.set_instance_transform(index, Transform3D(basis, Vector3(at.x + offset.x, y, at.z + offset.y)))
	_decals.multimesh.set_instance_custom_data(index, Color(randf(), 0.0, 0.0, 0.0))
	_decals.multimesh.set_instance_color(index, BLOOD_COLOR)
	_decal_born[index] = _time


func _fade_decals() -> void:
	var multimesh: MultiMesh = _decals.multimesh
	var fade_start: float = Tuning.BLOOD_DECAL_LIFETIME - Tuning.BLOOD_DECAL_FADE_TIME
	for i: int in multimesh.instance_count:
		var born: float = _decal_born[i]
		if born < 0.0:
			continue
		var age: float = _time - born
		if age < fade_start:
			continue
		var alpha: float = 1.0 - clampf((age - fade_start) / Tuning.BLOOD_DECAL_FADE_TIME, 0.0, 1.0)
		multimesh.set_instance_color(i, Color(BLOOD_COLOR, alpha))
		if alpha <= 0.0:
			_decal_born[i] = -1.0


func _build_splashes() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = BLOOD_COLOR
	material.roughness = 0.35
	var drop: BoxMesh = BoxMesh.new()
	drop.size = Vector3.ONE * DROP_SIZE
	drop.material = material
	var shrink: Curve = Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.2))
	for _i in SPLASH_POOL:
		var splash: CPUParticles3D = CPUParticles3D.new()
		splash.emitting = false
		splash.one_shot = true
		splash.explosiveness = 0.9
		splash.lifetime = SPLASH_LIFETIME
		splash.local_coords = false
		splash.mesh = drop
		splash.direction = Vector3.FORWARD
		splash.spread = SPLASH_SPREAD_DEG
		splash.gravity = SPLASH_GRAVITY
		splash.initial_velocity_min = SPLASH_SPEED.x
		splash.initial_velocity_max = SPLASH_SPEED.y
		splash.scale_amount_min = 0.5
		splash.scale_amount_max = 1.4
		splash.scale_amount_curve = shrink
		add_child(splash)
		_splashes.append(splash)


func _build_decals() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2.ONE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = DECAL_SHADER
	plane.material = material
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = plane
	_decals = MultiMeshInstance3D.new()
	_decals.name = "BloodDecals"
	_decals.multimesh = multimesh
	_decals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_decals)


func _apply_quality(_profile: StringName) -> void:
	if _decals == null:
		return
	var count: int = Quality.get_value("decal_max")
	var multimesh: MultiMesh = _decals.multimesh
	multimesh.instance_count = count
	_decal_born.resize(count)
	for i: int in count:
		_decal_born[i] = -1.0
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		multimesh.set_instance_color(i, Color(BLOOD_COLOR, 0.0))
	_next_decal = 0
