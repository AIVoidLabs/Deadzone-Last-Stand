class_name CityFacadeLights
extends Node3D
## 8.3h: bina cepheleri. Her iç binanın iki sokak yüzünde pencere ızgarası (çoğu karanlık cam, birkaç sıcak sarı,
## bazen soluk mavi TV ışığı) ve duvar lambaları (küçük ampul + cephede ve kaldırımda sahte ışık lekesi).
## Kapatma: Tuning.FEATURE_CITY_FACADE_LIGHTS.

const WINDOW_SHADER: Shader = preload("res://assets/shaders/city_facade_window.gdshader")
const MASK_PATH: String = "res://assets/textures/fx/kenney/%s.png"
const MASKS: Array[String] = ["window_01", "window_03"]
const DARK: Color = Color(0.09, 0.11, 0.17, 0.4)
const WARM: Array[Color] = [Color(1.0, 0.62, 0.22, 0.95), Color(1.0, 0.78, 0.4, 0.95), Color(0.95, 0.5, 0.18, 0.95)]
const TV: Color = Color(0.2, 0.3, 0.5, 0.95)
const BRACKET: Color = Color(0.06, 0.06, 0.07)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _windows: Array[Dictionary] = []   # maske başına {xfs, colors, customs}
var _lamp_nodes: Array[Node3D] = []


func _ready() -> void:
	name = "CityFacadeLights"
	_rng.seed = Tuning.DRESS_SEED + 303
	for i: int in MASKS.size():
		_windows.append({"xfs": [] as Array[Transform3D], "colors": [] as Array[Color], "customs": [] as Array[Color]})
	for rect: Rect2 in CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH):
		var c: Vector2 = rect.get_center()
		# Sokağa (kavşak eksenlerine) bakan iki yüz
		_face(Vector3(c.x, 0.0, c.y), Vector3(-signf(c.x), 0.0, 0.0), rect.size.x * 0.5, rect.size.y)
		_face(Vector3(c.x, 0.0, c.y), Vector3(0.0, 0.0, -signf(c.y)), rect.size.y * 0.5, rect.size.x)
	_flush_windows()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


## Yüz: merkezden normal yönünde yarı boyut kadar ileride, genişlik face_width.
func _face(center: Vector3, normal: Vector3, half_depth: float, face_width: float) -> void:
	var origin: Vector3 = center + normal * (half_depth + Tuning.CITY_FACADE_OFFSET)
	var tangent: Vector3 = Vector3.UP.cross(normal)
	var basis: Basis = Basis(tangent, Vector3.UP, normal)
	var columns: int = int(floorf(face_width / Tuning.CITY_FACADE_COLUMN_STEP))
	var slots: Array[Vector2i] = []
	for r: int in Tuning.CITY_FACADE_ROWS.size():
		for col: int in columns:
			slots.append(Vector2i(r, col))
	var lit_target: int = maxi(2, int(roundf(float(slots.size()) * Tuning.CITY_FACADE_LIT_CHANCE)))
	var lit: Dictionary = {}
	while lit.size() < lit_target:
		lit[slots[_rng.randi() % slots.size()]] = true
	for slot: Vector2i in slots:
		var along: float = (float(slot.y) - (columns - 1) * 0.5) * Tuning.CITY_FACADE_COLUMN_STEP
		var pos: Vector3 = origin + tangent * along + Vector3(0.0, Tuning.CITY_FACADE_ROWS[slot.x], 0.0)
		var color: Color = DARK
		var tv: float = 0.0
		if lit.has(slot):
			if _rng.randf() < Tuning.CITY_FACADE_TV_CHANCE / Tuning.CITY_FACADE_LIT_CHANCE:
				color = TV
				tv = 1.0
			else:
				color = WARM[_rng.randi() % WARM.size()]
		var g: Dictionary = _windows[0 if _rng.randf() < 0.7 else 1]
		g["xfs"].append(Transform3D(basis * Basis.from_scale(Vector3(Tuning.CITY_FACADE_WINDOW_SIZE.x, Tuning.CITY_FACADE_WINDOW_SIZE.y, 1.0)), pos))
		g["colors"].append(color)
		g["customs"].append(Color(_rng.randf(), tv, 0.0, 0.0))
	for k: int in Tuning.CITY_FACADE_LAMPS_PER_FACE:
		var span: float = face_width * 0.5 - 2.5
		var along: float = (float(k) + 0.5) / float(Tuning.CITY_FACADE_LAMPS_PER_FACE) * span * 2.0 - span + _rng.randf_range(-0.8, 0.8)
		_lamp(origin + tangent * along, normal, basis, k == 0)


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
func _lamp(wall: Vector3, normal: Vector3, basis: Basis, flickers: bool) -> void:
	var pos: Vector3 = Vector3(wall.x, Tuning.CITY_FACADE_LAMP_HEIGHT, wall.z)
	var color: Color = Tuning.CITY_FACADE_LAMP_COLOR
	var bracket: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.14, 0.14, 0.3)
	bracket.mesh = box
	bracket.material_override = CityFxAssets.emissive(BRACKET, 0.0)
	bracket.transform = Transform3D(basis, pos + normal * 0.15)
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
	on_wall.transform = Transform3D(basis, pos + normal * 0.05 - Vector3(0.0, 0.8, 0.0))
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
