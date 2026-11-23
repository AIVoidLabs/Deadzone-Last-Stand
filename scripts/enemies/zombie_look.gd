class_name ZombieLook
extends RefCounted
## Zombi görünümü = gövde çeşidi (model dosyasındaki ağlardan biri) + renk şeması (palet satırı).
## Her model dosyasının (yürüyen, koşucu, tank) kendi paleti ve malzemesi vardır; şema ve vuruş
## parlaması örnek başına ayarlanır.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
## Palet dokusundaki sütun sayısı; tools/blender/build_zombie.py içindeki PALETTE_COLUMNS ile aynı.
const PALETTE_COLUMNS: int = 16

## Palet dokusu -> {material, schemes}
static var _by_palette: Dictionary = {}


static func clear_cache() -> void:
	_by_palette.clear()


static func variant_count(model: Node3D) -> int:
	return ModelVariants.count(model)


## Modelde tek çeşidi bırakır, o modelin ortak malzemesini ve renk şemasını uygular. Dönüş: kalan ağ.
static func apply(model: Node3D, variant: int, scheme: int) -> MeshInstance3D:
	var mesh: MeshInstance3D = ModelVariants.keep(model, variant)
	var entry: Dictionary = _entry(mesh)
	mesh.material_override = entry["material"]
	var count: int = entry["schemes"]
	# Blender'da ilk şema dokunun altındadır; glTF'te V ters olduğu için üst satırlara eksi yönde gidilir.
	mesh.set_instance_shader_parameter(&"palette_offset", -float(posmod(scheme, count)) / count)
	return mesh


static func apply_random(model: Node3D) -> MeshInstance3D:
	var mesh: MeshInstance3D = apply(model, randi() % variant_count(model), 0)
	var count: int = _entry(mesh)["schemes"]
	mesh.set_instance_shader_parameter(&"palette_offset", -float(randi() % count) / count)
	return mesh


static func _entry(mesh: MeshInstance3D) -> Dictionary:
	var source: BaseMaterial3D = mesh.mesh.surface_get_material(0) as BaseMaterial3D
	var palette: Texture2D = source.albedo_texture if source != null else null
	var key: Variant = mesh.mesh
	if palette != null:
		key = palette
	if _by_palette.has(key):
		return _by_palette[key]
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FLASH_SHADER
	material.set_shader_parameter(&"albedo", Color.WHITE)
	var schemes: int = 1
	if palette != null:
		material.set_shader_parameter(&"albedo_texture", palette)
		@warning_ignore("integer_division")
		schemes = maxi(1, palette.get_height() / (palette.get_width() / PALETTE_COLUMNS))
	var entry: Dictionary = {"material": material, "schemes": schemes}
	_by_palette[key] = entry
	return entry
