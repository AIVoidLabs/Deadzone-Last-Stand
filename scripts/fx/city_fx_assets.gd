class_name CityFxAssets
extends RefCounted
## 8.3b: şehir efektleri için betikle üretilmiş dokular ve malzemeler (dosya yok).

const FLAME_SHADER: Shader = preload("res://assets/shaders/city_flame.gdshader")

const SPARK_SHADER: Shader = preload("res://assets/shaders/city_spark.gdshader")
const WISP_SHADER: Shader = preload("res://assets/shaders/city_wisp.gdshader")
const GLOW_SHADER: Shader = preload("res://assets/shaders/city_glow.gdshader")
const EMBER_SHADER: Shader = preload("res://assets/shaders/city_ember.gdshader")
const HAZE_SHADER: Shader = preload("res://assets/shaders/city_haze.gdshader")
const WINDOW_SHADER: Shader = preload("res://assets/shaders/city_window_fire.gdshader")

const KENNEY_DIR: String = "res://assets/textures/fx/kenney/%s.png"
const SMOKE_TEXTURES: Array[String] = ["smoke_01", "smoke_03", "smoke_05", "smoke_07"]

static var _soft: GradientTexture2D = null
static var _puff: GradientTexture2D = null


## Duman puf dokusu: geniş opak çekirdek, yumuşak kenar.
static func puff_texture() -> GradientTexture2D:
	if _puff == null:
		var grad: Gradient = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
		_puff = GradientTexture2D.new()
		_puff.gradient = grad
		_puff.fill = GradientTexture2D.FILL_RADIAL
		_puff.fill_from = Vector2(0.5, 0.5)
		_puff.fill_to = Vector2(1.0, 0.5)
		_puff.width = 64
		_puff.height = 64
	return _puff


## Kenney dokusu (CC0, assets/textures/fx/kenney/).
static func kenney(name: String) -> Texture2D:
	return load(KENNEY_DIR % name) as Texture2D


## Ince duman tülü: Kenney smoke dokusu, alfa renk rampasından (vertex color).
static func smoke_material(index: int) -> StandardMaterial3D:
	var mat: StandardMaterial3D = particle_material(false, kenney(SMOKE_TEXTURES[index % SMOKE_TEXTURES.size()]))
	return mat


## Alev malzemesi (shader billboard).
static func flame_material() -> ShaderMaterial:
	var mat: ShaderMaterial = _shader_mat(FLAME_SHADER)
	mat.set_shader_parameter(&"hdr", Tuning.CITY_FLAME_HDR)
	return mat


static func _shader_mat(shader: Shader) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	return mat


static func spark_material() -> ShaderMaterial:
	var mat: ShaderMaterial = _shader_mat(SPARK_SHADER)
	mat.set_shader_parameter(&"hdr", Tuning.CITY_SPARK_HDR)
	return mat


static func wisp_material() -> ShaderMaterial:
	return _shader_mat(WISP_SHADER)


static func ember_material() -> ShaderMaterial:
	return _shader_mat(EMBER_SHADER)


static func window_material() -> ShaderMaterial:
	return _shader_mat(WINDOW_SHADER)


## Zemine sızan sahte ışık malzemesi (additive radyal leke).
static func glow_material(color: Color, energy: float, flicker: float, seed_value: float) -> ShaderMaterial:
	var mat: ShaderMaterial = _shader_mat(GLOW_SHADER)
	mat.set_shader_parameter(&"glow_color", color)
	mat.set_shader_parameter(&"energy", energy)
	mat.set_shader_parameter(&"flicker", flicker)
	mat.set_shader_parameter(&"seed", seed_value)
	return mat


static func haze_material(height_index: int) -> ShaderMaterial:
	var mat: ShaderMaterial = _shader_mat(HAZE_SHADER)
	mat.set_shader_parameter(&"alpha", Tuning.CITY_SMOKE_HAZE_ALPHA * (1.0 if height_index == 0 else 0.7))
	mat.set_shader_parameter(&"scale", 0.07 if height_index == 0 else 0.045)
	mat.set_shader_parameter(&"drift", Vector2(0.5, 0.2) if height_index == 0 else Vector2(-0.3, 0.45))
	return mat


## Yere yatan kare (glow, kor, pus).
static func flat_quad(size: float) -> QuadMesh:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(size, size)
	mesh.orientation = PlaneMesh.FACE_Y
	return mesh


## Zemine serilen sahte ışık düğümü (yerden biraz yukarıda; kaldırım 0.08).
static func glow_quad(pos: Vector3, radius: float, color: Color, energy: float, flicker: float) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = flat_quad(radius * 2.0)
	mi.material_override = glow_material(color, energy, flicker, pos.x * 1.3 + pos.z * 0.7)
	mi.position = Vector3(pos.x, 0.1, pos.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Alt noktası pivot olan dikey quad (alev, kıvılcım).
static func tall_quad(width: float, height: float) -> QuadMesh:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(width, height)
	mesh.center_offset = Vector3(0.0, height * 0.5, 0.0)
	return mesh


## Yumuşak dairesel leke (merkez opak, kenar saydam).
static func soft_texture() -> GradientTexture2D:
	if _soft == null:
		var grad: Gradient = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		_soft = GradientTexture2D.new()
		_soft.gradient = grad
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(1.0, 0.5)
		_soft.width = 64
		_soft.height = 64
	return _soft


## Parçacık billboard malzemesi; additive = alev / kıvılcım, değilse duman / kül.
static func particle_material(additive: bool, tex: Texture2D = null) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex if tex != null else soft_texture()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


static func ramp(offsets: Array[float], colors: Array[Color]) -> GradientTexture1D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array(offsets)
	grad.colors = PackedColorArray(colors)
	var tex: GradientTexture1D = GradientTexture1D.new()
	tex.gradient = grad
	return tex


## Ölçek eğrisi: (0..1 yaşam, değer) noktaları.
static func scale_curve(points: Array[Vector2]) -> CurveTexture:
	var curve: Curve = Curve.new()
	for p: Vector2 in points:
		curve.add_point(p)
	var tex: CurveTexture = CurveTexture.new()
	tex.curve = curve
	return tex


static func quad(size: float) -> QuadMesh:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(size, size)
	return mesh


## Emisif malzeme (neon, ampul).
static func emissive(color: Color, energy: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color * 0.3
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.6
	return mat
