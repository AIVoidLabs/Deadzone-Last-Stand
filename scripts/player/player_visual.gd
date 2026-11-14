class_name PlayerVisual
extends Node3D
## Askerin görüntüsü (şimdilik kapsül + vizör). Aşama 4'te model buraya takılır.
## Gövdeyi yalnız okur; gövde buraya dokunmaz.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const BODY_COLOR: Color = Color(0.25, 0.42, 0.7)
const VISOR_COLOR: Color = Color(0.95, 0.75, 0.25)
const HURT_COLOR: Color = Color(1.0, 0.25, 0.2)
const DEAD_SQUASH: float = 0.25

var _player: Player
var _body: MeshInstance3D
var _visor: MeshInstance3D
var _blink_left: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player
	_body = _make_mesh(_capsule_mesh(), BODY_COLOR)
	_body.position.y = Tuning.PLAYER_HEIGHT * 0.5
	_visor = _make_mesh(_visor_mesh(), VISOR_COLOR)
	_visor.position = Vector3(0.0, Tuning.PLAYER_HEIGHT * 0.78, Tuning.PLAYER_RADIUS * 0.85)
	_player.event.connect(_on_event)
	_player.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	var target_yaw: float = atan2(_player.facing.x, _player.facing.y)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-Tuning.PLAYER_TURN_SHARPNESS * delta))
	if _blink_left > 0.0:
		_blink_left -= delta
		var on: bool = fmod(_blink_left * Tuning.PLAYER_BLINK_RATE, 2.0) > 1.0
		_set_flash(1.0 if on and _blink_left > 0.0 else 0.0)


func _on_event(event_name: StringName, data: Dictionary) -> void:
	if event_name == &"hit" and Tuning.FEATURE_HIT_FLASH:
		var iframes: float = data.get("iframes", Tuning.HIT_FLASH_TIME)
		_blink_left = maxf(iframes, Tuning.HIT_FLASH_TIME)
		_set_flash(1.0)


func _on_state_changed(new_state: int, _old_state: int) -> void:
	if new_state == Player.State.DEAD:
		_blink_left = 0.0
		_set_flash(1.0)
		scale = Vector3(1.0, DEAD_SQUASH, 1.0)


func _set_flash(value: float) -> void:
	_body.set_instance_shader_parameter(&"flash", value)


func _make_mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = FLASH_SHADER
	mat.set_shader_parameter(&"albedo", color)
	mat.set_shader_parameter(&"flash_color", HURT_COLOR)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	return mi


func _capsule_mesh() -> CapsuleMesh:
	var m: CapsuleMesh = CapsuleMesh.new()
	m.radius = Tuning.PLAYER_RADIUS
	m.height = Tuning.PLAYER_HEIGHT
	return m


func _visor_mesh() -> BoxMesh:
	var m: BoxMesh = BoxMesh.new()
	m.size = Vector3(Tuning.PLAYER_RADIUS * 1.4, 0.18, 0.2)
	return m
