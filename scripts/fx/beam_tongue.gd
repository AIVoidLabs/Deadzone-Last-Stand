class_name BeamTongue
extends MeshInstance3D
## Eski kutu dil (Tuning.FEATURE_DILCI_MODEL kapalıyken): ağızdan hedefe uzanan ince kutu.
## Olay sözleşmesi DilciTongue ile aynı (SpecialAttacks yayar): shoot / attach / to / off.

const THICKNESS: float = 0.08
const COLOR: Color = Color(0.86, 0.2, 0.3)
## Ağız yüksekliği (boy yüzdesi) ve ileri payı (m).
const MOUTH_HEIGHT: float = 0.88
const MOUTH_FORWARD: float = 0.2

var _body: Node3D
var _height: float = 1.7
var _to: Vector3 = Vector3.ZERO
var _age: float = 0.0
var _extend: float = 0.12
## Ulaştıktan sonra bu kadar görünür kalır (sn); eksi = olay gelene dek.
var _hold: float = -1.0


func _init() -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh = box
	material_override = material
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false
	set_process(false)


func setup(body: Node3D, height: float) -> void:
	_body = body
	_height = height


func on_event(data: Dictionary) -> void:
	if data.get("off", false):
		hide_now()
		return
	_to = data.get("to", _to)
	if data.get("shoot", false):
		_age = 0.0
		_extend = maxf(float(data.get("time", 0.12)), 0.01)
		_hold = float(data.get("hold", -1.0))
		visible = true
		set_process(true)


func on_state(new_state: int, _old_state: int) -> void:
	if new_state == ZombieRules.State.INACTIVE or new_state == ZombieRules.State.DYING:
		hide_now()


func hide_now() -> void:
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_age += delta
	if _hold >= 0.0 and _age > _extend + _hold:
		hide_now()
		return
	var origin: Vector3 = _body.global_position + Vector3(0.0, _height * MOUTH_HEIGHT, 0.0)
	origin += _body.global_transform.basis.z * MOUTH_FORWARD
	var length: float = origin.distance_to(_to) * clampf(_age / _extend, 0.05, 1.0)
	if length < 0.01:
		return
	var direction: Vector3 = (_to - origin).normalized()
	var basis_scaled: Basis = Basis.looking_at(direction, Vector3.UP) * Basis.from_scale(Vector3(THICKNESS, THICKNESS, length))
	global_transform = Transform3D(basis_scaled, origin + direction * length * 0.5)
