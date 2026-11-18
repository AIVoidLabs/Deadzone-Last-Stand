class_name MeleeSlash
extends MeshInstance3D
## Yakın dövüş kesik izi: silahın vurduğu yayı gösterir (yalnız görüntü). Silah başına bir tane; havuz gerekmez.

const SHADER: Shader = preload("res://assets/shaders/melee_slash.gdshader")
const SEGMENTS: int = 20
## İç yarıçap oranı: savurmada iz yalnız dış kısımda (hilal), dürtmede merkeze yakın başlar.
const INNER_SWING: float = 0.4
const INNER_THRUST: float = 0.1
## Dürtmede (yay yok) gösterilen dar dilimin açısı.
const THRUST_ARC_DEG: float = 9.0
const FADE_TIME: float = 0.22
## Sönerken iz rüzgar gibi dağılır: yarıçap bu oranda büyür.
const DISPERSE: float = 0.12

var _time: float = 0.0
var _swing_time: float = 0.2
var _thrust: bool = false
var _base_scale: Vector3 = Vector3.ONE


## radial: iz merkezden dışa doğru açılır (dürtme ve itme patlaması); değilse yay boyunca savrulur.
## arc_deg 0 ise dürtmedir ve dar bir dilim gösterilir.
func setup(arc_deg: float, color: Color, radial: bool = false) -> void:
	_thrust = radial or arc_deg <= 0.0
	var arc: float = THRUST_ARC_DEG if arc_deg <= 0.0 else arc_deg
	mesh = _build_mesh(deg_to_rad(arc), INNER_THRUST if _thrust else INNER_SWING)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"color", color)
	material.set_shader_parameter(&"thrust", _thrust)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false
	set_process(false)


## yaw: izin yönü (üst düğüme göre); side: +1 ya da -1 (savurma yönü, art arda dönüşümlü); reach: yarıçap (m).
func play(yaw: float, side: float, reach: float, swing_time: float) -> void:
	rotation.y = yaw
	_base_scale = Vector3(side * reach, 1.0, reach)
	scale = _base_scale
	_swing_time = maxf(swing_time, 0.01)
	_time = 0.0
	visible = true
	set_process(true)
	_apply(0.0)


func _process(delta: float) -> void:
	_time += delta
	if _time >= _swing_time + FADE_TIME:
		visible = false
		set_process(false)
		return
	_apply(_time)


func _apply(time: float) -> void:
	var reveal: float = clampf(time / _swing_time, 0.0, 1.0)
	var out: float = clampf((time - _swing_time) / FADE_TIME, 0.0, 1.0)
	var fade: float = 1.0 - out
	scale = _base_scale * Vector3(1.0 + DISPERSE * out, 1.0, 1.0 + DISPERSE * out)
	set_instance_shader_parameter(&"reveal", reveal)
	set_instance_shader_parameter(&"fade", fade)


## Merkezden +Z yönünde açılan, yatay yay dilimi. UV.y = 0 (+X tarafı) → 1 (-X tarafı).
static func _build_mesh(arc: float, inner: float) -> ArrayMesh:
	var verts: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var half: float = arc * 0.5
	for j in SEGMENTS + 1:
		var f: float = float(j) / float(SEGMENTS)
		var angle: float = lerpf(half, -half, f)
		verts.append(Vector3(sin(angle) * inner, 0.0, cos(angle) * inner))
		uvs.append(Vector2(inner, f))
		verts.append(Vector3(sin(angle), 0.0, cos(angle)))
		uvs.append(Vector2(1.0, f))
	for j in SEGMENTS:
		var k: int = j * 2
		indices.append_array(PackedInt32Array([k, k + 1, k + 2, k + 1, k + 3, k + 2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var array_mesh: ArrayMesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh
