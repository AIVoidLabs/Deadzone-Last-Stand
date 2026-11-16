class_name ZombieVisual
extends Node3D
## Zombi görüntüsü: ortak iskeletli model + animasyon (Tuning.FEATURE_ZOMBIE_MODEL kapalıysa kutu).
## Görünüm (gövde çeşidi + renk şeması) ZombieLook ile rastgele seçilir; vuruş parlaması örnek başına.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const MODEL: PackedScene = preload("res://assets/models/characters/zombie_walker.glb")
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


func _init() -> void:
	if Tuning.FEATURE_ZOMBIE_MODEL:
		_build_model()
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
	elif _flash_left <= 0.0:
		set_process(false)


func _on_event(event_name: StringName, data: Dictionary) -> void:
	match event_name:
		&"configure":
			_apply_kind(data)
		&"hit":
			if Tuning.FEATURE_HIT_FLASH:
				_flash_left = Tuning.HIT_FLASH_TIME
				_set_flash(1.0)
				set_process(true)


func _on_state_changed(new_state: int, _old_state: int) -> void:
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
			# Klipteki vuruş anı hazırlığın sonuna denk gelsin.
			_play_timed(&"anim_attack", _row.get("attack_anim_hit_time", 0.0), _body.state_duration)
		ZombieRules.State.STAGGER:
			_play_timed(&"anim_stagger", 0.0, _body.state_duration)
		ZombieRules.State.RECOVER:
			# Saldırı klibi kendi hızında tamamlanır.
			if _animation != null:
				_animation.speed_scale = 1.0
		ZombieRules.State.INACTIVE:
			_flash_left = 0.0
			_set_flash(0.0)
			set_process(false)
			# Havuzdaki (görünmeyen) zombi animasyon hesaplamasın.
			if _animation != null:
				_animation.stop()


func _set_fade(value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(&"fade", value)


func _set_flash(value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(&"flash", value)


func _build_model() -> void:
	var model: Node3D = MODEL.instantiate() as Node3D
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
