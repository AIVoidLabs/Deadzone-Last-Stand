class_name CityGroundDressing
extends Node3D
## 8.3d: yer dekoru. Kâğıt/karton/enkaz, kan gölleri ve izleri, devrik koni, düşmüş tabela, cesetler.
## Hepsi MultiMesh, çarpışmasız; adet profildeki ground_dressing çarpanıyla. Kapatma: Tuning.FEATURE_CITY_GROUND_DRESSING.

const BLOOD_Y: float = 0.04
const TRAIL_BLOBS: int = 6
const PROP_CLEARANCE: float = 2.8
const PAPER_COLORS: Array[Color] = [Color(0.5, 0.45, 0.36), Color(0.38, 0.32, 0.25), Color(0.3, 0.3, 0.29), Color(0.42, 0.28, 0.17)]
const CLOTH_COLORS: Array[Color] = [Color(0.2, 0.22, 0.28), Color(0.3, 0.17, 0.14), Color(0.22, 0.26, 0.2), Color(0.3, 0.28, 0.24)]
const SIGN_COLORS: Array[Color] = [Color(0.12, 0.3, 0.22), Color(0.5, 0.09, 0.07), Color(0.18, 0.22, 0.32)]
const CONE_COLOR: Color = Color(0.85, 0.32, 0.05)
const SKIN_COLOR: Color = Color(0.55, 0.45, 0.38)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _groups: Array[Dictionary] = []   # {node: MultiMeshInstance3D, total: int}
var _blocked: Array[Vector2] = []


func _ready() -> void:
	name = "CityGroundDressing"
	_rng.seed = Tuning.DRESS_SEED
	for row: Dictionary in CityProps.rows():
		if row["collide"]:
			_blocked.append(row["pos"])
	var pools: Array[Transform3D] = []
	_build_corpses(pools)
	_build_blood(pools)
	_build_debris()
	_build_cones()
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


func _build_debris() -> void:
	var size: Vector2 = Tuning.DRESS_DEBRIS_SIZE
	var paper: Array[Transform3D] = []
	var card: Array[Transform3D] = []
	var paper_colors: Array[Color] = []
	var card_colors: Array[Color] = []
	for i: int in Tuning.DRESS_DEBRIS_COUNT:
		var p: Vector3 = _street_point()
		var is_card: bool = _rng.randf() < 0.3
		p.y = 0.03 + _rng.randf() * 0.015
		var xf: Transform3D = Transform3D(_flat_basis(_rng.randf() * TAU, _rng.randf_range(size.x, size.y), _rng.randf_range(size.x, size.y)), p)
		var tint: Color = PAPER_COLORS[_rng.randi() % PAPER_COLORS.size()] * _rng.randf_range(0.35, 0.75)
		if is_card:
			card.append(xf)
			card_colors.append(tint)
		else:
			paper.append(xf)
			paper_colors.append(tint)
	var flat: BoxMesh = BoxMesh.new()
	flat.size = Vector3(1.0, 0.012, 1.0)
	var thick: BoxMesh = BoxMesh.new()
	thick.size = Vector3(1.0, 0.05, 1.0)
	_add_group(flat, paper, paper_colors, 0.95)
	_add_group(thick, card, card_colors, 0.95)


func _build_blood(pools: Array[Transform3D]) -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	var xfs: Array[Transform3D] = pools.duplicate()
	for i: int in Tuning.DRESS_BLOOD_POOLS:
		xfs.append(_blob(_free_point(0.5), _rng.randf_range(0.9, 2.6)))
	for i: int in Tuning.DRESS_BLOOD_TRAILS:
		var p: Vector3 = _free_point(1.5)
		var dir: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, _rng.randf() * TAU)
		var s: float = _rng.randf_range(0.6, 1.0)
		for k: int in TRAIL_BLOBS:
			xfs.append(_blob(p + dir * (k * 0.9) + Vector3(_rng.randf_range(-0.15, 0.15), 0.0, _rng.randf_range(-0.15, 0.15)), s * (1.0 - k * 0.12)))
	var colors: Array[Color] = []
	for x: Transform3D in xfs:
		colors.append(Color.WHITE * _rng.randf_range(0.7, 1.1))
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 0.8, 1.0])
	grad.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	mat.albedo_texture = tex
	mat.albedo_color = Tuning.DRESS_BLOOD_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.12
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_group(quad, xfs, colors, 0.0, mat)


func _blob(p: Vector3, diameter: float) -> Transform3D:
	var basis: Basis = Basis(Vector3.UP, _rng.randf() * TAU) * Basis.from_scale(Vector3(diameter * _rng.randf_range(0.8, 1.4), diameter, 1.0)) * Basis(Vector3.RIGHT, -PI * 0.5)
	return Transform3D(basis, Vector3(p.x, BLOOD_Y, p.z))


func _build_cones() -> void:
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


## Yatan ceset: gövde + bacaklar + kollar (kıyafet) ve baş (ten); iki poz. Altına kan gölü eklenir.
func _build_corpses(pools: Array[Transform3D]) -> void:
	var xfs: Array[Array] = [[], []]
	var colors: Array[Array] = [[], []]
	for i: int in Tuning.DRESS_CORPSES:
		var p: Vector3 = _free_point(1.5)
		var pose: int = i % 2
		xfs[pose].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), Vector3(p.x, 0.0, p.z)))
		colors[pose].append(CLOTH_COLORS[_rng.randi() % CLOTH_COLORS.size()] * 3.0)
		pools.append(_blob(p + Vector3(_rng.randf_range(-0.3, 0.3), 0.0, _rng.randf_range(-0.3, 0.3)), _rng.randf_range(1.3, 2.0)))
	for pose: int in 2:
		var typed_x: Array[Transform3D] = []
		var typed_c: Array[Color] = []
		typed_x.assign(xfs[pose])
		typed_c.assign(colors[pose])
		_add_group(_corpse_mesh(pose), typed_x, typed_c, 0.9)


func _corpse_mesh(pose: int) -> ArrayMesh:
	var cloth: Color = Color(0.5, 0.5, 0.5)
	var pants: Color = Color(0.25, 0.23, 0.22)
	var parts: Array = []
	var head: SphereMesh = SphereMesh.new()
	head.radius = 0.13
	head.height = 0.26
	parts.append([head, Transform3D(Basis.IDENTITY, Vector3(0, 0.13, -0.95)), SKIN_COLOR])
	parts.append([_box(0.46, 0.2, 0.62), Transform3D(Basis.IDENTITY, Vector3(0, 0.1, -0.5)), cloth])
	for s: float in [-1.0, 1.0]:
		var leg_yaw: float = (s * 0.12) if pose == 0 else (s * 0.4)
		parts.append([_box(0.16, 0.15, 0.85), Transform3D(Basis(Vector3.UP, leg_yaw), Vector3(s * 0.11 + s * leg_yaw * 0.4, 0.075, 0.38)), pants])
		var arm_yaw: float = (s * 0.05) if pose == 0 else (s * 0.9)
		parts.append([_box(0.12, 0.12, 0.6), Transform3D(Basis(Vector3.UP, arm_yaw), Vector3(s * (0.34 + absf(arm_yaw) * 0.15), 0.06, -0.55 + absf(arm_yaw) * 0.1)), cloth])
	return _merge(parts)


func _box(x: float, y: float, z: float) -> BoxMesh:
	var m: BoxMesh = BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m


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


func _add_group(mesh: Mesh, xfs: Array[Transform3D], colors: Array[Color], roughness: float, material: Material = null) -> void:
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
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, colors[i])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	_groups.append({"node": node, "total": xfs.size()})


func _apply_quality(_profile_id: StringName) -> void:
	var factor: float = Quality.get_value("ground_dressing")
	for g: Dictionary in _groups:
		(g["node"] as MultiMeshInstance3D).multimesh.visible_instance_count = int(ceilf(float(g["total"]) * factor))
