class_name ZombieVisual
extends Node3D
## Zombi görüntüsü: ortak iskeletli model + animasyon (Tuning.FEATURE_ZOMBIE_MODEL kapalıysa kutu).
## Görünüm (gövde çeşidi + renk şeması) ZombieLook ile rastgele seçilir; vuruş parlaması örnek başına.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
## Tür satırındaki "model" alanı bu tablodan seçilir; her model aynı 25 kemikli iskeleti kullanır.
const MODELS: Dictionary = {
	&"walker": preload("res://assets/models/characters/zombie_walker.glb"),
	&"runner": preload("res://assets/models/characters/zombie_runner.glb"),
	&"tank": preload("res://assets/models/characters/zombie_tank.glb"),
	&"jumper": preload("res://assets/models/characters/zombie_jumper.glb"),
	&"tongue": preload("res://assets/models/characters/zombie_tongue.glb"),
}
const MARKER_SHADER: Shader = preload("res://assets/shaders/jump_marker.gdshader")
const MARKER_HEIGHT: float = 0.03
## Dil: kalınlık (m), uzama süresi (sn), renk.
const TONGUE_THICKNESS: float = 0.08
const TONGUE_EXTEND_TIME: float = 0.12
const TONGUE_COLOR: Color = Color(0.86, 0.2, 0.3)
## Dilin çıktığı ağız yüksekliği (boyun yüzdesi) ve ileri payı (m).
const TONGUE_MOUTH_HEIGHT: float = 0.88
const TONGUE_MOUTH_FORWARD: float = 0.2
## Atılma hazırlığı ve toparlanma: klip bu hızda (yavaş) oynar, çömelme duruşu uzunca okunur.
const HOLD_ANIM_SPEED: float = 0.3
const LUNGE_ANIM_SPEED: float = 1.25
const BOX_WIDTH_FACTOR: float = 1.6

static var _box_meshes: Dictionary = {}
static var _materials: Dictionary = {}

var _meshes: Array[MeshInstance3D] = []
var _animation: AnimationPlayer
var _row: Dictionary = {}
var _body: Zombie
var _flash_left: float = 0.0
var _dying: bool = false
var _death_left: float = 0.0
## Zıplama: geçen ve toplam süre; havadaki yükseklik yalnız görüntüde (fizik gövdesi yerde kalır).
var _jump_age: float = -1.0
var _jump_total: float = 0.0
var _marker: MeshInstance3D
var _marker_age: float = 0.0
var _marker_total: float = 1.0
var _tongue: MeshInstance3D
var _tongue_to: Vector3 = Vector3.ZERO
var _tongue_hold: float = 0.0
var _tongue_age: float = 0.0


func _init(model_kind: StringName = &"walker") -> void:
	if Tuning.FEATURE_ZOMBIE_MODEL:
		_build_model(model_kind)
	else:
		_build_box()
	set_process(false)


func _ready() -> void:
	_body = get_parent() as Zombie
	_body.event.connect(_on_event)
	_body.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_set_flash(0.0)
	if _dying:
		# Sürenin son ZOMBIE_FADE_TIME saniyesinde solar.
		_death_left -= delta
		_set_fade(1.0 - clampf(_death_left / Tuning.ZOMBIE_FADE_TIME, 0.0, 1.0))
	_tick_jump(delta)
	_tick_marker(delta)
	_tick_tongue(delta)
	if not _dying and _flash_left <= 0.0 and _jump_age < 0.0 and not _marker_on() and not _tongue_on():
		set_process(false)


func _on_event(event_name: StringName, data: Dictionary) -> void:
	match event_name:
		&"configure":
			_apply_kind(data)
		&"burn":
			_set_burn(1.0 if data["on"] else 0.0)
		&"marker":
			_on_marker(data)
		&"tongue":
			_on_tongue(data)
		&"hit":
			if Tuning.FEATURE_HIT_FLASH:
				_flash_left = Tuning.HIT_FLASH_TIME
				_set_flash(1.0)
				set_process(true)


func _on_state_changed(new_state: int, old_state: int) -> void:
	if old_state == ZombieRules.State.JUMP and new_state != ZombieRules.State.JUMP:
		_jump_age = -1.0
		position.y = 0.0
	if _dying and new_state != ZombieRules.State.DYING:
		_dying = false
		_set_fade(0.0)
	match new_state:
		ZombieRules.State.DYING:
			_dying = true
			_death_left = _body.state_duration
			set_process(true)
			var clip: StringName = _pick_clip(&"anim_death")
			if clip != &"":
				_animation.speed_scale = Tuning.ZOMBIE_DEATH_ANIM_SPEED
				_animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)
				_animation.seek(0.0)
		ZombieRules.State.SPAWN:
			_play_timed(&"anim_spawn", 0.0, _body.state_duration)
		ZombieRules.State.CHASE:
			_start_walk()
		ZombieRules.State.WINDUP:
			if _is_special():
				_play_loop(&"anim_attack", HOLD_ANIM_SPEED)
			else:
				# Klipteki vuruş anı hazırlığın sonuna denk gelsin.
				_play_timed(&"anim_attack", _row.get("attack_anim_hit_time", 0.0), _body.state_duration)
		ZombieRules.State.LUNGE:
			_play_loop(&"anim_lunge", LUNGE_ANIM_SPEED)
		ZombieRules.State.JUMP:
			_jump_age = 0.0
			_jump_total = maxf(_body.state_duration, 0.01)
			set_process(true)
			_play_loop(&"anim_air", 1.0)
		ZombieRules.State.LASH:
			_play_loop(&"anim_attack", HOLD_ANIM_SPEED)
		ZombieRules.State.STAGGER:
			_play_timed(&"anim_stagger", 0.0, _body.state_duration)
		ZombieRules.State.RECOVER:
			if _is_special():
				_play_loop(&"anim_attack", HOLD_ANIM_SPEED)
			elif _animation != null:
				# Saldırı klibi kendi hızında tamamlanır.
				_animation.speed_scale = 1.0
		ZombieRules.State.INACTIVE:
			_hide_extras()
			_set_burn(0.0)
			_flash_left = 0.0
			_set_flash(0.0)
			set_process(false)
			# Havuzdaki (görünmeyen) zombi animasyon hesaplamasın.
			if _animation != null:
				_animation.stop()


func _set_fade(value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(&"fade", value)


func _set_burn(value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(&"burn", value)


func _set_flash(value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(&"flash", value)


func _build_model(model_kind: StringName) -> void:
	var model: Node3D = (MODELS[model_kind] as PackedScene).instantiate() as Node3D
	add_child(model)
	_meshes.append(ZombieLook.apply_random(model))
	_animation = AnimationPlayer.new()
	model.add_child(_animation)
	var skeleton: Skeleton3D = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	_animation.add_animation_library(ZombieClips.LIBRARY_NAME, ZombieClips.library(skeleton))


func _build_box() -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	add_child(mesh)
	_meshes.append(mesh)


func _apply_kind(row: Dictionary) -> void:
	_row = row
	var height: float = row["height"]
	if _animation == null:
		var box: MeshInstance3D = _meshes[0]
		box.mesh = _box_mesh_for(row)
		box.material_override = _material_for(row)
		box.position.y = height * 0.5
		return
	var size: float = randf_range(1.0 - Tuning.ZOMBIE_SCALE_VARIANCE, 1.0 + Tuning.ZOMBIE_SCALE_VARIANCE)
	scale = Vector3.ONE * (size * height / Tuning.CHARACTER_MODEL_HEIGHT)


## Yürüyüşü rastgele bir kareden ve biraz farklı hızda başlatır; sürü aynı adımda yürümez.
func _start_walk() -> void:
	var clip: StringName = _pick_clip(&"anim_walk")
	if clip == &"":
		return
	var variance: float = Tuning.ZOMBIE_ANIM_SPEED_VARIANCE
	_animation.speed_scale = randf_range(1.0 - variance, 1.0 + variance)
	_animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)
	_animation.seek(randf() * _animation.current_animation_length)


## Klibi baştan oynatır; marker_time (0 ise klibin sonu) tam duration saniyede gelecek hızda.
func _play_timed(row_key: StringName, marker_time: float, duration: float) -> void:
	var clip: StringName = _pick_clip(row_key)
	if clip == &"":
		return
	var span: float = marker_time if marker_time > 0.0 else _animation.get_animation(clip).length
	_animation.speed_scale = span / maxf(duration, 0.01)
	_animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)
	_animation.seek(0.0)


func _is_special() -> bool:
	return not _row.is_empty() and SpecialAttacks.is_special(_row)


func _marker_on() -> bool:
	return _marker != null and _marker.visible


func _tongue_on() -> bool:
	return _tongue != null and _tongue.visible


func _hide_extras() -> void:
	_jump_age = -1.0
	position.y = 0.0
	if _marker != null:
		_marker.visible = false
	if _tongue != null:
		_tongue.visible = false


## Havadaki yükseklik: yay (JumpRules.height_at); zıplama süresi dolunca yerde.
func _tick_jump(delta: float) -> void:
	if _jump_age < 0.0:
		return
	_jump_age += delta
	position.y = JumpRules.height_at(_jump_age / _jump_total, float(_row.get("jump_height", 0.0)))


func _on_marker(data: Dictionary) -> void:
	if not data["on"]:
		if _marker != null:
			_marker.visible = false
		return
	if _marker == null:
		_marker = _make_marker()
	if not _marker.visible:
		_marker_age = 0.0
		_marker_total = float(_row.get("attack_windup", 0.7)) + float(_row.get("jump_time", 0.9))
		_marker.visible = true
		set_process(true)
	var radius: float = float(data["radius"]) + Tuning.PLAYER_RADIUS
	_marker.scale = Vector3(radius, 1.0, radius)
	_marker.global_position = (data["pos"] as Vector3) + Vector3(0.0, MARKER_HEIGHT, 0.0)


func _tick_marker(delta: float) -> void:
	if not _marker_on():
		return
	_marker_age += delta
	var material: ShaderMaterial = _marker.material_override as ShaderMaterial
	material.set_shader_parameter(&"age", _marker_age)
	material.set_shader_parameter(&"urgency", clampf(_marker_age / _marker_total, 0.0, 1.0))


func _make_marker() -> MeshInstance3D:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = MARKER_SHADER
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = plane
	instance.material_override = material
	instance.top_level = true
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visible = false
	add_child(instance)
	return instance


func _on_tongue(data: Dictionary) -> void:
	if data.get("off", false):
		if _tongue != null:
			_tongue.visible = false
		return
	if _tongue == null:
		_tongue = _make_tongue()
	if not _tongue.visible:
		_tongue_age = 0.0
		_tongue.visible = true
		set_process(true)
	_tongue_to = data["to"]
	_tongue_hold = data["hold"]


## Ağızdan hedefe uzanan ince kutu; uzama süresi boyunca kısa başlar, sonra tam boy.
func _tick_tongue(delta: float) -> void:
	if not _tongue_on():
		return
	_tongue_age += delta
	if _tongue_hold > 0.0:
		_tongue_hold -= delta
		if _tongue_hold <= 0.0:
			_tongue.visible = false
			return
	var origin: Vector3 = _body.global_position + Vector3(0.0, float(_row["height"]) * TONGUE_MOUTH_HEIGHT, 0.0)
	origin += _body.global_transform.basis.z * TONGUE_MOUTH_FORWARD
	var length: float = origin.distance_to(_tongue_to) * clampf(_tongue_age / TONGUE_EXTEND_TIME, 0.05, 1.0)
	if length < 0.01:
		return
	var direction: Vector3 = (_tongue_to - origin).normalized()
	var basis: Basis = Basis.looking_at(direction, Vector3.UP) * Basis.from_scale(Vector3(TONGUE_THICKNESS, TONGUE_THICKNESS, length))
	_tongue.global_transform = Transform3D(basis, origin + direction * length * 0.5)


func _make_tongue() -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = TONGUE_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = box
	instance.material_override = material
	instance.top_level = true
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visible = false
	add_child(instance)
	return instance


## Klibi sabit hızda baştan oynatır (süreye uydurmadan).
func _play_loop(row_key: StringName, speed: float) -> void:
	var clip: StringName = _pick_clip(row_key)
	if clip == &"":
		return
	_animation.speed_scale = speed
	_animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)


func _pick_clip(row_key: StringName) -> StringName:
	if _animation == null:
		return &""
	var clips: Array = _row.get(row_key, [])
	if clips.is_empty():
		return &""
	return ZombieClips.full_name(clips.pick_random())


static func _material_for(row: Dictionary) -> ShaderMaterial:
	var id: StringName = row["id"]
	if not _materials.has(id):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = FLASH_SHADER
		material.set_shader_parameter(&"albedo", row["color"])
		_materials[id] = material
	return _materials[id]


static func _box_mesh_for(row: Dictionary) -> BoxMesh:
	var id: StringName = row["id"]
	if not _box_meshes.has(id):
		var radius: float = row["radius"]
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(radius * BOX_WIDTH_FACTOR, row["height"], radius * BOX_WIDTH_FACTOR)
		_box_meshes[id] = box
	return _box_meshes[id]
