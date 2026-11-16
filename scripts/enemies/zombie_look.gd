class_name ZombieLook
extends RefCounted
## Zombi görünümü = gövde çeşidi (model dosyasındaki ağlardan biri) + renk şeması (palet satırı).
## Tek malzeme tüm zombilerde paylaşılır; şema ve vuruş parlaması örnek başına ayarlanır.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
## Palet dokusundaki sütun sayısı; tools/blender/build_zombie.py içindeki PALETTE_COLUMNS ile aynı.
const PALETTE_COLUMNS: int = 16

static var _material: ShaderMaterial
static var _scheme_count: int = 1


static func variant_count(model: Node3D) -> int:
	return ModelVariants.count(model)


## Paletteki renk şeması sayısı (ilk apply çağrısından sonra geçerli).
static func scheme_count() -> int:
	return _scheme_count


## Modelde tek çeşidi bırakır, ortak malzemeyi ve renk şemasını uygular. Dönüş: kalan ağ.
static func apply(model: Node3D, variant: int, scheme: int) -> MeshInstance3D:
	var mesh: MeshInstance3D = ModelVariants.keep(model, variant)
	mesh.material_override = _shared_material(mesh)
	# Blender'da ilk şema dokunun altındadır; glTF'te V ters olduğu için üst satırlara eksi yönde gidilir.
	mesh.set_instance_shader_parameter(&"palette_offset", -float(posmod(scheme, _scheme_count)) / _scheme_count)
	return mesh


static func apply_random(model: Node3D) -> MeshInstance3D:
	var mesh: MeshInstance3D = apply(model, randi() % variant_count(model), 0)
	mesh.set_instance_shader_parameter(&"palette_offset", -float(randi() % _scheme_count) / _scheme_count)
	return mesh


static func _shared_material(mesh: MeshInstance3D) -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = FLASH_SHADER
		_material.set_shader_parameter(&"albedo", Color.WHITE)
		var source: BaseMaterial3D = mesh.mesh.surface_get_material(0) as BaseMaterial3D
		if source != null and source.albedo_texture != null:
			var palette: Texture2D = source.albedo_texture
			_material.set_shader_parameter(&"albedo_texture", palette)
			@warning_ignore("integer_division")
			_scheme_count = maxi(1, palette.get_height() / (palette.get_width() / PALETTE_COLUMNS))
	return _material
