class_name CityGreybox
extends Node3D
## Kaba şehir kavşağı (8.1a): oyun alanı kavşağın kendisi. Köşelerde çarpışmalı bloklar (içeride),
## kollar ve dış bloklar yalnız görsel. Düğümler kodla kurulur. Kapatma: Tuning.FEATURE_CITY_GREYBOX.

const SIDEWALK: Color = Color(0.3, 0.3, 0.32)
const LANE: Color = Color(0.55, 0.55, 0.5)
const STAIN: Color = Color(0.02, 0.015, 0.015)
const RUST_A: Color = Color(0.32, 0.16, 0.1)
const RUST_B: Color = Color(0.24, 0.13, 0.1)
const RUST_C: Color = Color(0.2, 0.17, 0.15)
const BIN: Color = Color(0.12, 0.2, 0.15)
const BARRICADE: Color = Color(0.45, 0.32, 0.14)
const BRICK: Color = Color(0.4, 0.15, 0.12)
const GREY: Color = Color(0.28, 0.3, 0.34)
const POLE: Color = Color(0.12, 0.12, 0.13)
const FIRE_COLOR: Color = Color(1.0, 0.45, 0.12)
const LAMP_COLOR: Color = Color(1.0, 0.8, 0.45)
const NEON_COLOR: Color = Color(0.25, 1.0, 0.8)
const TILT_DEG: float = 12.0
const LANE_DASH: float = 3.0
const LANE_STEP: float = 7.0
const LANE_WIDTH: float = 0.25

## Dış bloklar (köşe başına; x, z, genişlik, derinlik, yükseklik, renk 0/1, yıkık mı); işaretle yansıtılır.
const OUTER_BLOCKS: Array = [
	[14.0, 34.0, 14.0, 16.0, 18.0, 0, false],
	[32.0, 34.0, 16.0, 14.0, 24.0, 1, true],
	[34.0, 14.0, 14.0, 12.0, 11.0, 0, false],
	[18.0, 56.0, 20.0, 14.0, 9.0, 1, false],
	[46.0, 48.0, 16.0, 18.0, 15.0, 0, true],
]
const STAIN_SPOTS: Array = [Vector3(-4, 0, 6), Vector3(5, 0, -8), Vector3(-16, 0, -5), Vector3(3, 0, 17), Vector3(18, 0, 4)]
## Yanan araba (ateşli) ve sönük araba konumları; sokaklarda, bloklarda değil.
const FIRE_CARS: Array[Vector3] = [Vector3(-4.0, 0.0, -20.0), Vector3(20.0, 0.0, 3.5)]
const DEAD_CARS: Array = [Vector3(5.0, 0.0, 24.0), Vector3(-22.0, 0.0, -4.0)]
const BIN_SPOTS: Array = [Vector3(-9.0, 0.0, 12.5), Vector3(9.0, 0.0, -13.0), Vector3(12.5, 0.0, 9.5), Vector3(-12.0, 0.0, -9.5)]
## Sokak lambaları (kaldırım kenarı); sonuncusu zayıf.
const LAMP_SPOTS: Array = [Vector3(-9.5, 0.0, -16.0), Vector3(9.5, 0.0, 16.0), Vector3(17.0, 0.0, -9.5), Vector3(-17.0, 0.0, 9.5)]
const LAMP_HEIGHT: float = 4.4
const FLAME_SIZE: Vector3 = Vector3(1.4, 0.6, 1.0)

var _mats: Dictionary = {}
## Sıra önemli (profil sınırı baştan sayar): ateşler, neon, lambalar.
var _lights: Array[OmniLight3D] = []
var _fire_lights: Array[OmniLight3D] = []


func _ready() -> void:
	name = "CityGreybox"
	_build_ground()
	_build_sidewalks_and_lanes()
	if Tuning.FEATURE_CITY_PROPS:
		add_child(CityPropsBuilder.new())
	else:
		_build_barricades()
	_build_outer_blocks()
	_build_inner_blocks()
	_build_decor()
	_build_lights()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


func _material(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var key: String = "%s%s" % [color, emissive]
	if not _mats.has(key):
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.95
		if emissive:
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 2.5
		_mats[key] = mat
	return _mats[key]


func _box(pos: Vector3, size: Vector3, color: Color, tilt: float = 0.0, emissive: bool = false) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material(color, emissive)
	mi.position = pos + Vector3(0.0, size.y * 0.5, 0.0)
	mi.rotation_degrees.z = tilt
	add_child(mi)
	return mi


func _solid_box(pos: Vector3, size: Vector3, color: Color, show_mesh: bool = true) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.position = pos + Vector3(0.0, size.y * 0.5, 0.0)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	if show_mesh:
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = size
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _material(color)
		body.add_child(mi)
	add_child(body)


func _build_ground() -> void:
	var extent: float = Tuning.ARENA_SIZE + Tuning.CITY_STREET_LENGTH * 2.0 + 120.0
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(extent, extent)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Tuning.CITY_GROUND_COLOR
	mat.roughness = Tuning.CITY_GROUND_ROUGHNESS
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = mat
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)


## Kaldırım şeritleri blok kenarlarında (sokak tarafı), sokak ortasında kesik şerit çizgisi.
func _build_sidewalks_and_lanes() -> void:
	var half: float = Tuning.ARENA_SIZE * 0.5
	var w: float = Tuning.CITY_STREET_WIDTH * 0.5
	var sw: float = Tuning.CITY_SIDEWALK_WIDTH
	var end: float = half + Tuning.CITY_STREET_LENGTH
	for s: float in [-1.0, 1.0]:
		for edge: float in [-1.0, 1.0]:
			var off: float = edge * (w - sw * 0.5)
			# x ekseni boyunca kollar (z = off) ve z ekseni boyunca kollar (x = off)
			_strip(Vector3(s * (w + end) * 0.5, 0.0, off), Vector3(end - w, 0.08, sw))
			_strip(Vector3(off, 0.0, s * (w + end) * 0.5), Vector3(sw, 0.08, end - w))
	for dir: float in [-1.0, 1.0]:
		var d: float = w + LANE_DASH
		while d < end:
			_box(Vector3(dir * d, 0.0, 0.0), Vector3(LANE_DASH, 0.03, LANE_WIDTH), LANE)
			_box(Vector3(0.0, 0.0, dir * d), Vector3(LANE_WIDTH, 0.03, LANE_DASH), LANE)
			d += LANE_STEP


func _strip(center: Vector3, size: Vector3) -> void:
	_box(center, size, SIDEWALK)


## Kol ağzı (alan duvarının üstü) ve kol ucu barikatları; yalnız görsel.
func _build_barricades() -> void:
	var half: float = Tuning.ARENA_SIZE * 0.5
	var width: float = Tuning.CITY_STREET_WIDTH
	var depth: float = Tuning.CITY_BARRICADE_DEPTH
	var h: float = Tuning.CITY_BARRICADE_HEIGHT
	for dist: float in [half + Tuning.ARENA_WALL_THICKNESS * 0.5, half + Tuning.CITY_STREET_LENGTH - 2.0]:
		for s: float in [-1.0, 1.0]:
			_box(Vector3(s * dist, 0.0, 0.0), Vector3(depth, h, width), BARRICADE)
			_box(Vector3(0.0, 0.0, s * dist), Vector3(width, h, depth), BARRICADE)


func _build_outer_blocks() -> void:
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			for row: Array in OUTER_BLOCKS:
				var size: Vector3 = Vector3(row[2], row[4], row[3])
				var center: Vector3 = Vector3(sx * (row[0] + row[2] * 0.5), 0.0, sz * (row[1] + row[3] * 0.5))
				var color: Color = BRICK if row[5] == 0 else GREY
				var tilt: float = TILT_DEG * sx if row[6] else 0.0
				_box(center, size, color, tilt)
				if row[6]:
					_box(center + Vector3(size.x * 0.25, size.y, 0.0), Vector3(size.x * 0.4, size.y * 0.2, size.z * 0.6), color)


## Alan içi dört blok: çarpışmalı; biri yıkık (eksik üst köşe).
func _build_inner_blocks() -> void:
	var rects: Array[Rect2] = CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH)
	var building: PackedScene = null
	if Tuning.FEATURE_CITY_BUILDINGS:
		building = load(Tuning.CITY_BUILDING_SCENE) as PackedScene
	for i: int in rects.size():
		var rect: Rect2 = rects[i]
		var height: float = Tuning.CITY_INNER_BLOCK_HEIGHTS[i]
		var color: Color = BRICK if i % 3 == 0 else GREY
		var center: Vector3 = Vector3(rect.get_center().x, 0.0, rect.get_center().y)
		if building != null:
			_solid_box(center, Vector3(rect.size.x, height, rect.size.y), color, false)
			_place_building(building, center)
			continue
		_solid_box(center, Vector3(rect.size.x, height, rect.size.y), color)
		if i == 1:
			# Yıkık çatı: üstte kırık basamak
			_box(center + Vector3(-rect.size.x * 0.2, height, 0.0), Vector3(rect.size.x * 0.5, height * 0.25, rect.size.y * 0.7), color)


## Model sokak cepheleri +X ve +Z yönüne bakar; her köşede merkeze bakacak kadar yalnız döndürülür (ölçek yok).
func _place_building(scene: PackedScene, center: Vector3) -> void:
	var node: Node3D = scene.instantiate() as Node3D
	node.position = center
	var quarter: int
	if center.x < 0.0:
		quarter = 0 if center.z < 0.0 else 1
	else:
		quarter = 2 if center.z > 0.0 else 3
	node.rotation_degrees.y = 90.0 * quarter
	add_child(node)


## Ateş konumları: prop açıkken yanmış araçların üstü, kapalıyken eski kutu arabalar.
func _fire_spots() -> Array[Vector3]:
	return CityProps.FIRE_SPOTS if Tuning.FEATURE_CITY_PROPS else FIRE_CARS


func _build_decor() -> void:
	for p: Vector3 in STAIN_SPOTS:
		var stain: MeshInstance3D = _box(p, Vector3(3.0 + absf(p.x) * 0.1, 0.02, 2.2), STAIN)
		stain.rotation_degrees.y = p.x * 7.0
	for p: Vector3 in _fire_spots():
		if not Tuning.FEATURE_CITY_PROPS:
			_box(p, Vector3(4.4, 1.5, 1.9), RUST_A)
		_box(p + Vector3(0.0, 1.5, 0.0), FLAME_SIZE, FIRE_COLOR, 0.0, true)
	if not Tuning.FEATURE_CITY_PROPS:
		for i: int in DEAD_CARS.size():
			_box(DEAD_CARS[i], Vector3(4.4, 1.5, 1.9), RUST_B if i == 0 else RUST_C)
		for p: Vector3 in BIN_SPOTS:
			_box(p, Vector3(0.8, 1.0, 0.8), BIN)
	for p: Vector3 in LAMP_SPOTS:
		_box(p, Vector3(0.25, LAMP_HEIGHT, 0.25), POLE)
	# Neon: -x-z blok cephesi (sokağa bakan yüz)
	var half: float = Tuning.ARENA_SIZE * 0.5
	var face: float = -Tuning.CITY_STREET_WIDTH * 0.5
	_box(Vector3(face + 0.15, 2.5, -half * 0.55), Vector3(0.2, 0.7, 7.0), NEON_COLOR, 0.0, true)


func _build_lights() -> void:
	for p: Vector3 in _fire_spots():
		var fire: OmniLight3D = _omni(p + Vector3(0.0, 2.2, 0.0), FIRE_COLOR, Tuning.CITY_FIRE_ENERGY, Tuning.CITY_FIRE_RANGE)
		_fire_lights.append(fire)
	var face: float = -Tuning.CITY_STREET_WIDTH * 0.5
	_omni(Vector3(face + 2.5, 3.0, -Tuning.ARENA_SIZE * 0.275), NEON_COLOR, Tuning.CITY_NEON_ENERGY, Tuning.CITY_NEON_RANGE)
	for i: int in LAMP_SPOTS.size():
		var energy: float = Tuning.CITY_LAMP_ENERGY * (Tuning.CITY_LAMP_WEAK_FACTOR if i == LAMP_SPOTS.size() - 1 else 1.0)
		_omni(LAMP_SPOTS[i] + Vector3(0.0, LAMP_HEIGHT, 0.0), LAMP_COLOR, energy, Tuning.CITY_LAMP_RANGE)


func _omni(pos: Vector3, color: Color, energy: float, range_m: float) -> OmniLight3D:
	var light: OmniLight3D = OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	add_child(light)
	_lights.append(light)
	return light


## Profil: omni ışık sayısı üst sınırı ve ateşlerde gölge.
func _apply_quality(_profile_id: StringName) -> void:
	var count: int = Quality.get_value("omni_lights")
	var fire_shadows: bool = Quality.get_value("fire_shadows")
	for i: int in _lights.size():
		_lights[i].visible = i < count
		_lights[i].shadow_enabled = fire_shadows and _fire_lights.has(_lights[i])
