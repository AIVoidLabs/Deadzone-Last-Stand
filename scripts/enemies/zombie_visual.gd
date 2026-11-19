class_name ZombieVisual
extends Node3D
## Zombi görüntüsü: ortak iskeletli model + animasyon (Tuning.FEATURE_ZOMBIE_MODEL kapalıysa kutu).
## Görünüm (gövde çeşidi + renk şeması) ZombieLook ile rastgele seçilir; vuruş parlaması örnek başına.
## Yeni hat (VC_MODELS, Aşama V): Blender'da üretilen köşe renkli model, kendi klipleriyle.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
## Tür satırındaki "model" alanı bu tablodan seçilir; her model aynı 25 kemikli iskeleti kullanır.
const MODELS: Dictionary = {
	&"walker": preload("res://assets/models/characters/zombie_walker.glb"),
	&"runner": preload("res://assets/models/characters/zombie_runner.glb"),
	&"tank": preload("res://assets/models/characters/zombie_tank.glb"),
	&"jumper": preload("res://assets/models/characters/zombie_jumper.glb"),
	&"tongue": preload("res://assets/models/characters/zombie_tongue.glb"),
}
## Yeni hat modelleri: renk köşelerde (VC_SHADER), klipler dosyanın kendi AnimationPlayer'ında;
## satırdaki anim_* adları bu kliplerdir. Birden çok ağ = çeşit (ModelVariants).
const VC_MODELS: Dictionary = {
	&"dilci": preload("res://assets/models/characters/zombie_dilci.glb"),
}
const VC_SHADER: Shader = preload("res://assets/shaders/zombie_vc.gdshader")
## Örnek başına hafif ton farkı (±); sürüde aynı ağ aynı görünmesin.
const VC_TINT_VARIANCE: float = 0.08
## Atılma hazırlığı ve toparlanma: klip bu hızda (yavaş) oynar, çömelme duruşu uzunca okunur.
const HOLD_ANIM_SPEED: float = 0.3
const LUNGE_ANIM_SPEED: float = 1.25
const BOX_WIDTH_FACTOR: float = 1.6

static var _box_meshes: Dictionary = {}
static var _materials: Dictionary = {}
static var _vc_material: ShaderMaterial

var _meshes: Array[MeshInstance3D] = []
var _clips: ZombieClipPlayer = ZombieClipPlayer.new()
var _body: Zombie
var _flash_left: float = 0.0
var _dying: bool = false
var _death_left: float = 0.0
## Zıplama: geçen ve toplam süre; havadaki yükseklik yalnız görüntüde (fizik gövdesi yerde kalır).
var _jump_age: float = -1.0
var _jump_total: float = 0.0
var _marker: ZombieJumpMarker
var _model_height: float = Tuning.CHARACTER_MODEL_HEIGHT
var _skeleton: Skeleton3D
## Dil görüntüsü (yalnız dilci): DilciTongue (yeni model) ya da BeamTongue (eski kutu).
var _tongue: Node


func _init(model_kind: StringName = &"walker") -> void:
	_marker = ZombieJumpMarker.new(self)
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
	_marker.tick(delta)
	if not _dying and _flash_left <= 0.0 and _jump_age < 0.0 and not _marker.is_on():
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
			if _tongue != null:
				_tongue.on_event(data)
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
	if _tongue != null:
		_tongue.on_state(new_state, old_state)
	match new_state:
		ZombieRules.State.DYING:
			_dying = true
			_death_left = _body.state_duration
			set_process(true)
			var clip: StringName = _clips.pick_clip(&"anim_death")
			if clip != &"":
				_clips.animation.speed_scale = Tuning.ZOMBIE_DEATH_ANIM_SPEED
				_clips.animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)
				_clips.animation.seek(0.0)
		ZombieRules.State.SPAWN:
			_clips.play_timed(&"anim_spawn", 0.0, _body.state_duration)
		ZombieRules.State.CHASE:
			_clips.start_walk()
		ZombieRules.State.WINDUP:
			if _clips.own_clips:
				# Elle anahtarlanmış hazırlık klibi hazırlık süresine sığar.
				_clips.play_timed(&"anim_attack", 0.0, _body.state_duration)
			elif _is_special():
				_clips.play_loop(&"anim_attack", HOLD_ANIM_SPEED)
			else:
				# Klipteki vuruş anı hazırlığın sonuna denk gelsin.
				_clips.play_timed(&"anim_attack", _clips.row.get("attack_anim_hit_time", 0.0), _body.state_duration)
		ZombieRules.State.LUNGE:
			_clips.play_loop(&"anim_lunge", LUNGE_ANIM_SPEED)
		ZombieRules.State.JUMP:
			_jump_age = 0.0
			_jump_total = maxf(_body.state_duration, 0.01)
			set_process(true)
			_clips.play_loop(&"anim_air", 1.0)
		ZombieRules.State.LASH:
			if _clips.own_clips:
				_clips.play_lash()
			else:
				_clips.play_loop(&"anim_attack", HOLD_ANIM_SPEED)
		ZombieRules.State.PULL:
			if _clips.own_clips:
				_clips.play_loop(&"anim_pull", 1.0)
			else:
				_clips.play_loop(&"anim_attack", HOLD_ANIM_SPEED)
		ZombieRules.State.STAGGER:
			_clips.play_timed(&"anim_stagger", 0.0, _body.state_duration)
		ZombieRules.State.RECOVER:
			if _clips.own_clips:
				_clips.play_loop(&"anim_idle", 1.0)
			elif _is_special():
				_clips.play_loop(&"anim_attack", HOLD_ANIM_SPEED)
			elif _clips.animation != null:
				# Saldırı klibi kendi hızında tamamlanır.
				_clips.animation.speed_scale = 1.0
		ZombieRules.State.INACTIVE:
			_hide_extras()
			_set_burn(0.0)
			_flash_left = 0.0
			_set_flash(0.0)
			set_process(false)
			# Havuzdaki (görünmeyen) zombi animasyon hesaplamasın.
			if _clips.animation != null:
				_clips.animation.stop()


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
	if VC_MODELS.has(model_kind):
		_build_vc_model(model_kind)
		return
	var model: Node3D = (MODELS[model_kind] as PackedScene).instantiate() as Node3D
	add_child(model)
	_meshes.append(ZombieLook.apply_random(model))
	_clips.animation = AnimationPlayer.new()
	model.add_child(_clips.animation)
	_skeleton = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	_clips.animation.add_animation_library(ZombieClips.LIBRARY_NAME, ZombieClips.library(_skeleton))


## Yeni hat: çeşitlerden biri kalır, köşe renkli ortak malzeme, modelin kendi AnimationPlayer'ı.
func _build_vc_model(model_kind: StringName) -> void:
	var model: Node3D = (VC_MODELS[model_kind] as PackedScene).instantiate() as Node3D
	add_child(model)
	var mesh: MeshInstance3D = ModelVariants.keep(model, randi())
	mesh.material_override = _vc_shared_material()
	var t: float = 1.0 + randf_range(-VC_TINT_VARIANCE, VC_TINT_VARIANCE)
	mesh.set_instance_shader_parameter(&"tint", Vector3(t, t * randf_range(0.97, 1.03), t))
	_meshes.append(mesh)
	_model_height = mesh.get_aabb().end.y
	_clips.animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_skeleton = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	_clips.own_clips = true


func _build_box() -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	add_child(mesh)
	_meshes.append(mesh)


func _apply_kind(row: Dictionary) -> void:
	_clips.row = row
	var height: float = row["height"]
	if _tongue == null and EnemyData.tongues(row) and SpecialAttacks.is_special(row):
		_make_tongue(height)
	if _clips.animation == null:
		var box: MeshInstance3D = _meshes[0]
		box.mesh = _box_mesh_for(row)
		box.material_override = _material_for(row)
		box.position.y = height * 0.5
		return
	var size: float = randf_range(1.0 - Tuning.ZOMBIE_SCALE_VARIANCE, 1.0 + Tuning.ZOMBIE_SCALE_VARIANCE)
	scale = Vector3.ONE * (size * height / _model_height)


## Dil görüntüsü: yeni modelde Head kemiğine bağlı yordamsal dil, yoksa eski kutu.
func _make_tongue(height: float) -> void:
	if _clips.own_clips:
		var rope: DilciTongue = DilciTongue.new()
		add_child(rope)
		rope.setup(_body, _skeleton)
		_tongue = rope
	else:
		var beam: BeamTongue = BeamTongue.new()
		add_child(beam)
		beam.setup(_body, height)
		_tongue = beam


func _is_special() -> bool:
	return not _clips.row.is_empty() and SpecialAttacks.is_special(_clips.row)


func _on_marker(data: Dictionary) -> void:
	if _marker.on_event(data, _clips.row):
		set_process(true)


func _hide_extras() -> void:
	_jump_age = -1.0
	position.y = 0.0
	_marker.hide_marker()


## Havadaki yükseklik: yay (JumpRules.height_at); zıplama süresi dolunca yerde.
func _tick_jump(delta: float) -> void:
	if _jump_age < 0.0:
		return
	_jump_age += delta
	position.y = JumpRules.height_at(_jump_age / _jump_total, float(_clips.row.get("jump_height", 0.0)))


static func _vc_shared_material() -> ShaderMaterial:
	if _vc_material == null:
		_vc_material = ShaderMaterial.new()
		_vc_material.shader = VC_SHADER
	return _vc_material


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
