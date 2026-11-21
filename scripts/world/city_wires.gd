class_name CityWires
extends Node3D
## 8.3d: ön plan elektrik telleri. Blok cepheleri arasında sarkık koyu kablolar (kavşağı çapraz keser), gölgesiz.
## Kapatma: Tuning.FEATURE_CITY_WIRES.

const SEGMENTS: int = 16
## Blok indeksleri: 0 = -x-z, 1 = +x-z, 2 = -x+z, 3 = +x+z (CITY_INNER_BLOCK_HEIGHTS sırası).


func _ready() -> void:
	name = "CityWires"
	var w: float = Tuning.CITY_STREET_WIDTH * 0.5 + 0.3
	var h: Array[float] = Tuning.CITY_INNER_BLOCK_HEIGHTS
	var wires: Array = [
		[Vector3(-w, h[0] - 0.5, -w - 2.0), Vector3(w, h[3] - 0.5, w + 2.0)],
		[Vector3(w, h[1] - 0.6, -w - 2.0), Vector3(-w, h[2] - 0.5, w + 2.0)],
		[Vector3(-w, h[0] - 1.4, -w - 5.0), Vector3(w, h[1] - 1.4, -w - 5.0)],
		[Vector3(-w, h[2] - 1.2, w + 5.0), Vector3(w, h[3] - 1.2, w + 5.0)],
		[Vector3(-w - 5.0, h[0] - 1.0, -w), Vector3(-w - 5.0, h[2] - 1.0, w)],
		[Vector3(w + 5.0, h[1] - 1.0, -w), Vector3(w + 5.0, h[3] - 1.0, w)],
	]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = Tuning.DRESS_SEED
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Tuning.WIRE_COLOR
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for pair: Array in wires:
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = _tube(pair[0], pair[1], rng.randf_range(Tuning.WIRE_SAG.x, Tuning.WIRE_SAG.y))
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


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
