class_name CityPropsBuilder
extends Node3D
## CityProps tablosundan prop örnekler (8.1f). Aynı glb bir kez yüklenir; çarpışmalı satırlara kutu StaticBody3D eklenir.
## Kapatma: Tuning.FEATURE_CITY_PROPS (CityGreybox bu düğümü o zaman eklemez).

var _scenes: Dictionary = {}
var _fixed: Dictionary = {}   # özgün malzeme -> köşe rengi açık kopya


func _ready() -> void:
	name = "CityProps"
	for row: Dictionary in CityProps.rows():
		_place(row)


func _scene(prop: StringName) -> PackedScene:
	if not _scenes.has(prop):
		_scenes[prop] = load(CityProps.DIR % prop) as PackedScene
	return _scenes[prop]


func _place(row: Dictionary) -> void:
	var prop: StringName = row["prop"]
	var scene: PackedScene = _scene(prop)
	if scene == null:
		push_warning("CityProps: model yok: %s" % prop)
		return
	var node: Node3D = scene.instantiate() as Node3D
	var pos: Vector2 = row["pos"]
	node.position = Vector3(pos.x, row.get("y", 0.0), pos.y)
	node.rotation_degrees = Vector3(row.get("tilt", 0.0), row["rot_y"], 0.0)
	node.scale = Vector3.ONE * float(row.get("scale", 1.0))
	if CityProps.NO_SHADOW.has(prop):
		_disable_shadows(node)
	if Tuning.FEATURE_CITY_PROP_COLORS:
		_fix_materials(node)
	add_child(node)
	if row["collide"] and CityProps.FOOT.has(prop):
		_add_collision(row)


## Godot GLB'deki wreck_body malzemesinde köşe rengini albedo'ya çarpmıyor (kök neden: prop'lar bembeyaz görünüyordu);
## açıp parlamayı kısarız. Özgün malzeme başına tek kopya paylaşılır.
func _fix_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var inst: MeshInstance3D = node as MeshInstance3D
		for i: int in inst.mesh.get_surface_count():
			var mat: BaseMaterial3D = inst.mesh.surface_get_material(i) as BaseMaterial3D
			if mat != null:
				inst.set_surface_override_material(i, _fixed_material(mat))
	for child: Node in node.get_children():
		_fix_materials(child)


func _fixed_material(mat: BaseMaterial3D) -> BaseMaterial3D:
	if not _fixed.has(mat):
		var copy: BaseMaterial3D = mat.duplicate() as BaseMaterial3D
		copy.vertex_color_use_as_albedo = true
		copy.metallic_specular = Tuning.CITY_PROP_SPECULAR
		_fixed[mat] = copy
	return _fixed[mat]


func _disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_disable_shadows(child)


func _add_collision(row: Dictionary) -> void:
	var foot: Vector3 = CityProps.FOOT[row["prop"]]
	var pos: Vector2 = row["pos"]
	var body: StaticBody3D = StaticBody3D.new()
	body.position = Vector3(pos.x, foot.y * 0.5, pos.y)
	body.rotation_degrees.y = row["rot_y"]
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = foot
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
