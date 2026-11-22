class_name CityGroundDressing
extends Node3D
## 8.3d: yer dekoru. Kâğıt/karton/enkaz, devrik koni, düşmüş tabela, ölü zombi cesetleri (kan ve zemin lekeleri: CityDecals).
## Hepsi MultiMesh, çarpışmasız; adet profildeki ground_dressing çarpanıyla. Kapatma: Tuning.FEATURE_CITY_GROUND_DRESSING.

const PAPER_SHADER: Shader = preload("res://assets/shaders/city_paper.gdshader")
const PROP_CLEARANCE: float = 2.8
const PAPER_COLORS: Array[Color] = [Color(0.5, 0.45, 0.36), Color(0.38, 0.32, 0.25), Color(0.3, 0.3, 0.29), Color(0.42, 0.28, 0.17)]
const SIGN_COLORS: Array[Color] = [Color(0.12, 0.3, 0.22), Color(0.5, 0.09, 0.07), Color(0.18, 0.22, 0.32)]
const CONE_COLOR: Color = Color(0.85, 0.32, 0.05)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _groups: Array[Dictionary] = []   # {node: MultiMeshInstance3D, total: int}
var _corpses: CityZombieCorpses
var _blocked: Array[Vector2] = []
var _hot: Array[Vector3] = []   # çöp kümelerinin merkezleri (prop, ceset, kan)


func _ready() -> void:
	name = "CityGroundDressing"
	_rng.seed = Tuning.DRESS_SEED
	for row: Dictionary in CityProps.rows():
		if row["collide"]:
			_blocked.append(row["pos"])
			_hot.append(Vector3(row["pos"].x, 0.0, row["pos"].y))
	var corpse_spots: Array[Vector3] = []
	_build_corpses(corpse_spots)
	if Tuning.FEATURE_CITY_BLOOD_DECALS or Tuning.FEATURE_CITY_GROUND_DECALS:
		add_child(CityDecals.new(_blocked, corpse_spots, _hot))
	_build_debris()
	_build_cones(corpse_spots)
	_build_signs()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


## Sokak haçı üzerinde rastgele nokta: alan içine ağırlıklı, kol boyunca seyrek.
func _street_point(margin: float = 0.0) -> Vector3:
	var half: float = Tuning.ARENA_SIZE * 0.5
	var reach: float = half + Tuning.CITY_STREET_LENGTH - 4.0
	var lateral: float = Tuning.CITY_STREET_WIDTH * 0.5 - margin
	var along: float = _rng.randf_range(-half, half) if _rng.randf() < Tuning.DRESS_ARENA_SHARE else _rng.randf_range(-reach, reach)
	var side: float = _rng.randf_range(-lateral, lateral)
	return Vector3(along, 0.0, side) if _rng.randf() < 0.5 else Vector3(side, 0.0, along)


func _free_point(margin: float) -> Vector3:
	for i: int in 12:
		var p: Vector3 = _street_point(margin)
		var ok: bool = true
		for b: Vector2 in _blocked:
			if Vector2(p.x, p.z).distance_to(b) < PROP_CLEARANCE:
				ok = false
				break
		if ok:
			return p
	return _street_point(margin)


func _flat_basis(yaw: float, sx: float, sz: float) -> Basis:
	return Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(sx, 1.0, sz))


## Kümeli nokta: kaldırım dipleri, prop ve kan/ceset çevresi, geri kalanı seyrek sokak.
func _debris_point() -> Vector3:
	var r: float = _rng.randf()
	if r < 0.35:
		var half: float = Tuning.ARENA_SIZE * 0.5
		var reach: float = half + Tuning.CITY_STREET_LENGTH - 4.0
		var edge: float = Tuning.CITY_STREET_WIDTH * 0.5 - _rng.randf_range(0.2, 1.6)
		edge *= 1.0 if _rng.randf() < 0.5 else -1.0
		var along: float = _rng.randf_range(-half, half) if _rng.randf() < Tuning.DRESS_ARENA_SHARE else _rng.randf_range(-reach, reach)
		return Vector3(along, 0.0, edge) if _rng.randf() < 0.5 else Vector3(edge, 0.0, along)
	if r < 0.8 and not _hot.is_empty():
		var c: Vector3 = _hot[_rng.randi() % _hot.size()]
		var ang: float = _rng.randf() * TAU
		var dist: float = absf(_rng.randfn(0.0, 1.5)) + 0.5
		return Vector3(c.x + cos(ang) * dist, 0.0, c.z + sin(ang) * dist)
	return _street_point()


func _build_debris() -> void:
	var size: Vector2 = Tuning.DRESS_DEBRIS_SIZE
	# tür: [en, boy, biçim (0 yaprak, 1 buruşuk, 2 şerit)]
	var kinds: Array = [[0.22, 0.3, 0], [0.4, 0.3, 0], [0.5, 0.4, 0], [0.2, 0.2, 1], [0.3, 0.3, 1], [0.1, 0.5, 2]]
	var xfs: Array[Transform3D] = []
	var colors: Array[Color] = []
	var customs: Array[Color] = []
	for i: int in Tuning.DRESS_DEBRIS_COUNT:
		var p: Vector3 = _debris_point()
		var k: Array = kinds[_rng.randi() % kinds.size()]
		var s: float = clampf(_rng.randf_range(0.6, 1.4) * (size.x + size.y) * 0.5 * _rng.randf_range(0.5, 1.3), size.x, size.y)
		var basis: Basis = _flat_basis(_rng.randf() * TAU, s * k[0] / 0.3, s * k[1] / 0.3)
		p.y = 0.034 + _rng.randf() * 0.004
		var tint: Color
		if k[2] == 1 and _rng.randf() < 0.4:
			tint = Color(0.07, 0.07, 0.08) * _rng.randf_range(0.8, 1.4)
		else:
			tint = PAPER_COLORS[_rng.randi() % PAPER_COLORS.size()] * _rng.randf_range(Tuning.CITY_PAPER_VALUE.x, Tuning.CITY_PAPER_VALUE.y)
		xfs.append(Transform3D(basis, p))
		colors.append(tint)
		customs.append(Color(_rng.randf(), k[2], 0.0, 0.0))
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	quad.orientation = PlaneMesh.FACE_Y
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = PAPER_SHADER
	mat.set_shader_parameter(&"grime", load("res://assets/textures/fx/kenney/dirt_01.png"))
	mat.set_shader_parameter(&"shaped", Tuning.FEATURE_CITY_PAPER_SHAPES)
	_add_group(quad, xfs, colors, 0.95, mat, customs)


func _build_cones(corpse_spots: Array[Vector3]) -> void:
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.03
	cone.bottom_radius = 0.16
	cone.height = 0.7
	cone.radial_segments = 8
	var base: BoxMesh = BoxMesh.new()
	base.size = Vector3(0.4, 0.04, 0.4)
	var mesh: ArrayMesh = _merge([[cone, Transform3D(Basis.IDENTITY, Vector3(0, 0.37, 0)), CONE_COLOR], [base, Transform3D(Basis.IDENTITY, Vector3(0, 0.02, 0)), CONE_COLOR * 0.6]])
	var xfs: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i: int in Tuning.DRESS_CONES:
		var p: Vector3 = _free_point(1.0)
		if Tuning.FEATURE_CITY_CONE_CLEAR:
			p = CityConePlacement.pick_spot(p, corpse_spots, _blocked, Tuning.DRESS_CONE_CORPSE_GAP, PROP_CLEARANCE, Tuning.CITY_STREET_WIDTH * 0.5 - 1.0)
		var yaw: Basis = Basis(Vector3.UP, _rng.randf() * TAU)
		if _rng.randf() < 0.75:
			xfs.append(Transform3D(yaw * Basis(Vector3.FORWARD, PI * 0.5), Vector3(p.x, 0.2, p.z)))
		else:
			xfs.append(Transform3D(yaw, p + Vector3(0, 0.03, 0)))
		colors.append(Color.WHITE * _rng.randf_range(0.7, 1.0))
	_add_group(mesh, xfs, colors, 0.8)


func _build_signs() -> void:
	var pole: BoxMesh = BoxMesh.new()
	pole.size = Vector3(2.4, 0.07, 0.07)
	var plate: BoxMesh = BoxMesh.new()
	plate.size = Vector3(0.05, 0.6, 0.85)
	var mesh: ArrayMesh = _merge([[pole, Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 0)), Color(0.25, 0.25, 0.26)], [plate, Transform3D(Basis.IDENTITY, Vector3(1.25, 0.1, 0)), Color.WHITE]])
	var xfs: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i: int in Tuning.DRESS_SIGNS:
		var p: Vector3 = _free_point(2.0)
		var basis: Basis = Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.BACK, _rng.randf_range(-0.08, 0.08))
		xfs.append(Transform3D(basis * Basis(Vector3.FORWARD, PI * 0.5) * Basis(Vector3.UP, 0.0), Vector3(p.x, 0.05, p.z)))
		colors.append(SIGN_COLORS[i % SIGN_COLORS.size()] * 2.0)
	_add_group(mesh, xfs, colors, 0.7)


## Ölü zombi cesetleri (CityZombieCorpses). Konumları kan lekeleri için döner.
func _build_corpses(spots: Array[Vector3]) -> void:
	var corpses: CityZombieCorpses = CityZombieCorpses.new() if Tuning.FEATURE_CITY_ZOMBIE_CORPSES else null
	if corpses != null:
		add_child(corpses)
		_corpses = corpses
	for i: int in Tuning.DRESS_CORPSES:
		var p: Vector3 = _free_point(1.5)
		var yaw: float = _rng.randf() * TAU
		_rng.randi()   # Eski ceset renk seçimi: sonraki dekor yerleşimi bozulmasın.
		if corpses != null:
			corpses.add_corpse(p, yaw)
		_hot.append(p)
		spots.append(p)


## [mesh, Transform3D, Color] parçalarını köşe renkli tek mesh'te birleştirir.
func _merge(parts: Array) -> ArrayMesh:
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var cols: PackedColorArray = PackedColorArray()
	var idx: PackedInt32Array = PackedInt32Array()
	for part: Array in parts:
		var src: Array = (part[0] as Mesh).get_mesh_arrays()
		var xf: Transform3D = part[1]
		var offset: int = verts.size()
		var sv: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
		var sn: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
		for i: int in sv.size():
			verts.append(xf * sv[i])
			normals.append((xf.basis * sn[i]).normalized())
			cols.append(part[2])
		for i: int in (src[Mesh.ARRAY_INDEX] as PackedInt32Array):
			idx.append(i + offset)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_group(mesh: Mesh, xfs: Array[Transform3D], colors: Array[Color], roughness: float, material: Material = null, customs: Array[Color] = []) -> void:
	if xfs.is_empty():
		return
	if material == null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = roughness
		material = mat
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = not customs.is_empty()
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, colors[i])
		if not customs.is_empty():
			mm.set_instance_custom_data(i, customs[i])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	_groups.append({"node": node, "total": xfs.size()})


func _apply_quality(_profile_id: StringName) -> void:
	if _corpses != null:
		_corpses.apply_quality(Quality.shadows_enabled())
	var factor: float = Quality.get_value("ground_dressing")
	for g: Dictionary in _groups:
		(g["node"] as MultiMeshInstance3D).multimesh.visible_instance_count = int(ceilf(float(g["total"]) * factor))
