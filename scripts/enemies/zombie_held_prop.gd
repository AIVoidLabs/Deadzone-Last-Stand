class_name ZombieHeldProp
extends RefCounted
## Elde taşınan prop (taş fırlatanın kayası; ZombieVisual'in yardımcısı): kemiğe bağlı, hazırlıkta klibin show_time anından
## bırakışa (WINDUP sonu) dek görünür. Satırdaki `held_prop` alanı: bone (kemik adı), offset (kemik yerel ofseti), show_time (klip sn).

const SCENE: PackedScene = preload("res://assets/models/props/thrown_rock.glb")

static var _material: StandardMaterial3D

var _prop: Node3D
## Görünmeye kalan süre (sn); < 0 = beklemiyor.
var _delay: float = -1.0


func setup(skeleton: Skeleton3D, config: Dictionary) -> void:
	var attach: BoneAttachment3D = BoneAttachment3D.new()
	attach.bone_name = config["bone"]
	skeleton.add_child(attach)
	_prop = SCENE.instantiate() as Node3D
	for mesh: Node in _prop.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = _vertex_color_material()
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_prop.position = config["offset"]
	_prop.visible = false
	attach.add_child(_prop)


## Hazırlık başladı: klibin hit_time'ı duration'a uydurulduğundan show_time da aynı oranda ölçeklenir.
func begin(config: Dictionary, duration: float, hit_time: float) -> void:
	_delay = float(config["show_time"]) * duration / maxf(hit_time, 0.01)


## Gizle ve beklemeyi bırak (bırakış, kesilme, ölüm, havuza dönüş).
func reset() -> void:
	_delay = -1.0
	if _prop != null:
		_prop.visible = false


func is_waiting() -> bool:
	return _delay >= 0.0


func tick(delta: float) -> void:
	if _delay < 0.0:
		return
	_delay -= delta
	if _delay <= 0.0:
		_delay = -1.0
		_prop.visible = true


static func _vertex_color_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.albedo_color = Color(0.8, 0.78, 0.76)
		_material.roughness = 0.95
	return _material
