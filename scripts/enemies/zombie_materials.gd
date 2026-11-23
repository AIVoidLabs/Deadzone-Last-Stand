class_name ZombieMaterials
extends RefCounted
## ZombieVisual'in paylaşılan malzeme ve kutu ağları (statik önbellek): yeni hat köşe renkli malzeme, eski kutu görünümü.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const VC_SHADER: Shader = preload("res://assets/shaders/zombie_vc.gdshader")
const BOX_WIDTH_FACTOR: float = 1.6

static var _box_meshes: Dictionary = {}
static var _materials: Dictionary = {}
static var _vc_material: ShaderMaterial


static func clear_cache() -> void:
	_box_meshes.clear()
	_materials.clear()
	_vc_material = null


## Satırda tint varsa (özel türler, kendi modeli yokken yürüyenin modeli) köşe renginin çarpanı olarak örneğe uygulanır.
static func apply_tint(mesh: MeshInstance3D, row: Dictionary, own_clips: bool, variance: Vector3) -> void:
	if not own_clips or not row.has("tint"):
		return
	var tint: Color = row["tint"]
	mesh.set_instance_shader_parameter(&"tint", Vector3(tint.r * variance.x, tint.g * variance.y, tint.b * variance.z))


static func vc_shared() -> ShaderMaterial:
	if _vc_material == null:
		_vc_material = ShaderMaterial.new()
		_vc_material.shader = VC_SHADER
	return _vc_material


static func box_material(row: Dictionary) -> ShaderMaterial:
	var id: StringName = row["id"]
	if not _materials.has(id):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = FLASH_SHADER
		material.set_shader_parameter(&"albedo", row["color"])
		_materials[id] = material
	return _materials[id]


static func box_mesh(row: Dictionary) -> BoxMesh:
	var id: StringName = row["id"]
	if not _box_meshes.has(id):
		var radius: float = row["radius"]
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(radius * BOX_WIDTH_FACTOR, row["height"], radius * BOX_WIDTH_FACTOR)
		_box_meshes[id] = box
	return _box_meshes[id]
