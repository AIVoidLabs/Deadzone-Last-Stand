class_name LobProjectiles
extends Node3D
## Yay atışının görüntüsü (yalnız görüntü, havuzlu): uçan asit topu (yeşil parlayan küre + kısa iz) ve kaya, yerde
## inişi önceden gösteren gölge işareti. Kaya inince ROCK_REST_TIME sn yerde kalıp solar (küçülür). Gerçek uçuş ve
## hasar LobAttack'ta; `EnemyManager.lob_launched` buraya bağlanır. Kaya modeli assets/models/props/thrown_rock.glb
## varsa o, yoksa koyu gri yedek kutu kullanılır.

const SHADOW_SHADER: Shader = preload("res://assets/shaders/jump_shadow.gdshader")
const ROCK_PATH: String = "res://assets/models/props/thrown_rock.glb"
const SHADOW_HEIGHT: float = 0.03
const BALL_RADIUS: float = 0.2
const ROCK_SIZE: float = 0.45
const ACID_COLOR: Color = Color(0.35, 0.95, 0.2)
const ROCK_COLOR: Color = Color(0.3, 0.29, 0.28)
## İzdeki küreler: boy oranı.
const TRAIL_SCALES: Array[float] = [0.7, 0.45]

var _slots: Array[Dictionary] = []
var _next: int = 0
var _ball_mesh: SphereMesh
var _ball_material: StandardMaterial3D
var _rock_material: StandardMaterial3D
var _rock_scene: PackedScene


func _ready() -> void:
	name = "LobProjectiles"
	_build_assets()
	for _i in Tuning.LOB_POOL_SIZE:
		_slots.append(_make_slot())
	set_process(false)


## kind: &"spit" / &"throw". from/dest: dünya konumu (from bırakış yüksekliğinde); radius: iniş gölgesi yarıçapı.
func launch(kind: StringName, from: Vector3, dest: Vector3, flight: float, arc: float, radius: float) -> void:
	var slot: Dictionary = _slots[_next]
	_next = (_next + 1) % _slots.size()
	slot["kind"] = kind
	slot["from"] = Vector2(from.x, from.z)
	slot["height"] = from.y
	slot["dest"] = Vector2(dest.x, dest.z)
	slot["flight"] = flight
	slot["arc"] = arc
	slot["age"] = 0.0
	slot["active"] = true
	var spit: bool = kind == &"spit"
	(slot["ball"] as Node3D).visible = spit
	(slot["rock"] as Node3D).visible = not spit
	(slot["rock"] as Node3D).scale = Vector3.ONE
	for trail: Node3D in slot["trail"]:
		trail.visible = spit
	var shadow: MeshInstance3D = slot["shadow"]
	shadow.scale = Vector3(radius, 1.0, radius)
	shadow.global_position = Vector3(dest.x, SHADOW_HEIGHT, dest.z)
	shadow.visible = true
	(shadow.material_override as ShaderMaterial).set_shader_parameter(&"urgency", 0.0)
	_place(slot, 0.0)
	set_process(true)


func _process(delta: float) -> void:
	var any: bool = false
	for slot: Dictionary in _slots:
		if not slot["active"]:
			continue
		any = true
		slot["age"] = float(slot["age"]) + delta
		_step(slot)
	if not any:
		set_process(false)


func _step(slot: Dictionary) -> void:
	var age: float = slot["age"]
	var flight: float = slot["flight"]
	if age < flight:
		_place(slot, age)
		var shadow: MeshInstance3D = slot["shadow"]
		(shadow.material_override as ShaderMaterial).set_shader_parameter(&"urgency", LobRules.progress(age, flight))
		return
	(slot["shadow"] as Node3D).visible = false
	(slot["ball"] as Node3D).visible = false
	for trail: Node3D in slot["trail"]:
		trail.visible = false
	if slot["kind"] != &"throw":
		slot["active"] = false
		return
	# Kaya yerde durur, son ROCK_FADE_TIME sn'de küçülüp yok olur.
	var rock: Node3D = slot["rock"]
	var dest: Vector2 = slot["dest"]
	rock.global_position = Vector3(dest.x, ROCK_SIZE * 0.3, dest.y)
	var left: float = Tuning.ROCK_REST_TIME - (age - flight)
	if left <= 0.0:
		slot["active"] = false
		rock.visible = false
	else:
		rock.scale = Vector3.ONE * clampf(left / Tuning.ROCK_FADE_TIME, 0.0, 1.0)


## Uçuşun age anındaki konumu: top/kaya ve izdeki küreler.
func _place(slot: Dictionary, age: float) -> void:
	var from: Vector2 = slot["from"]
	var dest: Vector2 = slot["dest"]
	var flight: float = slot["flight"]
	var arc: float = slot["arc"]
	var spit: bool = slot["kind"] == &"spit"
	var head: Node3D = slot["ball"] if spit else slot["rock"]
	var height: float = slot["height"]
	head.global_position = LobRules.position_at(from, dest, age / flight, arc, height)
	if not spit:
		head.rotation = Vector3(age * 6.0, age * 4.0, 0.0)
		return
	var trail: Array = slot["trail"]
	for k in trail.size():
		var back: float = maxf(age - Tuning.LOB_TRAIL_STEP * float(k + 1), 0.0)
		(trail[k] as Node3D).global_position = LobRules.position_at(from, dest, back / flight, arc, height)


func _make_slot() -> Dictionary:
	var slot: Dictionary = {"active": false, "kind": &"spit", "age": 0.0, "flight": 1.0, "arc": 1.0, "from": Vector2.ZERO, "height": Tuning.LOB_RELEASE_HEIGHT, "dest": Vector2.ZERO}
	var trail: Array[Node3D] = []
	for factor: float in TRAIL_SCALES:
		trail.append(_make_ball(factor))
	slot["ball"] = _make_ball(1.0)
	slot["rock"] = _make_rock()
	slot["trail"] = trail
	slot["shadow"] = _make_shadow()
	return slot


func _make_shadow() -> MeshInstance3D:
	var shadow: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADOW_SHADER
	material.set_shader_parameter(&"max_darkness", Tuning.JUMP_SHADOW_DARKNESS)
	material.set_shader_parameter(&"soft_start", Tuning.JUMP_SHADOW_SOFT_START)
	material.set_shader_parameter(&"soft_end", Tuning.JUMP_SHADOW_SOFT_END)
	material.set_shader_parameter(&"edge_width", Tuning.JUMP_SHADOW_EDGE_WIDTH)
	material.set_shader_parameter(&"edge_strength", Tuning.JUMP_SHADOW_EDGE_STRENGTH)
	shadow.mesh = plane
	shadow.material_override = material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.visible = false
	add_child(shadow)
	return shadow


func _make_ball(factor: float) -> MeshInstance3D:
	var ball: MeshInstance3D = MeshInstance3D.new()
	ball.mesh = _ball_mesh
	ball.material_override = _ball_material
	ball.scale = Vector3.ONE * factor
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ball.visible = false
	add_child(ball)
	return ball


func _make_rock() -> Node3D:
	var rock: Node3D
	if _rock_scene != null:
		rock = _rock_scene.instantiate() as Node3D
		_paint_rock(rock)
	else:
		var box: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(ROCK_SIZE, ROCK_SIZE * 0.8, ROCK_SIZE * 0.9)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = ROCK_COLOR
		material.roughness = 0.95
		mesh.material = material
		box.mesh = mesh
		rock = box
	rock.visible = false
	add_child(rock)
	return rock


## GLB köşe renkli: malzeme köşe rengini albedo olarak kullanır (yoksa düz beyaz görünür).
func _paint_rock(node: Node) -> void:
	for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = _rock_material
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_assets() -> void:
	_rock_material = StandardMaterial3D.new()
	_rock_material.vertex_color_use_as_albedo = true
	_rock_material.albedo_color = Color(0.8, 0.78, 0.76)
	_rock_material.roughness = 0.95
	_ball_mesh = SphereMesh.new()
	_ball_mesh.radius = BALL_RADIUS
	_ball_mesh.height = BALL_RADIUS * 2.0
	_ball_mesh.radial_segments = 12
	_ball_mesh.rings = 6
	_ball_material = StandardMaterial3D.new()
	_ball_material.albedo_color = ACID_COLOR
	_ball_material.emission_enabled = true
	_ball_material.emission = ACID_COLOR
	_ball_material.emission_energy_multiplier = 2.5
	if ResourceLoader.exists(ROCK_PATH):
		_rock_scene = load(ROCK_PATH) as PackedScene
