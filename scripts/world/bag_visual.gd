class_name BagVisual
extends RefCounted
## Ödül çantasının görünümü tek yerden kurulur (mantıktan ayrı). Şimdilik yer tutucu: torba + boyun + düğüm + ön işaret
## (para: sikke, XP: elmas). FEATURE_BAG_MODEL açıkken ve GLB varsa onu yükler; tür rengi "BagTint" adlı malzemeye verilir.

const TINT_MATERIAL: StringName = &"BagTint"


## Süzülüp dönen çanta gövdesi (yerden yukarı ötelemeyi çağıran yapar).
static func build(kind: StringName) -> Node3D:
	var color: Color = BagRules.color_of(kind)
	if Tuning.FEATURE_BAG_MODEL and ResourceLoader.exists(Tuning.BAG_MODEL_PATH):
		var scene: PackedScene = load(Tuning.BAG_MODEL_PATH) as PackedScene
		if scene != null:
			var model: Node3D = scene.instantiate() as Node3D
			if model != null:
				model.scale = Vector3.ONE * Tuning.BAG_SCALE
				_tint(model, color)
				return model
	return _placeholder(kind, color)


## Zemindeki soluk halka ve hafif ışık (türün renginde); çantayla birlikte süzülmez.
static func build_marker(kind: StringName) -> Node3D:
	var color: Color = BagRules.color_of(kind)
	var root: Node3D = Node3D.new()
	root.name = "BagMarker"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = Tuning.BAG_RING_RADIUS - 0.05
	torus.outer_radius = Tuning.BAG_RING_RADIUS
	torus.rings = 32
	torus.ring_segments = 6
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.mesh = torus
	ring.scale = Vector3(1.0, 0.05, 1.0)
	ring.position.y = 0.04
	ring.material_override = _glow_material(Color(color.r, color.g, color.b, 0.45), 1.2)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = Tuning.BAG_RING_RADIUS
	disc.bottom_radius = Tuning.BAG_RING_RADIUS
	disc.height = 0.01
	disc.radial_segments = 32
	disc.rings = 1
	var fill: MeshInstance3D = MeshInstance3D.new()
	fill.mesh = disc
	fill.position.y = 0.03
	fill.material_override = _glow_material(Color(color.r, color.g, color.b, 0.12), 0.0)
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(fill)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = color
	light.light_energy = Tuning.BAG_LIGHT_ENERGY
	light.omni_range = Tuning.BAG_LIGHT_RANGE
	light.position.y = Tuning.BAG_HOVER_HEIGHT
	light.shadow_enabled = false
	light.visible = Quality.get_value("bag_light")
	root.add_child(light)
	return root


static func _placeholder(kind: StringName, color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BagBody"
	root.scale = Vector3.ONE * Tuning.BAG_SCALE
	var cloth: StandardMaterial3D = _solid_material(color, 0.5)
	var dark: StandardMaterial3D = _solid_material(color.darkened(0.45), 0.2)
	var light: StandardMaterial3D = _solid_material(color.lerp(Color.WHITE, 0.55), 0.9)
	var sack: SphereMesh = SphereMesh.new()
	sack.radius = 0.3
	sack.height = 0.5
	sack.radial_segments = 20
	sack.rings = 10
	_add(root, sack, cloth, Vector3(0.0, 0.0, 0.0))
	var neck: CylinderMesh = CylinderMesh.new()
	neck.top_radius = 0.1
	neck.bottom_radius = 0.17
	neck.height = 0.16
	neck.radial_segments = 12
	_add(root, neck, cloth, Vector3(0.0, 0.3, 0.0))
	var tie: TorusMesh = TorusMesh.new()
	tie.inner_radius = 0.08
	tie.outer_radius = 0.13
	tie.rings = 14
	tie.ring_segments = 6
	_add(root, tie, dark, Vector3(0.0, 0.34, 0.0))
	var tuft: CylinderMesh = CylinderMesh.new()
	tuft.top_radius = 0.16
	tuft.bottom_radius = 0.06
	tuft.height = 0.1
	tuft.radial_segments = 12
	_add(root, tuft, cloth, Vector3(0.0, 0.43, 0.0))
	if kind == BagRules.KIND_MONEY:
		var coin: CylinderMesh = CylinderMesh.new()
		coin.top_radius = 0.12
		coin.bottom_radius = 0.12
		coin.height = 0.04
		coin.radial_segments = 16
		var coin_node: MeshInstance3D = _add(root, coin, light, Vector3(0.0, -0.02, 0.27))
		coin_node.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	else:
		var gem: SphereMesh = SphereMesh.new()
		gem.radius = 0.12
		gem.height = 0.26
		gem.radial_segments = 4
		gem.rings = 2
		_add(root, gem, light, Vector3(0.0, -0.02, 0.28))
	return root


static func _add(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


static func _solid_material(color: Color, glow: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = glow
	return material


static func _glow_material(color: Color, glow: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.render_priority = 1
	if glow > 0.0:
		material.albedo_color = Color(color.r * glow, color.g * glow, color.b * glow, color.a)
	return material


## GLB'de adı BagTint olan malzemeyi türün rengine boyar (kopya; paylaşılan kaynak bozulmaz).
static func _tint(model: Node, color: Color) -> void:
	for found: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = found as MeshInstance3D
		for surface in mesh_node.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh_node.get_active_material(surface) as StandardMaterial3D
			if material != null and material.resource_name == TINT_MATERIAL:
				var copy: StandardMaterial3D = material.duplicate() as StandardMaterial3D
				copy.albedo_color = color
				copy.emission_enabled = true
				copy.emission = color
				copy.emission_energy_multiplier = Tuning.BAG_CRYSTAL_GLOW
				mesh_node.set_surface_override_material(surface, copy)
