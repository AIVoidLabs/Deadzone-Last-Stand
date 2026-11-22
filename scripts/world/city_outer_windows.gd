class_name CityOuterWindows
extends Node3D
## 8.3j: dis bloklarin (CityGreybox.OUTER_BLOCKS, egik olmayanlar) sokaga bakan yuzlerinde pencere izgarasi.
## Cogu karanlik cam, cok azi sonuk sicak. Tek MultiMesh, golgesiz. Kapatma: Tuning.FEATURE_CITY_OUTER_WINDOWS.

const WINDOW_SHADER: Shader = preload("res://assets/shaders/city_facade_window.gdshader")
const MASK: String = "res://assets/textures/fx/kenney/window_01.png"


## Bir yuzdeki pencere merkezleri: face = {origin: yuz orta noktasi (x,z), tangent, normal, length, height}.
static func face_positions(length: float, height: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cols: int = int(floorf((length - Tuning.CITY_OUTER_WINDOW_EDGE_MARGIN * 2.0) / Tuning.CITY_OUTER_WINDOW_COL_STEP)) + 1
	var floors: int = int(floorf((height - Tuning.CITY_OUTER_WINDOW_TOP_MARGIN - Tuning.CITY_OUTER_WINDOW_FIRST_Z) / Tuning.CITY_OUTER_WINDOW_FLOOR_STEP)) + 1
	for c: int in maxi(cols, 0):
		var along: float = (float(c) - float(cols - 1) * 0.5) * Tuning.CITY_OUTER_WINDOW_COL_STEP
		for f: int in maxi(floors, 0):
			out.append(Vector2(along, Tuning.CITY_OUTER_WINDOW_FIRST_Z + float(f) * Tuning.CITY_OUTER_WINDOW_FLOOR_STEP))
	return out


## Blok satiri icin sokaga bakan yuzler: [{mid: Vector3, normal: Vector3, length, height}]. Egik blok bos doner.
static func street_faces(row: Array, sx: float, sz: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if row[6]:
		return out
	var reach: float = Tuning.CITY_OUTER_WINDOW_STREET_REACH
	if row[0] <= reach:   # z koluna bakan yuz (x = sx * row[0])
		out.append({"mid": Vector3(sx * row[0], 0.0, sz * (row[1] + row[3] * 0.5)), "normal": Vector3(-sx, 0.0, 0.0), "length": row[3], "height": row[4]})
	if row[1] <= reach:   # x koluna bakan yuz (z = sz * row[1])
		out.append({"mid": Vector3(sx * (row[0] + row[2] * 0.5), 0.0, sz * row[1]), "normal": Vector3(0.0, 0.0, -sz), "length": row[2], "height": row[4]})
	return out


func _ready() -> void:
	name = "CityOuterWindows"
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = Tuning.DRESS_SEED + 404
	var xfs: Array[Transform3D] = []
	var colors: Array[Color] = []
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			for row: Array in CityGreybox.OUTER_BLOCKS:
				for face: Dictionary in street_faces(row, sx, sz):
					_add_face(face, rng, xfs, colors)
	_flush(xfs, colors)


func _add_face(face: Dictionary, rng: RandomNumberGenerator, xfs: Array[Transform3D], colors: Array[Color]) -> void:
	var normal: Vector3 = face["normal"]
	var tangent: Vector3 = Vector3.UP.cross(normal)
	var basis: Basis = Basis(tangent, Vector3.UP, normal) * Basis.from_scale(Vector3(Tuning.CITY_FACADE_WINDOW_SIZE.x, Tuning.CITY_FACADE_WINDOW_SIZE.y, 1.0))
	var mid: Vector3 = face["mid"] + normal * Tuning.CITY_FACADE_OFFSET
	for p: Vector2 in face_positions(face["length"], face["height"]):
		var pos: Vector3 = mid + tangent * p.x + Vector3(0.0, p.y, 0.0)
		xfs.append(Transform3D(basis, pos))
		colors.append(Tuning.CITY_OUTER_WINDOW_LIT_COLOR if rng.randf() < Tuning.CITY_OUTER_WINDOW_LIT_CHANCE else Tuning.CITY_OUTER_WINDOW_DARK_COLOR)


func _flush(xfs: Array[Transform3D], colors: Array[Color]) -> void:
	if xfs.is_empty():
		return
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, colors[i])
		mm.set_instance_custom_data(i, Color(float(i) * 0.37, 0.0, 0.0, 0.0))
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = WINDOW_SHADER
	mat.set_shader_parameter(&"mask", load(MASK))
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
