class_name CityNeon
extends Node3D
## 8.3e: zemin kat tabelaları: ince tüp harf / şekiller (BAR, OPEN, 24H, MOTEL, PIZZA, ok, fincan, berber direği),
## duvardan öne eğik asılı. Her tabelanın altına sahte renkli ışık sızıntısı; gerçek omni yalnız "light" olanlarda.
## Bozuk tabelada bir harf ölü, biri titrek. Konumlar Tuning.CITY_NEON_SPOTS.

const SIGN_TILT: float = 0.55
const SIGN_OUT: float = 0.9
const SPILL_OUT: float = 2.2
const BARBER_RED: Color = Color(1.0, 0.1, 0.1)
const BARBER_BLUE: Color = Color(0.2, 0.4, 1.0)

var lights: Array[OmniLight3D] = []
var _signs: Array[Dictionary] = []


func _ready() -> void:
	name = "CityNeon"
	var i: int = 0
	for spot: Dictionary in Tuning.CITY_NEON_SPOTS:
		_build_sign(spot, i)
		i += 1


func _process(delta: float) -> void:
	for s: Dictionary in _signs:
		var f: BrokenFlicker = s["flicker"]
		var k: float = f.step(delta)
		(s["flick_mat"] as StandardMaterial3D).emission_energy_multiplier = Tuning.CITY_NEON_EMISSION * k
		(s["spill"] as ShaderMaterial).set_shader_parameter(&"energy", Tuning.CITY_NEON_SPILL_ENERGY * (0.8 + 0.2 * k))
		if s["light"] != null:
			(s["light"] as OmniLight3D).light_energy = Tuning.CITY_NEON_LIGHT_ENERGY * (0.8 + 0.2 * k)


func _build_sign(spot: Dictionary, index: int) -> void:
	var color: Color = spot["color"]
	var n: Vector3 = spot["n"]
	var wall: Vector3 = spot["pos"]
	var size: float = spot["size"]
	var u: Vector3 = spot["u"]
	var sn: Vector3 = (n * SIGN_TILT + Vector3.UP * 0.85).normalized()
	var v: Vector3 = sn.cross(u)
	var layout: Dictionary = CityNeonFont.text_segments(spot["text"]) if spot.has("text") else CityNeonFont.shape_segments(spot["shape"])
	var width: float = layout["width"]
	var center: Vector3 = wall + n * SIGN_OUT
	var origin: Vector3 = center - u * (width * size * 0.5) - v * (size * 0.5)
	_backing(center, u, sn, v, width * size + 0.5, size + 0.5)
	var letter_count: int = (spot["text"] as String).length() if spot.has("text") else 1
	var mats: Array[StandardMaterial3D] = []
	for l: int in letter_count:
		mats.append(CityFxAssets.emissive(color, Tuning.CITY_NEON_EMISSION))
	var colored: Dictionary = {1: CityFxAssets.emissive(BARBER_RED, Tuning.CITY_NEON_EMISSION), 2: CityFxAssets.emissive(BARBER_BLUE, Tuning.CITY_NEON_EMISSION)}
	for seg: Array in layout["segs"]:
		var a: Vector3 = origin + u * (seg[0] * size) + v * (seg[1] * size)
		var b: Vector3 = origin + u * (seg[2] * size) + v * (seg[3] * size)
		var mat: Material = mats[seg[4]] if seg[5] == 0 else colored[seg[5]]
		_tube(a, b, sn, mat)
	var spill_pos: Vector3 = wall + n * SPILL_OUT
	var spill: MeshInstance3D = CityFxAssets.glow_quad(spill_pos, Tuning.CITY_NEON_SPILL_RADIUS, color, Tuning.CITY_NEON_SPILL_ENERGY, 0.0)
	if Tuning.FEATURE_CITY_FAKE_LIGHT:
		add_child(spill)
	var light: OmniLight3D = null
	if spot["light"]:
		light = OmniLight3D.new()
		light.position = center + sn * 0.8
		light.light_color = color
		light.light_energy = Tuning.CITY_NEON_LIGHT_ENERGY
		light.omni_range = Tuning.CITY_NEON_LIGHT_RANGE
		add_child(light)
		lights.append(light)
	AmbienceEmitter.attach(self, &"neon_broken" if spot["broken"] else &"neon", center)
	if spot["broken"] and letter_count > 1:
		mats[1].emission_energy_multiplier = 0.15
		_signs.append({"flicker": BrokenFlicker.new(7 + index), "flick_mat": mats[letter_count - 1], "spill": spill.material_override, "light": light})


func _backing(center: Vector3, u: Vector3, sn: Vector3, v: Vector3, w: float, h: float) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(w, 0.04, h)
	mi.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.03, 0.035)
	mat.roughness = 0.9
	mi.material_override = mat
	mi.transform = Transform3D(Basis(u, sn, -v), center - sn * 0.05)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _tube(a: Vector3, b: Vector3, sn: Vector3, mat: Material) -> void:
	var dir: Vector3 = b - a
	var tube: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	var t: float = Tuning.CITY_NEON_THICKNESS
	mesh.size = Vector3(dir.length() + t, t, t)
	tube.mesh = mesh
	tube.material_override = mat
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bx: Vector3 = dir.normalized()
	var by: Vector3 = (sn - bx * sn.dot(bx)).normalized()
	tube.transform = Transform3D(Basis(bx, by, bx.cross(by)), (a + b) * 0.5)
	add_child(tube)
