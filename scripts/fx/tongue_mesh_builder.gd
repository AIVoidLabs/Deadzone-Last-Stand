class_name TongueMeshBuilder
extends RefCounted
## Dil tüpü için hızlı ağ kurucu (FEATURE_TONGUE_MESH_FAST): indeks, UV ve halka sabitleri bir kez üretilir,
## köşe ve normal tamponları yerinde yazılıp GPU'ya bölge güncellemesiyle gider (yüzey yeniden yaratılmaz).
## Tamponlar: köşe verisi = [tüm konumlar (12 B)] + [köşe başına normal (4 B oktahedral) + teğet (4 B)].
## Saf sınıf: sahne ve autoload bilmez.

const POS_STRIDE: int = 12

var samples: int = 0
var radial: int = 0
var cap_rings: int = 0
var rings: int = 0
var vertex_count: int = 0

var _base_radii: PackedFloat32Array = PackedFloat32Array()
var _cos: PackedFloat32Array = PackedFloat32Array()
var _sin: PackedFloat32Array = PackedFloat32Array()
var _cap_cos: PackedFloat32Array = PackedFloat32Array()
var _cap_sin: PackedFloat32Array = PackedFloat32Array()
## Catmull-Rom: örnek başına dört nokta indeksi ve ağırlığı.
var _ci: PackedInt32Array = PackedInt32Array()
var _cw: PackedFloat32Array = PackedFloat32Array()
var _centers: PackedVector3Array = PackedVector3Array()
var _positions: PackedVector3Array = PackedVector3Array()
var _normal_words: PackedInt32Array = PackedInt32Array()
var _indices: PackedInt32Array = PackedInt32Array()
var _uvs: PackedVector2Array = PackedVector2Array()
var _uv2s: PackedVector2Array = PackedVector2Array()
var _norms_array: PackedVector3Array = PackedVector3Array()
var _rope_count: int = 0
## Yalnız yüzey kurulurken Vector3 normal dizisi de doldurulur; güncellemede gerekmez.
var _want_vectors: bool = false


## base_radii: örnek başına (samples) tam uzunluktaki yarıçap; rope_count: halat nokta sayısı.
func setup(p_samples: int, p_radial: int, p_cap_rings: int, base_radii: PackedFloat32Array, rope_count: int) -> void:
	samples = p_samples
	radial = p_radial
	cap_rings = p_cap_rings
	rings = samples + cap_rings
	vertex_count = rings * (radial + 1)
	_base_radii = base_radii
	_rope_count = rope_count
	_build_tables()
	_build_curve_weights()
	_build_indices_and_uvs()
	_centers.resize(rings)
	_positions.resize(vertex_count)
	_norms_array.resize(vertex_count)
	_normal_words.resize(vertex_count * 2)


## Yarıçap ve halka sayısına bağlı halka-içi sabitler (cos/sin tabloları, uç kapağı açıları).
func _build_tables() -> void:
	_cos.resize(radial + 1)
	_sin.resize(radial + 1)
	for j: int in radial + 1:
		var ang: float = float(j) / float(radial) * TAU
		_cos[j] = cos(ang)
		_sin[j] = sin(ang)
	_cap_cos.resize(cap_rings)
	_cap_sin.resize(cap_rings)
	for k: int in cap_rings:
		var a: float = float(k + 1) / float(cap_rings) * PI * 0.5
		_cap_cos[k] = cos(a)
		_cap_sin[k] = sin(a)


func _build_curve_weights() -> void:
	_ci.resize(samples * 4)
	_cw.resize(samples * 4)
	for k: int in samples:
		var x: float = float(k) / float(samples - 1) * float(_rope_count - 1)
		var i: int = mini(int(x), _rope_count - 2)
		var s: float = x - float(i)
		var s2: float = s * s
		var s3: float = s2 * s
		_ci[k * 4] = maxi(i - 1, 0)
		_ci[k * 4 + 1] = i
		_ci[k * 4 + 2] = i + 1
		_ci[k * 4 + 3] = mini(i + 2, _rope_count - 1)
		_cw[k * 4] = 0.5 * (-s + 2.0 * s2 - s3)
		_cw[k * 4 + 1] = 0.5 * (2.0 - 5.0 * s2 + 3.0 * s3)
		_cw[k * 4 + 2] = 0.5 * (s + 4.0 * s2 - 3.0 * s3)
		_cw[k * 4 + 3] = 0.5 * (-s2 + s3)


func _build_indices_and_uvs() -> void:
	_indices.clear()
	for i: int in rings - 1:
		for j: int in radial:
			var a0: int = i * (radial + 1) + j
			var b0: int = a0 + radial + 1
			_indices.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])
	_uvs.resize(vertex_count)
	_uv2s.resize(vertex_count)
	for i: int in rings:
		var v: float = minf(float(i) / float(samples - 1), 1.0)
		for j: int in radial + 1:
			_uvs[i * (radial + 1) + j] = Vector2(float(j) / float(radial), v)
			_uv2s[i * (radial + 1) + j] = Vector2.ZERO


## Yüzeyi bir kez oluşturur (dinamik güncellemeli). Köşe verisi önce bir kez yazılır.
func create_surface(mesh: ArrayMesh, pts: PackedVector3Array, length: float) -> void:
	_want_vectors = true
	fill_buffers(pts, length)
	_want_vectors = false
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays(), [], {}, Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE)
	_capture_tangent_words(mesh)


## Yalnız köşe ve normal tamponlarını günceller.
func update_surface(mesh: ArrayMesh, pts: PackedVector3Array, length: float) -> void:
	fill_buffers(pts, length)
	mesh.surface_update_vertex_region(0, 0, _positions.to_byte_array())
	mesh.surface_update_vertex_region(0, vertex_count * POS_STRIDE, _normal_words.to_byte_array())


## Eski yolla karşılaştırma için: yüzeyi her seferinde baştan ekler (yalnız ölçüm).
func rebuild_surface(mesh: ArrayMesh, pts: PackedVector3Array, length: float) -> void:
	_want_vectors = true
	fill_buffers(pts, length)
	_want_vectors = false
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays())


func _arrays() -> Array:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _positions
	arrays[Mesh.ARRAY_NORMAL] = _norms_array
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_TEX_UV2] = _uv2s
	arrays[Mesh.ARRAY_INDEX] = _indices
	return arrays


## Motorun kendi ürettiği teğet sözcüklerini saklar (normalin yanında iç içe durur, gölgelendirici kullanmaz).
func _capture_tangent_words(mesh: ArrayMesh) -> void:
	var surf: Dictionary = RenderingServer.mesh_get_surface(mesh.get_rid(), 0)
	var data: PackedByteArray = surf.get("vertex_data", PackedByteArray())
	var offset: int = vertex_count * POS_STRIDE
	if data.size() != offset + vertex_count * 8:
		return
	var words: PackedInt32Array = data.slice(offset).to_int32_array()
	for v: int in vertex_count:
		_normal_words[v * 2 + 1] = words[v * 2 + 1]


## Konum ve normal dizilerini yerinde doldurur.
func fill_buffers(pts: PackedVector3Array, length: float) -> void:
	_fill_centers(pts)
	var len_scale: float = clampf(length / 0.5, 0.35, 1.0)
	var tip_tan: Vector3 = (_centers[samples - 1] - _centers[samples - 2]).normalized()
	var r_tip: float = _base_radii[samples - 1] * len_scale
	for k: int in cap_rings:
		_centers[samples + k] = _centers[samples - 1] + tip_tan * (_cap_sin[k] * r_tip)
	var tan0: Vector3 = (_centers[1] - _centers[0]).normalized()
	var ref: Vector3 = Vector3.UP
	if absf(tan0.dot(ref)) > 0.95:
		ref = Vector3.RIGHT
	var nrm: Vector3 = (ref - tan0 * tan0.dot(ref)).normalized()
	for i: int in rings:
		var tan: Vector3 = tan0
		if i > 0 and i < rings - 1:
			tan = (_centers[i + 1] - _centers[i - 1]).normalized()
		elif i == rings - 1:
			tan = (_centers[i] - _centers[i - 1]).normalized()
		# Yansıtmalı taşıma: önceki çerçeveyi yeni teğete diker (küçük açılarda paralel taşımaya eşdeğer).
		nrm = (nrm - tan * tan.dot(nrm)).normalized()
		var bin: Vector3 = tan.cross(nrm)
		var rad: float
		var cc: float = 1.0
		var ss: float = 0.0
		if i < samples:
			rad = _base_radii[i] * len_scale
		else:
			cc = _cap_cos[i - samples]
			ss = _cap_sin[i - samples]
			rad = maxf(cc * r_tip, 0.0005)
		_write_ring(i, _centers[i], nrm, bin, tan, rad, cc, ss)


func _fill_centers(pts: PackedVector3Array) -> void:
	for k: int in samples:
		var b: int = k * 4
		_centers[k] = pts[_ci[b]] * _cw[b] + pts[_ci[b + 1]] * _cw[b + 1] + pts[_ci[b + 2]] * _cw[b + 2] + pts[_ci[b + 3]] * _cw[b + 3]


func _write_ring(i: int, c: Vector3, nrm: Vector3, bin: Vector3, tan: Vector3, rad: float, cc: float, ss: float) -> void:
	var base: int = i * (radial + 1)
	var tan_ss: Vector3 = tan * ss
	for j: int in radial + 1:
		var dir: Vector3 = nrm * _cos[j] + bin * _sin[j]
		var v: int = base + j
		_positions[v] = c + dir * rad
		var n: Vector3 = dir * cc + tan_ss
		if _want_vectors:
			_norms_array[v] = n
		_normal_words[v * 2] = pack_normal(n)


## Birim normali motorun 4 baytlık oktahedral biçimine (iki uint16, alt sözcük x) sıkıştırır.
static func pack_normal(n: Vector3) -> int:
	var d: float = absf(n.x) + absf(n.y) + absf(n.z)
	var x: float = n.x / d
	var y: float = n.y / d
	if n.z < 0.0:
		var ox: float = (1.0 - absf(y)) * (1.0 if x >= 0.0 else -1.0)
		y = (1.0 - absf(x)) * (1.0 if y >= 0.0 else -1.0)
		x = ox
	var u: int = clampi(int((x * 0.5 + 0.5) * 65535.0), 0, 65535)
	var w: int = clampi(int((y * 0.5 + 0.5) * 65535.0), 0, 65535)
	return u | (w << 16)
