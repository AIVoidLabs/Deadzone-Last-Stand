class_name CityWires
extends Node3D
## 8.3d: ön plan elektrik telleri. Kaldırımdaki direkten karşı cepheye paralel sarkık kablo demetleri (2 demet), gölgesiz.
## Kapatma: Tuning.FEATURE_CITY_WIRES.

const SEGMENTS: int = 16
## Blok indeksleri: 0 = -x-z, 1 = +x-z, 2 = -x+z, 3 = +x+z (CITY_INNER_BLOCK_HEIGHTS sırası).


func _ready() -> void:
	name = "CityWires"
	var w: float = Tuning.CITY_STREET_WIDTH * 0.5 + 0.3
	var h: Array[float] = Tuning.CITY_INNER_BLOCK_HEIGHTS
	var top: float = Tuning.POLE_HEIGHT - 0.4
	# direk, başı ve karşı cephedeki bağlantı noktası; kablolar paralel, tek yönde, hafif çapraz
	var groups: Array = [
		[Vector3(w - 1.7, 0.0, 6.0), Vector3(-w, h[2] - 2.0, w + 3.0)],
		[Vector3(-w + 1.7, 0.0, -6.0), Vector3(w, h[1] - 5.5, -w - 3.0)],
	]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = Tuning.DRESS_SEED
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Tuning.WIRE_COLOR
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for g: Array in groups:
		var base: Vector3 = g[0]
		_add_pole(base)
		var start: Vector3 = Vector3(base.x, top, base.z)
		var end: Vector3 = g[1]
		var sag: float = rng.randf_range(Tuning.WIRE_SAG.x, Tuning.WIRE_SAG.y)
		var side: Vector3 = (end - start).cross(Vector3.UP).normalized()
		for i: int in Tuning.WIRE_COUNT:
			var off: Vector3 = side * ((i - (Tuning.WIRE_COUNT - 1) * 0.5) * Tuning.WIRE_SPACING) + Vector3(0.0, rng.randf_range(-0.15, 0.15), 0.0)
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = _tube(start + off, end + off, sag * rng.randf_range(0.9, 1.1))
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)


## Basit low-poly elektrik direği: gövde + iki çapraz kol.
func _add_pole(base: Vector3) -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.075, 0.055)
	mat.roughness = 0.9
	var parts: Array = [
		[Vector3(0.28, Tuning.POLE_HEIGHT, 0.28), Vector3(0.0, Tuning.POLE_HEIGHT * 0.5, 0.0)],
		[Vector3(0.18, 0.18, 3.2), Vector3(0.0, Tuning.POLE_HEIGHT - 0.4, 0.0)],
		[Vector3(0.18, 0.18, 2.4), Vector3(0.0, Tuning.POLE_HEIGHT - 1.4, 0.0)],
	]
	for p: Array in parts:
		var box: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = p[0]
		box.mesh = mesh
		box.material_override = mat
		box.position = base + (p[1] as Vector3)
		add_child(box)


## Sarkık eğri boyunca kare kesitli ince boru.
func _tube(a: Vector3, b: Vector3, sag: float) -> ArrayMesh:
	var r: float = Tuning.WIRE_RADIUS
	var verts: PackedVector3Array = PackedVector3Array()
	var idx: PackedInt32Array = PackedInt32Array()
	var dir: Vector3 = (b - a).normalized()
	var side: Vector3 = dir.cross(Vector3.UP).normalized()
	var up: Vector3 = side.cross(dir).normalized()
	for i: int in SEGMENTS + 1:
		var t: float = float(i) / SEGMENTS
		var c: Vector3 = a.lerp(b, t) - Vector3(0.0, sag * 4.0 * t * (1.0 - t), 0.0)
		verts.append(c + (side + up) * r)
		verts.append(c + (-side + up) * r)
		verts.append(c + (-side - up) * r)
		verts.append(c + (side - up) * r)
	for i: int in SEGMENTS:
		for k: int in 4:
			var v0: int = i * 4 + k
			var v1: int = i * 4 + (k + 1) % 4
			idx.append_array([v0, v1, v0 + 4, v1, v1 + 4, v0 + 4])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
