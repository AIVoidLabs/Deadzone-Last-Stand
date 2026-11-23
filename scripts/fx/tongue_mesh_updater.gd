class_name TongueMeshUpdater
extends RefCounted
## Dil ağının güncellenmesi: hızlı yol (TongueMeshBuilder, FEATURE_TONGUE_MESH_FAST) ve eski yol
## (her karede tüm ağı yeniden kurar). TongueRope her karede update() çağırır.
## Görsel sabitler; oynanış ayarı değil.

const SAMPLES: int = 44
const RADIAL: int = 10
const CAP_RINGS: int = 4
const RADIUS_BASE: float = 0.06
const RADIUS_TIP: float = 0.018
const BULB_AT: float = 0.9
const BULB_SIZE: float = 0.014
const BULB_WIDTH: float = 0.05
const SHORT_FULL_RADIUS_LENGTH: float = 0.5

var _owner: MeshInstance3D
var _mesh: ArrayMesh
var _mat: ShaderMaterial
var _rope_points: int
## Hızlı ağ yolu; yalnız ölçüm bayrakları: ara adımları ayrı ölçmek için.
var _builder: TongueMeshBuilder = null
var _bench_rebuild: bool = Benchmark.flag("--bench-tongue-rebuild")
var _bench_every1: bool = Benchmark.flag("--bench-tongue-every1")
var _bench_no_cull: bool = Benchmark.flag("--bench-tongue-no-cull")


func _init(owner: MeshInstance3D, mesh: ArrayMesh, mat: ShaderMaterial, rope_points: int) -> void:
	_owner = owner
	_mesh = mesh
	_mat = mat
	_rope_points = rope_points


## pts: halat noktaları, length: dinlenme uzunluğu, dangling: dil sarkma durumunda mı.
func update(pts: PackedVector3Array, length: float, dangling: bool) -> void:
	if Tuning.FEATURE_TONGUE_MESH_FAST:
		_build_fast(pts, length, dangling)
	else:
		_build_legacy(pts, length)


static func radius_at(t: float, length: float) -> float:
	var r: float = lerpf(RADIUS_BASE, RADIUS_TIP, pow(t, 0.9))
	r += BULB_SIZE * exp(-pow((t - BULB_AT) / BULB_WIDTH, 2.0))
	return r * clampf(length / SHORT_FULL_RADIUS_LENGTH, 0.35, 1.0)


## Catmull-Rom ile halat noktalarından düzgün eğri.
static func _curve(pts: PackedVector3Array, f: float) -> Vector3:
	var n: int = pts.size()
	var x: float = f * float(n - 1)
	var i: int = mini(int(x), n - 2)
	var s: float = x - float(i)
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[i + 1]
	var p3: Vector3 = pts[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * p1) + (p2 - p0) * s + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s * s + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s * s * s)


## Hızlı yol: sarkarken seyrek, ekran dışında hiç kurmaz; yüzey bir kez yaratılır.
func _build_fast(pts: PackedVector3Array, length: float, dangling: bool) -> void:
	var every: int = 1 if _bench_every1 else Tuning.TONGUE_MESH_DANGLE_EVERY
	if dangling and every > 1 and _mesh.get_surface_count() > 0:
		if (Engine.get_process_frames() + _owner.get_instance_id()) % every != 0:
			return
	if not _bench_no_cull and _mesh.get_surface_count() > 0 and not _maybe_on_screen(pts):
		return
	if _builder == null:
		_builder = _make_builder()
	if _bench_rebuild:
		_builder.rebuild_surface(_mesh, pts, length)
	elif _mesh.get_surface_count() == 0:
		_builder.create_surface(_mesh, pts, length)
	else:
		_builder.update_surface(_mesh, pts, length)
	_mat.set_shader_parameter(&"arc_scale", maxf(length, 0.01))
	var e: float = length * 1.25 + 1.0
	_owner.custom_aabb = AABB(pts[0] - Vector3.ONE * e, Vector3.ONE * (2.0 * e))


func _make_builder() -> TongueMeshBuilder:
	var n: int = Tuning.TONGUE_MESH_SAMPLES
	var radii: PackedFloat32Array = PackedFloat32Array()
	for i: int in n:
		radii.append(radius_at(float(i) / float(n - 1), 1.0))
	var b: TongueMeshBuilder = TongueMeshBuilder.new()
	b.setup(n, Tuning.TONGUE_MESH_RADIAL, Tuning.TONGUE_MESH_CAP_RINGS, radii, _rope_points)
	return b


## Dilin başı, ortası ya da ucu kameranın görüş hacminde mi (yoksa ağı kurmaya gerek yok).
func _maybe_on_screen(pts: PackedVector3Array) -> bool:
	var cam: Camera3D = _owner.get_viewport().get_camera_3d()
	if cam == null:
		return true
	return cam.is_position_in_frustum(pts[0]) or cam.is_position_in_frustum(pts[pts.size() >> 1]) or cam.is_position_in_frustum(pts[pts.size() - 1])


func _build_legacy(pts: PackedVector3Array, length: float) -> void:
	var rings: int = SAMPLES + CAP_RINGS
	var centers: PackedVector3Array = PackedVector3Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	for i: int in SAMPLES:
		var t: float = float(i) / float(SAMPLES - 1)
		centers.append(_curve(pts, t))
		radii.append(radius_at(t, length))
	var tip_tan: Vector3 = (centers[SAMPLES - 1] - centers[SAMPLES - 2]).normalized()
	var r_tip: float = radii[SAMPLES - 1]
	for k: int in range(1, CAP_RINGS + 1):
		var a: float = float(k) / float(CAP_RINGS) * PI * 0.5
		centers.append(centers[SAMPLES - 1] + tip_tan * (sin(a) * r_tip))
		radii.append(maxf(cos(a) * r_tip, 0.0005))
	var verts: PackedVector3Array = PackedVector3Array()
	var norms: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	# UV2.x: kökten metre (shader dokusu dilin boyuyla gerilmesin).
	var uv2s: PackedVector2Array = PackedVector2Array()
	var arc: float = 0.0
	var idx: PackedInt32Array = PackedInt32Array()
	var normal_ref: Vector3 = Vector3.UP
	var tan0: Vector3 = (centers[1] - centers[0]).normalized()
	if absf(tan0.dot(normal_ref)) > 0.95:
		normal_ref = Vector3.RIGHT
	var nrm: Vector3 = (normal_ref - tan0 * tan0.dot(normal_ref)).normalized()
	var prev_tan: Vector3 = tan0
	for i: int in rings:
		var tangent: Vector3 = tan0
		if i > 0 and i < rings - 1:
			tangent = (centers[i + 1] - centers[i - 1]).normalized()
		elif i == rings - 1:
			tangent = (centers[i] - centers[i - 1]).normalized()
		# Paralel taşıma: önceki tanjant -> yeni tanjant dönüşü.
		var axis: Vector3 = prev_tan.cross(tangent)
		if axis.length() > 0.00001:
			nrm = nrm.rotated(axis.normalized(), prev_tan.angle_to(tangent))
		nrm = (nrm - tangent * tangent.dot(nrm)).normalized()
		prev_tan = tangent
		if i > 0:
			arc += centers[i].distance_to(centers[i - 1])
		var bin: Vector3 = tangent.cross(nrm)
		var v: float = minf(float(i) / float(SAMPLES - 1), 1.0)
		var cap: float = 0.0
		if i >= SAMPLES:
			cap = float(i - SAMPLES + 1) / float(CAP_RINGS) * PI * 0.5
		for j: int in RADIAL + 1:
			var ang: float = float(j) / float(RADIAL) * TAU
			var radial: Vector3 = nrm * cos(ang) + bin * sin(ang)
			verts.append(centers[i] + radial * radii[i])
			norms.append((radial * cos(cap) + tangent * sin(cap)).normalized())
			uvs.append(Vector2(float(j) / float(RADIAL), v))
			uv2s.append(Vector2(arc, 0.0))
	for i: int in rings - 1:
		for j: int in RADIAL:
			var a0: int = i * (RADIAL + 1) + j
			var b0: int = a0 + RADIAL + 1
			idx.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = idx
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
