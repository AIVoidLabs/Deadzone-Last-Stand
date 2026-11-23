class_name CityFacadeLights
extends Node3D
## 8.3h: bina cepheleri. Her iç binanın iki sokak yüzünde pencere ızgarası (bina A'nın gerçek pencere ızgarasında: kapkara cam, birkaç sönük sarı,
## çok az soluk mavi TV) ve duvar lambaları (küçük ampul + cephede ve kaldırımda sahte ışık lekesi).
## Kapatma: Tuning.FEATURE_CITY_FACADE_LIGHTS.

const WINDOW_SHADER: Shader = preload("res://assets/shaders/city_facade_window.gdshader")
const MASK_PATH: String = "res://assets/textures/fx/kenney/%s.png"
const MASKS: Array[String] = ["window_01", "window_03"]
const DARK: Color = Color(0.012, 0.012, 0.016, 0.55)
const WARM: Array[Color] = [Color(1.0, 0.62, 0.22, 0.95), Color(1.0, 0.78, 0.4, 0.95), Color(0.95, 0.5, 0.18, 0.95)]
const TV: Color = Color(0.13, 0.19, 0.3, 0.9)
const BRACKET: Color = Color(0.06, 0.06, 0.07)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _windows: Array[Dictionary] = []   # maske başına {xfs, colors, customs}
var _lamp_nodes: Array[Node3D] = []


func _ready() -> void:
	name = "CityFacadeLights"
	_rng.seed = Tuning.DRESS_SEED + 303
	for i: int in MASKS.size():
		_windows.append({"xfs": [] as Array[Transform3D], "colors": [] as Array[Color], "customs": [] as Array[Color]})
	var rects: Array[Rect2] = CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH)
	for rect: Rect2 in rects:
		var c: Vector2 = rect.get_center()
		_building(Vector3(c.x, 0.0, c.y), _quarter(c))
	_flush_windows()
	if Tuning.FEATURE_CITY_WINDOW_DIM:
		_dim_model_windows()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


## Bina modelindeki yanan pencere malzemesi (paylaşılan kaynak) sönük amber olur; glb dosyası değişmez.
func _dim_model_windows() -> void:
	var scene: PackedScene = load(Tuning.CITY_BUILDING_SCENE) as PackedScene
	if scene == null:
		return
	var root: Node = scene.instantiate()
	for mi: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for s: int in mesh.get_surface_count():
			var mat: StandardMaterial3D = mesh.surface_get_material(s) as StandardMaterial3D
			if mat != null and mat.resource_name == Tuning.CITY_WINDOW_DIM_MATERIAL:
				mat.emission = Tuning.CITY_WINDOW_DIM_COLOR
				mat.emission_energy_multiplier = Tuning.CITY_WINDOW_DIM_ENERGY
	root.free()


## Bina A'nın gerçek pencere ızgarası (tools/blender/build_city_building.py: WIN_U, WIN_Z, WINDOWS) dünyaya döndürülür.
## Yüz: model +X (satırlar MODEL_X) ve +Z (MODEL_Z) cepheleri; kuzey-güney dönüş city_greybox._place_building ile aynı.
func _building(center: Vector3, quarter: int) -> void:
	var yaw: Basis = Basis(Vector3.UP, deg_to_rad(90.0 * quarter))
	_face(center, yaw, Vector3.RIGHT, Vector3.FORWARD, Tuning.CITY_FACADE_MODEL_X)
	_face(center, yaw, Vector3.BACK, Vector3.RIGHT, Tuning.CITY_FACADE_MODEL_Z)
	_lamps(center, yaw)


func _face(center: Vector3, yaw: Basis, normal_local: Vector3, tangent_local: Vector3, rows: Array[String]) -> void:
	var normal: Vector3 = yaw * normal_local
	var tangent: Vector3 = yaw * tangent_local
	var origin: Vector3 = center + normal * (Tuning.CITY_FACADE_HALF + Tuning.CITY_FACADE_OFFSET)
	var xform_basis: Basis = Basis(tangent, Vector3.UP, normal)
	for r: int in rows.size():
		for col: int in rows[r].length():
			var state: String = rows[r][col]
			var color: Color = Color.BLACK
			var tv: float = 0.0
			if state == "D":
				color = DARK
				if _rng.randf() < Tuning.CITY_FACADE_TV_CHANCE:
					color = TV
					tv = 1.0
			elif state == "L" and _rng.randf() < Tuning.CITY_FACADE_LIT_KEEP:
				color = WARM[_rng.randi() % WARM.size()]
			else:
				continue
			var along: float = Tuning.CITY_FACADE_WINDOW_U[col]
			var pos: Vector3 = origin + tangent * along + Vector3(0.0, Tuning.CITY_FACADE_WINDOW_Z[r], 0.0)
			var g: Dictionary = _windows[0 if _rng.randf() < 0.7 else 1]
			g["xfs"].append(Transform3D(xform_basis * Basis.from_scale(Vector3(Tuning.CITY_FACADE_WINDOW_SIZE.x, Tuning.CITY_FACADE_WINDOW_SIZE.y, 1.0)), pos))
			g["colors"].append(color)
			g["customs"].append(Color(_rng.randf(), tv, 0.0, 0.0))


## Duvar lambaları: yüz başına CITY_FACADE_LAMPS_PER_FACE, pencere hattının dışında.
func _lamps(center: Vector3, yaw: Basis) -> void:
	for face: int in 2:
		var normal: Vector3 = yaw * (Vector3.RIGHT if face == 0 else Vector3.BACK)
		var tangent: Vector3 = yaw * (Vector3.FORWARD if face == 0 else Vector3.RIGHT)
		var origin: Vector3 = center + normal * (Tuning.CITY_FACADE_HALF + Tuning.CITY_FACADE_OFFSET)
		var xform_basis: Basis = Basis(tangent, Vector3.UP, normal)
		for k: int in Tuning.CITY_FACADE_LAMPS_PER_FACE:
			var span: float = Tuning.CITY_FACADE_HALF - 2.5
			var along: float = (float(k) + 0.5) / float(Tuning.CITY_FACADE_LAMPS_PER_FACE) * span * 2.0 - span + _rng.randf_range(-0.8, 0.8)
			_lamp(origin + tangent * along, normal, xform_basis, k == 0 and face == 0)


## Bina modelinin köşe dönüşü (city_greybox._place_building ile aynı).
func _quarter(c: Vector2) -> int:
	if c.x < 0.0:
		return 0 if c.y < 0.0 else 1
	return 2 if c.y > 0.0 else 3


func _flush_windows() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	for i: int in _windows.size():
		var g: Dictionary = _windows[i]
		var xfs: Array = g["xfs"]
		if xfs.is_empty():
			continue
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = quad
		mm.instance_count = xfs.size()
		for j: int in xfs.size():
			mm.set_instance_transform(j, xfs[j])
			mm.set_instance_color(j, g["colors"][j])
			mm.set_instance_custom_data(j, g["customs"][j])
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = WINDOW_SHADER
		mat.set_shader_parameter(&"mask", load(MASK_PATH % MASKS[i]))
		var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
		node.multimesh = mm
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)


## Duvar lambası: koyu braket + ampul; cephede ve altındaki kaldırımda sahte ışık lekesi.
func _lamp(wall: Vector3, normal: Vector3, xform_basis: Basis, flickers: bool) -> void:
	var pos: Vector3 = Vector3(wall.x, Tuning.CITY_FACADE_LAMP_HEIGHT, wall.z)
	var color: Color = Tuning.CITY_FACADE_LAMP_COLOR
	var bracket: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.14, 0.14, 0.3)
	bracket.mesh = box
	bracket.material_override = CityFxAssets.emissive(BRACKET, 0.0)
	bracket.transform = Transform3D(xform_basis, pos + normal * 0.15)
	add_child(bracket)
	var bulb: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.11
	sphere.height = 0.22
	sphere.radial_segments = 10
	sphere.rings = 5
	bulb.mesh = sphere
	bulb.material_override = CityFxAssets.emissive(color, 6.0)
	bulb.position = pos + normal * 0.36 - Vector3(0.0, 0.05, 0.0)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bulb)
	var flicker: float = 0.25 if flickers else 0.04
	var on_wall: MeshInstance3D = MeshInstance3D.new()
	var wall_quad: QuadMesh = QuadMesh.new()
	wall_quad.size = Vector2.ONE * Tuning.CITY_FACADE_LAMP_RADIUS * 2.0
	on_wall.mesh = wall_quad
	on_wall.material_override = CityFxAssets.glow_material(color, Tuning.CITY_FACADE_LAMP_WALL_ENERGY, flicker, pos.x + pos.z)
	on_wall.transform = Transform3D(xform_basis, pos + normal * 0.05 - Vector3(0.0, 0.8, 0.0))
	on_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(on_wall)
	var ground: MeshInstance3D = CityFxAssets.glow_quad(pos + normal * 2.0, Tuning.CITY_FACADE_LAMP_RADIUS * 1.1, color, Tuning.CITY_FACADE_LAMP_GROUND_ENERGY, flicker)
	add_child(ground)
	_lamp_nodes.append(ground)


## Düşük profilde zemin lekelerinin yarısı kapanır.
func _apply_quality(_profile_id: StringName) -> void:
	var factor: float = Quality.get_value("ground_dressing")
	for i: int in _lamp_nodes.size():
		_lamp_nodes[i].visible = float(i) < float(_lamp_nodes.size()) * factor
