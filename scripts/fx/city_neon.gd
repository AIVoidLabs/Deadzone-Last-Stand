class_name CityNeon
extends Node3D
## 8.3b: bina cephesine soyut neon şekiller (çizgi, ok, kalp; yazı yok) ve yanlarında zayıf renkli ışık.
## Konumlar Tuning.CITY_NEON_SPOTS. Bozuk olanlar düzensiz yanıp söner.

var lights: Array[OmniLight3D] = []
var _mats: Array[StandardMaterial3D] = []
var _flickers: Array[BrokenFlicker] = []  # _mats ile aynı sıra; null = sağlam
var _light_base: Array[float] = []


func _ready() -> void:
	name = "CityNeon"
	var i: int = 0
	for spot: Dictionary in Tuning.CITY_NEON_SPOTS:
		_build_spot(spot, i)
		i += 1


func _process(delta: float) -> void:
	for i: int in _mats.size():
		var f: BrokenFlicker = _flickers[i]
		if f == null:
			continue
		var k: float = f.step(delta)
		_mats[i].emission_energy_multiplier = Tuning.CITY_NEON_EMISSION * k
		lights[i].light_energy = _light_base[i] * k


func _build_spot(spot: Dictionary, index: int) -> void:
	var color: Color = spot["color"]
	var u: Vector3 = spot["u"]
	var origin: Vector3 = spot["pos"]
	var normal: Vector3 = Vector3.UP.cross(u).normalized()
	var mat: StandardMaterial3D = CityFxAssets.emissive(color, Tuning.CITY_NEON_EMISSION)
	var size: float = spot["size"]
	for seg: Array in _segments(spot["kind"], size):
		_bar(origin + u * seg[0].x + Vector3.UP * seg[0].y, origin + u * seg[1].x + Vector3.UP * seg[1].y, normal, mat)
	var light: OmniLight3D = OmniLight3D.new()
	light.position = origin + normal * Tuning.CITY_NEON_LIGHT_OFFSET
	light.light_color = color
	light.light_energy = Tuning.CITY_NEON_LIGHT_ENERGY
	light.omni_range = Tuning.CITY_NEON_LIGHT_RANGE
	add_child(light)
	lights.append(light)
	_mats.append(mat)
	_light_base.append(light.light_energy)
	_flickers.append(BrokenFlicker.new(7 + index) if spot["broken"] else null)


## Şekil parçaları: [[a(u,v), b(u,v)], ...].
func _segments(kind: StringName, s: float) -> Array:
	var out: Array = []
	match kind:
		&"line":
			out.append([Vector2(-s, 0.25 * s), Vector2(s, 0.25 * s)])
			out.append([Vector2(-s * 0.6, -0.25 * s), Vector2(s * 0.6, -0.25 * s)])
		&"arrow":
			out.append([Vector2(-s, 0.0), Vector2(s, 0.0)])
			out.append([Vector2(s, 0.0), Vector2(s * 0.45, s * 0.5)])
			out.append([Vector2(s, 0.0), Vector2(s * 0.45, -s * 0.5)])
		&"heart":
			var prev: Vector2 = Vector2.ZERO
			for k: int in 17:
				var t: float = TAU * k / 16.0
				var p: Vector2 = Vector2(16.0 * pow(sin(t), 3.0), 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)) * (s / 16.0)
				if k > 0:
					out.append([prev, p])
				prev = p
	return out


func _bar(a: Vector3, b: Vector3, normal: Vector3, mat: Material) -> void:
	var dir: Vector3 = b - a
	var bar: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(dir.length() + Tuning.CITY_NEON_THICKNESS, Tuning.CITY_NEON_THICKNESS, Tuning.CITY_NEON_THICKNESS)
	bar.mesh = mesh
	bar.material_override = mat
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bx: Vector3 = dir.normalized()
	bar.transform = Transform3D(Basis(bx, normal.cross(bx), normal), (a + b) * 0.5)
	add_child(bar)
