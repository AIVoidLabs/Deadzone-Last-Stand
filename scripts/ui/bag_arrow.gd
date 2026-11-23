class_name BagArrow
extends CanvasLayer
## Ekran dışındaki ödül çantası için kenarda türün renginde küçük ok. Yalnız çanta varken ve ekran dışındayken görünür.

const LAYER_INDEX: int = 1

var bags: RewardBags

var _root: Control
var _arrow: Polygon2D


func _ready() -> void:
	name = "BagArrow"
	layer = LAYER_INDEX
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var s: float = Tuning.BAG_ARROW_SIZE
	_arrow = Polygon2D.new()
	_arrow.polygon = PackedVector2Array([Vector2(s, 0.0), Vector2(-s * 0.6, -s * 0.7), Vector2(-s * 0.25, 0.0), Vector2(-s * 0.6, s * 0.7)])
	_arrow.visible = false
	_root.add_child(_arrow)


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if bags == null or camera == null or not bags.is_active():
		_arrow.visible = false
		return
	var size: Vector2 = _root.size
	var world: Vector3 = bags.bag_world_position()
	var screen: Vector2 = camera.unproject_position(world)
	if camera.is_position_behind(world):
		screen = size - screen
	var placement: Dictionary = BagRules.arrow_placement(screen, size, Tuning.BAG_ARROW_MARGIN)
	_arrow.visible = placement["visible"]
	if _arrow.visible:
		_arrow.position = placement["pos"]
		_arrow.rotation = placement["angle"]
		_arrow.color = BagRules.color_of(bags.bag_kind())
