class_name DamageNumbers
extends Node3D
## Zombinin üstünde yükselip sönen hasar sayıları. Sabit Label3D havuzu, en eski yeniden kullanılır.
## Öldüren vuruşun sayısı daha büyük ve sıcak renkli.

const POOL_SIZE: int = 48
const HEIGHT: float = 1.9
const JITTER: float = 0.35
const RISE: float = 0.9
const LIFETIME: float = 0.65
const POP_TIME: float = 0.08
const POP_SCALE: float = 1.5
const FONT_SIZE: int = 56
const OUTLINE_SIZE: int = 14
const PIXEL_SIZE: float = 0.0042
const KILL_SCALE: float = 1.35
const HIT_COLOR: Color = Color(1.0, 0.97, 0.9)
const KILL_COLOR: Color = Color(1.0, 0.68, 0.2)
const OUTLINE_COLOR: Color = Color(0.08, 0.05, 0.05)

var _labels: Array[Label3D] = []
var _start: PackedVector3Array = PackedVector3Array()
var _age: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0


func _ready() -> void:
	name = "DamageNumbers"
	for _i in POOL_SIZE:
		var label: Label3D = Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.fixed_size = false
		label.pixel_size = PIXEL_SIZE
		label.font_size = FONT_SIZE
		label.outline_size = OUTLINE_SIZE
		label.outline_modulate = OUTLINE_COLOR
		label.render_priority = 10
		label.outline_render_priority = 9
		label.visible = false
		add_child(label)
		_labels.append(label)
		_start.append(Vector3.ZERO)
		_age.append(-1.0)
		_size.append(1.0)


func _process(delta: float) -> void:
	for i: int in _labels.size():
		if _age[i] < 0.0:
			continue
		_age[i] += delta
		var t: float = _age[i] / LIFETIME
		var label: Label3D = _labels[i]
		if t >= 1.0:
			_age[i] = -1.0
			label.visible = false
			continue
		# Hızlı yükselip yavaşlar; başta kısa bir büyüme, son yarıda söner.
		label.position = _start[i] + Vector3.UP * RISE * (1.0 - pow(1.0 - t, 3.0))
		var pop: float = lerpf(POP_SCALE, 1.0, clampf(_age[i] / POP_TIME, 0.0, 1.0))
		label.scale = Vector3.ONE * pop * _size[i]
		label.modulate.a = 1.0 - smoothstep(0.5, 1.0, t)
		label.outline_modulate.a = label.modulate.a


func on_enemy_damaged(at: Vector3, _direction: Vector2, amount: float, killed: bool) -> void:
	var i: int = _next
	_next = (_next + 1) % _labels.size()
	var label: Label3D = _labels[i]
	label.text = str(roundi(amount))
	label.modulate = KILL_COLOR if killed else HIT_COLOR
	label.outline_modulate = OUTLINE_COLOR
	_size[i] = KILL_SCALE if killed else 1.0
	_start[i] = at + Vector3(randf_range(-JITTER, JITTER), HEIGHT, randf_range(-JITTER, JITTER))
	_age[i] = 0.0
	label.position = _start[i]
	label.visible = true
