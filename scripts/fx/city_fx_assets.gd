class_name CityFxAssets
extends RefCounted
## 8.3b: şehir efektleri için betikle üretilmiş dokular ve malzemeler (dosya yok).

const FLAME_SHADER: Shader = preload("res://assets/shaders/city_flame.gdshader")

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


## Alev malzemesi (shader billboard).
static func flame_material() -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = FLAME_SHADER
	return mat


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
