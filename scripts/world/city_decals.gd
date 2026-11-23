class_name CityDecals
extends Node3D
## 8.3h: yere yatık lekeler. Kan (gölcük, sıçrama, sürüklenme izi, ayak izi damlaları; Kenney dirt maskesi, koyu bordo, parlamasız)
## ve zemin dokusu (yanık, yağ, lastik izi, çatlak). Hepsi MultiMesh quad, çarpışmasız; adet profildeki ground_dressing çarpanıyla.
## Kapatma: Tuning.FEATURE_CITY_BLOOD_DECALS / FEATURE_CITY_GROUND_DECALS.

const SHADER: Shader = preload("res://assets/shaders/city_decal.gdshader")
const MASK_PATH: String = "res://assets/textures/fx/kenney/%s.png"
const Y_GROUND: float = 0.022
const Y_BLOOD: float = 0.04
## Kaldırım üstü (kaldırım yüksekliği 0.08) ve sokağın kaldırıma başladığı uzaklık (yarım sokak - kaldırım).
const Y_RAISED: float = 0.1
const BLOOD_CORE: Color = Color(0.2, 0.014, 0.02)
const BLOOD_EDGE: Color = Color(0.055, 0.018, 0.014)
const BLACK: Color = Color(0.012, 0.012, 0.013)

## Tür tablosu: maske, kip (shader), çekirdek/kenar rengi, pürüz, yansıma, sıçrama payı.
const KINDS: Dictionary = {
	&"puddle": {"mask": "dirt_02", "mode": 1, "core": BLOOD_CORE, "edge": BLOOD_EDGE, "rough": 0.32, "spec": 0.5, "splash": 0.8},
	&"drop": {"mask": "dirt_01", "mode": 1, "core": BLOOD_CORE, "edge": BLOOD_EDGE, "rough": 0.32, "spec": 0.5, "splash": 0.0},
	&"splash_a": {"mask": "dirt_01", "mode": 0, "core": BLOOD_CORE, "edge": BLOOD_EDGE, "rough": 0.34, "spec": 0.5, "splash": 1.0},
	&"splash_b": {"mask": "dirt_02", "mode": 0, "core": BLOOD_CORE, "edge": BLOOD_EDGE, "rough": 0.34, "spec": 0.5, "splash": 1.0},
	&"splash_c": {"mask": "dirt_03", "mode": 0, "core": BLOOD_CORE, "edge": BLOOD_EDGE, "rough": 0.34, "spec": 0.5, "splash": 1.0},
	&"trail": {"mask": "dirt_03", "mode": 2, "core": BLOOD_CORE, "edge": BLOOD_EDGE, "rough": 0.34, "spec": 0.5, "splash": 0.5},
	&"scorch_a": {"mask": "scorch_01", "mode": 0, "core": BLACK, "edge": BLACK, "rough": 0.9, "spec": 0.05, "splash": 1.0},
	&"scorch_b": {"mask": "scorch_02", "mode": 0, "core": BLACK, "edge": BLACK, "rough": 0.9, "spec": 0.05, "splash": 1.0},
	&"scorch_c": {"mask": "scorch_03", "mode": 0, "core": BLACK, "edge": BLACK, "rough": 0.9, "spec": 0.05, "splash": 1.0},
	&"oil_a": {"mask": "dirt_01", "mode": 0, "core": BLACK, "edge": BLACK, "rough": 0.12, "spec": 0.8, "splash": 1.0},
	&"oil_b": {"mask": "dirt_02", "mode": 0, "core": BLACK, "edge": BLACK, "rough": 0.12, "spec": 0.8, "splash": 1.0},
	&"oil_c": {"mask": "dirt_03", "mode": 0, "core": BLACK, "edge": BLACK, "rough": 0.12, "spec": 0.8, "splash": 1.0},
	&"skid": {"mask": "dirt_01", "mode": 3, "core": BLACK, "edge": BLACK, "rough": 0.7, "spec": 0.1, "splash": 0.0},
	&"crack": {"mask": "trace_03", "mode": 0, "core": BLACK, "edge": BLACK, "rough": 0.9, "spec": 0.05, "splash": 1.0},
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _buckets: Dictionary = {}   # tür -> {xfs, colors, seeds}
var _groups: Array[Dictionary] = []
var _blocked: Array[Vector2]
var _corpses: Array[Vector3]
var _hot: Array[Vector3]


func _init(blocked: Array[Vector2], corpses: Array[Vector3], hot: Array[Vector3]) -> void:
	_blocked = blocked
	_corpses = corpses
	_hot = hot


func _ready() -> void:
	name = "CityDecals"
	_rng.seed = Tuning.DRESS_SEED + 77
	if Tuning.FEATURE_CITY_BLOOD_DECALS:
		_build_blood()
	if Tuning.FEATURE_CITY_GROUND_DECALS:
		_build_ground()
	_flush()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


## Sokak haçı üzerinde rastgele nokta (alan içine ağırlıklı).
func _street_point(margin: float) -> Vector3:
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
			if Vector2(p.x, p.z).distance_to(b) < 2.0:
				ok = false
				break
		if ok:
			return p
	return _street_point(margin)


## Kaldırım şeridinde mi (iki eksenden küçüğü asfalt yarı genişliğinden büyük).
func _raised(p: Vector3) -> bool:
	var asphalt: float = Tuning.CITY_STREET_WIDTH * 0.5 - Tuning.CITY_SIDEWALK_WIDTH
	return minf(absf(p.x), absf(p.z)) > asphalt


func _put(kind: StringName, p: Vector3, yaw: float, size: Vector2, alpha: float, y: float = -1.0) -> void:
	if not _buckets.has(kind):
		_buckets[kind] = {"xfs": [] as Array[Transform3D], "colors": [] as Array[Color], "seeds": [] as Array[float]}
	var level: float = y if y >= 0.0 else (Y_RAISED if _raised(p) else Y_BLOOD)
	var xform_basis: Basis = Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(size.x, 1.0, size.y))
	var b: Dictionary = _buckets[kind]
	b["xfs"].append(Transform3D(xform_basis, Vector3(p.x, level, p.z)))
	b["colors"].append(Color(_rng.randf_range(0.8, 1.15), _rng.randf_range(0.8, 1.15), _rng.randf_range(0.8, 1.15), alpha))
	b["seeds"].append(_rng.randf())


func _yaw_of(dir: Vector3) -> float:
	return atan2(-dir.z, dir.x)


func _random_dir() -> Vector3:
	return Vector3.RIGHT.rotated(Vector3.UP, _rng.randf() * TAU)


func _splash_kind() -> StringName:
	return [&"splash_a", &"splash_b", &"splash_c"][_rng.randi() % 3]


# --- Kan ---

func _build_blood() -> void:
	for c: Vector3 in _corpses:
		_puddle(c + Vector3(_rng.randf_range(-0.3, 0.3), 0.0, _rng.randf_range(-0.3, 0.3)), _rng.randf_range(1.3, 2.1))
		_put(_splash_kind(), c, _rng.randf() * TAU, Vector2.ONE * _rng.randf_range(2.2, 3.4), 0.85)
		if _rng.randf() < 0.7:
			_trail(c, _random_dir(), _rng.randf_range(2.5, 5.0))
	for i: int in Tuning.DRESS_BLOOD_POOLS:
		var p: Vector3 = _free_point(0.5)
		if i % 2 == 0:
			_puddle(p, _rng.randf_range(0.9, 2.4))
		else:
			_put(_splash_kind(), p, _rng.randf() * TAU, Vector2.ONE * _rng.randf_range(1.6, 3.2), _rng.randf_range(0.7, 0.9))
	for i: int in Tuning.DRESS_BLOOD_TRAILS:
		var p: Vector3 = _free_point(1.5)
		_puddle(p, _rng.randf_range(0.7, 1.3))
		_trail(p, _random_dir(), _rng.randf_range(3.0, 6.0))
	for i: int in Tuning.CITY_BLOOD_FOOTPRINTS:
		_footprints(_free_point(1.5), _random_dir())
	for i: int in Tuning.CITY_BLOOD_SPLASHES:
		var near: Vector3 = _hot[_rng.randi() % _hot.size()] if not _hot.is_empty() and _rng.randf() < 0.6 else _free_point(0.5)
		near += Vector3(_rng.randf_range(-1.5, 1.5), 0.0, _rng.randf_range(-1.5, 1.5))
		_put(_splash_kind(), near, _rng.randf() * TAU, Vector2.ONE * _rng.randf_range(0.9, 2.0), _rng.randf_range(0.6, 0.85))


func _puddle(p: Vector3, diameter: float) -> void:
	_put(&"puddle", p, _rng.randf() * TAU, Vector2(diameter * _rng.randf_range(0.9, 1.3), diameter), _rng.randf_range(0.8, 0.95))


## Ceset yanından uzanan sürüklenme izi: başı geniş, ucu ince; ucunda küçük damla.
func _trail(start: Vector3, dir: Vector3, length: float) -> void:
	var bent: Vector3 = dir.rotated(Vector3.UP, _rng.randf_range(-0.12, 0.12))
	_put(&"trail", start + bent * length * 0.5, _yaw_of(bent), Vector2(length, _rng.randf_range(0.6, 0.95)), _rng.randf_range(0.8, 0.95))
	_put(&"drop", start + bent * (length + 0.3), _rng.randf() * TAU, Vector2.ONE * _rng.randf_range(0.25, 0.4), 0.8)


## Ayak izi damlaları: sağ-sol dönüşümlü küçük ovaller, sona doğru solar.
func _footprints(start: Vector3, dir: Vector3) -> void:
	var side: Vector3 = dir.rotated(Vector3.UP, PI * 0.5)
	var steps: int = _rng.randi_range(6, 10)
	for k: int in steps:
		var p: Vector3 = start + dir * (k * 0.75) + side * (0.18 if k % 2 == 0 else -0.18)
		var fade: float = 1.0 - float(k) / float(steps)
		_put(&"drop", p, _yaw_of(dir) + _rng.randf_range(-0.2, 0.2), Vector2(0.34, 0.18) * (0.6 + 0.6 * fade), 0.9 * (0.4 + 0.6 * fade))


# --- Zemin dokusu ---

func _build_ground() -> void:
	var fires: Array[Vector3] = []
	fires.append_array(CityProps.FIRE_SPOTS)
	fires.append(Tuning.CITY_FIRE_STOREFRONT)
	for p: Vector3 in fires:
		_scorch(p, _rng.randf_range(4.2, 5.6), 0.8)
	for p: Vector3 in Tuning.CITY_TRASH_FIRES:
		_scorch(p, _rng.randf_range(2.6, 3.6), 0.7)
	for i: int in Tuning.CITY_SCORCH_BLASTS:
		_scorch(_free_point(1.0), _rng.randf_range(2.8, 5.0), _rng.randf_range(0.35, 0.55))
	for i: int in Tuning.CITY_OIL_COUNT:
		var kind: StringName = [&"oil_a", &"oil_b", &"oil_c"][_rng.randi() % 3]
		_put(kind, _free_point(0.5), _rng.randf() * TAU, Vector2.ONE * _rng.randf_range(1.5, 4.5), _rng.randf_range(0.25, 0.45), Y_GROUND)
	for i: int in Tuning.CITY_SKID_COUNT:
		_skid()
	for i: int in Tuning.CITY_CRACK_COUNT:
		var p: Vector3 = _free_point(0.3)
		_put(&"crack", p, _rng.randf() * TAU, Vector2(_rng.randf_range(0.6, 1.0), _rng.randf_range(2.5, 6.0)), _rng.randf_range(0.55, 0.8), Y_GROUND)


func _scorch(p: Vector3, size: float, alpha: float) -> void:
	var kind: StringName = [&"scorch_a", &"scorch_b", &"scorch_c"][_rng.randi() % 3]
	_put(kind, p, _rng.randf() * TAU, Vector2.ONE * size, alpha, Y_GROUND)


## Lastik izi: şerit yönünde, yol (asfalt) üstünde, hafif eğik.
func _skid() -> void:
	var half: float = Tuning.ARENA_SIZE * 0.5
	var span: float = _rng.randf_range(7.0, 14.0)
	var lane: float = _rng.randf_range(-7.0, 7.0)
	var along: float = _rng.randf_range(-half, half)
	var yaw: float = _rng.randf_range(-0.1, 0.1)
	var p: Vector3 = Vector3(along, 0.0, lane)
	if _rng.randf() < 0.5:
		p = Vector3(lane, 0.0, along)
		yaw += PI * 0.5
	_put(&"skid", p, yaw, Vector2(span, 1.3), _rng.randf_range(0.4, 0.6), Y_GROUND)


# --- Düğümler ---

func _flush() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	quad.orientation = PlaneMesh.FACE_Y
	for kind: StringName in _buckets:
		var b: Dictionary = _buckets[kind]
		var xfs: Array = b["xfs"]
		var spec: Dictionary = KINDS[kind]
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = quad
		mm.instance_count = xfs.size()
		for i: int in xfs.size():
			mm.set_instance_transform(i, xfs[i])
			mm.set_instance_color(i, b["colors"][i])
			mm.set_instance_custom_data(i, Color(b["seeds"][i], 0.0, 0.0, 0.0))
		var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
		node.multimesh = mm
		node.material_override = _material(spec)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		_groups.append({"node": node, "total": xfs.size()})


func _material(spec: Dictionary) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"mask", load(MASK_PATH % spec["mask"]))
	mat.set_shader_parameter(&"mode", spec["mode"])
	mat.set_shader_parameter(&"core_color", spec["core"])
	mat.set_shader_parameter(&"edge_color", spec["edge"])
	mat.set_shader_parameter(&"roughness_value", spec["rough"])
	mat.set_shader_parameter(&"spec", spec["spec"])
	mat.set_shader_parameter(&"splash", spec["splash"])
	return mat


func _apply_quality(_profile_id: StringName) -> void:
	var factor: float = Quality.get_value("ground_dressing")
	for g: Dictionary in _groups:
		(g["node"] as MultiMeshInstance3D).multimesh.visible_instance_count = int(ceilf(float(g["total"]) * factor))
