class_name PlayerVisual
extends Node3D
## Askerin görüntüsü: ortak iskeletli model + animasyon (Tuning.FEATURE_PLAYER_MODEL kapalıysa kapsül).
## Gövdeyi yalnız okur; gövde buraya dokunmaz.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const MODEL: PackedScene = preload("res://assets/models/characters/soldier.glb")
const ANIM_LIBRARY_NAME: StringName = &"ual1"
const ANIM_LIBRARY: AnimationLibrary = preload("res://assets/models/anim/ual1.glb")
## Durum -> klip. Koşu klibinin hızı gerçek hıza oranlanır (ayak kaymasın).
const STATE_CLIPS: Dictionary = {
	Player.State.IDLE: &"ual1/Idle",
	Player.State.MOVE: &"ual1/Sprint",
	Player.State.DEAD: &"ual1/Death01",
}
const BODY_COLOR: Color = Color(0.25, 0.42, 0.7)
const VISOR_COLOR: Color = Color(0.95, 0.75, 0.25)
const HURT_COLOR: Color = Color(1.0, 0.25, 0.2)
const DEAD_SQUASH: float = 0.25

var _player: Player
var _meshes: Array[MeshInstance3D] = []
var _animation: AnimationPlayer
var _blink_left: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player
	if Tuning.FEATURE_PLAYER_MODEL:
		_build_model()
	else:
		_build_capsule()
	_player.event.connect(_on_event)
	_player.state_changed.connect(_on_state_changed)
	_play_state(_player.state)


func _process(delta: float) -> void:
	var target_yaw: float = atan2(_player.facing.x, _player.facing.y)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-Tuning.PLAYER_TURN_SHARPNESS * delta))
	_sync_run_speed()
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
	_play_state(new_state)
	if new_state == Player.State.DEAD:
		_blink_left = 0.0
		_set_flash(0.0 if _animation != null else 1.0)
		if _animation == null:
			scale = Vector3(1.0, DEAD_SQUASH, 1.0)


func _play_state(state: int) -> void:
	if _animation == null or not STATE_CLIPS.has(state):
		return
	_animation.speed_scale = 1.0
	_animation.play(STATE_CLIPS[state], Tuning.PLAYER_ANIM_BLEND)


func _sync_run_speed() -> void:
	if _animation == null or _player.state != Player.State.MOVE:
		return
	var planar_speed: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	_animation.speed_scale = planar_speed / Tuning.PLAYER_SPEED


func _set_flash(value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(&"flash", value)


func _build_model() -> void:
	var model: Node3D = MODEL.instantiate() as Node3D
	add_child(model)
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		mesh.material_override = _flash_material(Color.WHITE, _albedo_texture_of(mesh))
		_meshes.append(mesh)
	_animation = AnimationPlayer.new()
	model.add_child(_animation)
	_animation.add_animation_library(ANIM_LIBRARY_NAME, ANIM_LIBRARY)


func _build_capsule() -> void:
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = Tuning.PLAYER_RADIUS
	capsule.height = Tuning.PLAYER_HEIGHT
	var body: MeshInstance3D = _add_mesh(capsule, BODY_COLOR)
	body.position.y = Tuning.PLAYER_HEIGHT * 0.5
	_meshes.append(body)
	var visor_box: BoxMesh = BoxMesh.new()
	visor_box.size = Vector3(Tuning.PLAYER_RADIUS * 1.4, 0.18, 0.2)
	var visor: MeshInstance3D = _add_mesh(visor_box, VISOR_COLOR)
	visor.position = Vector3(0.0, Tuning.PLAYER_HEIGHT * 0.78, Tuning.PLAYER_RADIUS * 0.85)


func _add_mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _flash_material(color, null)
	add_child(instance)
	return instance


func _flash_material(color: Color, texture: Texture2D) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FLASH_SHADER
	material.set_shader_parameter(&"albedo", color)
	material.set_shader_parameter(&"flash_color", HURT_COLOR)
	if texture != null:
		material.set_shader_parameter(&"albedo_texture", texture)
	return material


func _albedo_texture_of(mesh: MeshInstance3D) -> Texture2D:
	var source: BaseMaterial3D = mesh.mesh.surface_get_material(0) as BaseMaterial3D
	return source.albedo_texture if source != null else null
