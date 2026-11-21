class_name PlayerVisual
extends Node3D
## Askerin görüntüsü: ortak iskeletli model + animasyon (Tuning.FEATURE_PLAYER_MODEL kapalıysa kapsül).
## Gövdeyi yalnız okur; gövde buraya dokunmaz.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const MODEL: PackedScene = preload("res://assets/models/characters/soldier.glb")
const BODY_COLOR: Color = Color(0.25, 0.42, 0.7)
const VISOR_COLOR: Color = Color(0.95, 0.75, 0.25)
const HURT_COLOR: Color = Color(1.0, 0.25, 0.2)
const DEAD_SQUASH: float = 0.25

var _player: Player
## Yatma bu düğüme uygulanır; yön (yaw) bu sınıfın kendisinde.
var _pivot: Node3D
var _meshes: Array[MeshInstance3D] = []
var _animator: PlayerAnimator
var _move_blend: float = 0.0
var _blink_left: float = 0.0
var _dust: CPUParticles3D
var _lamp: OmniLight3D


func _ready() -> void:
	_player = get_parent() as Player
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	if Tuning.FEATURE_PLAYER_MODEL:
		_build_model()
	else:
		_build_capsule()
	if Tuning.FEATURE_DASH_DUST:
		_dust = DashDust.create()
		add_child(_dust)
	_build_rim_light()
	_player.event.connect(_on_event)
	_player.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	var target_yaw: float = atan2(_player.facing.x, _player.facing.y)
	var yaw_error: float = angle_difference(rotation.y, target_yaw)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-Tuning.PLAYER_TURN_SHARPNESS * delta))
	_update_lean(yaw_error, delta)
	_update_locomotion(delta)
	_update_struggle_shake()
	if _blink_left > 0.0:
		_blink_left -= delta
		var on: bool = fmod(_blink_left * Tuning.PLAYER_BLINK_RATE, 2.0) > 1.0
		_set_flash(1.0 if on and _blink_left > 0.0 else 0.0)


func _on_event(event_name: StringName, data: Dictionary) -> void:
	if event_name == &"dash_started":
		_on_dash_started()
		return
	if event_name == &"dash_ended":
		_set_dust(false)
		return
	if event_name == &"rooted":
		if _animator != null:
			_animator.play_struggle()
		return
	if event_name == &"released":
		if _animator != null:
			_animator.release(data.get("broke_free", true))
		return
	if event_name != &"hit":
		return
	if _animator != null:
		_animator.play_hit()
	if Tuning.FEATURE_HIT_FLASH:
		var iframes: float = data.get("iframes", Tuning.HIT_FLASH_TIME)
		_blink_left = maxf(iframes, Tuning.HIT_FLASH_TIME)
		_set_flash(1.0)


func _on_state_changed(new_state: int, _old_state: int) -> void:
	if new_state != Player.State.DEAD:
		return
	_blink_left = 0.0
	if _animator != null:
		_animator.set_dead(true)
		_set_flash(0.0)
	else:
		_set_flash(1.0)
		scale = Vector3(1.0, DEAD_SQUASH, 1.0)


func _on_dash_started() -> void:
	if _animator != null:
		_animator.set_roll_duration(Tuning.DASH_ROLL_ANIM_TIME)
		_animator.play_roll()
	_set_dust(true)


func _set_dust(emitting: bool) -> void:
	if _dust != null:
		_dust.emitting = emitting


## Bağlıyken gövde hızlıca titrer (çırpınma); serbestken yerine döner.
func _update_struggle_shake() -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	var shaking: bool = _player.is_rooted() and not Tuning.FEATURE_PLAYER_DRAG_CLIPS
	var strength: float = Tuning.PLAYER_STRUGGLE_SHAKE if shaking else 0.0
	_pivot.position.x = sin(t * Tuning.PLAYER_STRUGGLE_RATE) * strength
	_pivot.position.z = cos(t * Tuning.PLAYER_STRUGGLE_RATE * 0.83) * strength * 0.6


func _update_locomotion(delta: float) -> void:
	if _animator == null:
		return
	var speed: float = _player.planar_speed() if _player.state != Player.State.DEAD else 0.0
	speed = minf(speed, Tuning.PLAYER_SPEED)
	var target: float = clampf(speed / Tuning.PLAYER_SPEED, 0.0, 1.0)
	_move_blend = lerpf(_move_blend, target, 1.0 - exp(-Tuning.PLAYER_ANIM_MOVE_SHARPNESS * delta))
	_animator.set_locomotion(_move_blend, speed / Tuning.PLAYER_RUN_ANIM_SPEED)


func _update_lean(yaw_error: float, delta: float) -> void:
	var forward: float = 0.0
	var side: float = 0.0
	if Tuning.FEATURE_PLAYER_LEAN and _player.state != Player.State.DEAD and not _player.is_dashing():
		forward = Locomotion.forward_lean(_player.planar_speed(), Tuning.PLAYER_SPEED, deg_to_rad(Tuning.PLAYER_LEAN_FORWARD_DEG))
		side = Locomotion.turn_lean(yaw_error, Tuning.PLAYER_LEAN_TURN_GAIN, deg_to_rad(Tuning.PLAYER_LEAN_TURN_DEG))
	var weight: float = 1.0 - exp(-Tuning.PLAYER_LEAN_SHARPNESS * delta)
	# Model +Z'ye bakar: +X ekseninde dönüş öne yatırır; sola dönüşte (yaw artar) sola yatmak için -Z.
	_pivot.rotation.x = lerpf(_pivot.rotation.x, forward, weight)
	_pivot.rotation.z = lerpf(_pivot.rotation.z, -side, weight)


## 8.3a: askerin üstünde zayıf sıcak ışık (gölgesiz) ve malzemelerde kenar ışığı; profilden.
func _build_rim_light() -> void:
	if not Tuning.FEATURE_CHARACTER_RIM:
		return
	_lamp = OmniLight3D.new()
	_lamp.name = "PlayerLamp"
	_lamp.position = Vector3(0.0, Tuning.PLAYER_LIGHT_HEIGHT, 0.0)
	_lamp.light_color = Tuning.PLAYER_LIGHT_COLOR
	_lamp.light_energy = Tuning.PLAYER_LIGHT_ENERGY
	_lamp.omni_range = Tuning.PLAYER_LIGHT_RANGE
	_lamp.shadow_enabled = false
	add_child(_lamp)
	Quality.profile_changed.connect(func(_id: StringName) -> void: _refresh_rim())
	_refresh_rim()


func _refresh_rim() -> void:
	_lamp.visible = CityAtmosphere.rim_active()
	for mesh: MeshInstance3D in _meshes:
		CityAtmosphere.apply_rim(mesh.material_override as ShaderMaterial)


func _set_flash(value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(&"flash", value)


func _build_model() -> void:
	var model: Node3D = MODEL.instantiate() as Node3D
	_pivot.add_child(model)
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		mesh.material_override = _flash_material(Tuning.PLAYER_ALBEDO_TINT, _albedo_texture_of(mesh))
		_meshes.append(mesh)
	_animator = PlayerAnimator.new(model)


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
	_pivot.add_child(instance)
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
