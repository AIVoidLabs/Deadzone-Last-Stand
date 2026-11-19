extends GutTest
## TongueMeshBuilder: sabit sayılar, köşe sayısı ve normal paketleme.


func _builder() -> TongueMeshBuilder:
	var n: int = Tuning.TONGUE_MESH_SAMPLES
	var radii: PackedFloat32Array = PackedFloat32Array()
	radii.resize(n)
	radii.fill(0.05)
	var b: TongueMeshBuilder = TongueMeshBuilder.new()
	b.setup(n, Tuning.TONGUE_MESH_RADIAL, Tuning.TONGUE_MESH_CAP_RINGS, radii, 20)
	return b


func _line(count: int) -> PackedVector3Array:
	var pts: PackedVector3Array = PackedVector3Array()
	for i: int in count:
		pts.append(Vector3(float(i) * 0.1, 0.0, 0.0))
	return pts


func test_vertex_count_matches_rings() -> void:
	var b: TongueMeshBuilder = _builder()
	var rings: int = Tuning.TONGUE_MESH_SAMPLES + Tuning.TONGUE_MESH_CAP_RINGS
	assert_eq(b.vertex_count, rings * (Tuning.TONGUE_MESH_RADIAL + 1))


func test_vertices_lie_on_tube_radius() -> void:
	var b: TongueMeshBuilder = _builder()
	b.fill_buffers(_line(20), 1.0)
	var v: Vector3 = b._positions[3 * (Tuning.TONGUE_MESH_RADIAL + 1)]
	var axis_dist: float = Vector2(v.y, v.z).length()
	assert_almost_eq(axis_dist, 0.05, 0.001)


func test_pack_normal_axes() -> void:
	# +Z merkez (0.5, 0.5), +X (1.0, 0.5) oktahedral kodda.
	assert_eq(TongueMeshBuilder.pack_normal(Vector3(0, 0, 1)) & 0xFFFF, 32767)
	assert_eq(TongueMeshBuilder.pack_normal(Vector3(1, 0, 0)) & 0xFFFF, 65535)
	assert_eq((TongueMeshBuilder.pack_normal(Vector3(1, 0, 0)) >> 16) & 0xFFFF, 32767)


func test_indices_are_in_range() -> void:
	var b: TongueMeshBuilder = _builder()
	for i: int in b._indices:
		assert_true(i >= 0 and i < b.vertex_count)
