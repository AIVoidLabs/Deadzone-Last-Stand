class_name ZombieVisual
extends Node3D
## Zombi görüntüsü: ortak iskeletli model + animasyon (Tuning.FEATURE_ZOMBIE_MODEL kapalıysa kutu).
## Görünüm (gövde çeşidi + renk şeması) ZombieLook ile rastgele seçilir; vuruş parlaması örnek başına.
## Yeni hat (VC_MODELS, Aşama V): Blender'da üretilen köşe renkli model, kendi klipleriyle.

## Tür satırındaki "model" alanı bu tablodan seçilir; her model aynı 25 kemikli iskeleti kullanır.
const MODELS: Dictionary = {
	&"walker": preload("res://assets/models/characters/zombie_walker.glb"),
	&"runner": preload("res://assets/models/characters/zombie_runner.glb"),
	&"tank": preload("res://assets/models/characters/zombie_tank.glb"),
	&"jumper": preload("res://assets/models/characters/zombie_jumper.glb"),
	&"tongue": preload("res://assets/models/characters/zombie_tongue.glb"),
}
## Yeni hat modelleri (ZombieModelData): satırdaki anim_* adları modelin kendi klipleridir.
const VC_MODELS: Dictionary = ZombieModelData.VC_MODELS
## Örnek başına hafif ton farkı (±); sürüde aynı ağ aynı görünmesin.
const VC_TINT_VARIANCE: float = 0.08
## Atılma hazırlığı ve toparlanma: klip bu hızda (yavaş) oynar, çömelme duruşu uzunca okunur.
const HOLD_ANIM_SPEED: float = 0.3
const LUNGE_ANIM_SPEED: float = 1.25

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
var _swell: ZombieSwell = ZombieSwell.new()
## Elde taşınan prop (yalnız satırda held_prop varsa: taş fırlatanın kayası).
var _held: ZombieHeldProp
var _model_height: float = Tuning.CHARACTER_MODEL_HEIGHT
var _skeleton: Skeleton3D
## Yeni hat modelinin örnek başına ton farkı (VC_TINT_VARIANCE); satırdaki `tint` ile çarpılır.
var _tint: Vector3 = Vector3.ONE
## Dil görüntüsü (yalnız dilci): DilciTongue (yeni model) ya da BeamTongue (eski kutu).
var _tongue: Node
## Boss Yığın'ın klip ve parıltı yardımcısı (yalnız boss satırında).
var _boss: ZombieBossLook


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
	_body.ground_speed.connect(_clips.sync_walk)


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_set_param(&"flash", 0.0)
	if _dying:
		# Sürenin son ZOMBIE_FADE_TIME saniyesinde solar.
		_death_left -= delta
		_set_param(&"fade", 1.0 - clampf(_death_left / Tuning.ZOMBIE_FADE_TIME, 0.0, 1.0))
	_tick_jump(delta)
	_marker.tick(delta)
	if _swell.is_on():
		_set_param(&"swell", _swell.tick(delta))
	if _held != null:
		_held.tick(delta)
	if not _dying and _flash_left <= 0.0 and _jump_age < 0.0 and not _marker.is_on() and not _swell.is_on() and not (_held != null and _held.is_waiting()):
		set_process(false)


func _on_event(event_name: StringName, data: Dictionary) -> void:
	match event_name:
		&"configure":
			_apply_kind(data)
		&"burn":
			_set_param(&"burn", 1.0 if data["on"] else 0.0)
		&"marker":
			_on_marker(data)
		&"tongue":
			if _tongue != null:
				_tongue.on_event(data)
		&"melee":
			_clips.play_melee()
		&"swell":
			_swell.start(_body.state_duration)
			set_process(true)
		&"swat":
			if _held != null:
				_held.reset()
			_clips.play_timed(&"anim_swat", float(_clips.row.get("throw_melee_anim_hit_time", 0.0)), _body.state_duration)
		&"hit":
			if Tuning.FEATURE_HIT_FLASH:
				_flash_left = Tuning.HIT_FLASH_TIME
				_set_param(&"flash", 1.0)
				set_process(true)
		_:
			if _boss != null:
				_boss.on_event(event_name, data)


func _on_state_changed(new_state: int, old_state: int) -> void:
	# İniş bitti ya da hazırlık sendelemeyle kesildi: yükseklik ve iniş işareti sıfırlanır.
	if (old_state == ZombieRules.State.JUMP or old_state == ZombieRules.State.WINDUP) and new_state != ZombieRules.State.JUMP:
		_hide_extras()
	if _held != null:
		_held.reset()
	if _dying and new_state != ZombieRules.State.DYING:
		_dying = false
		_set_param(&"fade", 0.0)
	if _tongue != null:
		_tongue.on_state(new_state, old_state)
	if _boss != null and _boss.on_state(new_state, _body.state_duration):
		return
	match new_state:
		ZombieRules.State.DYING:
			_clips.reset_sync()
			_dying = true
			_death_left = _body.state_duration
			set_process(true)
			var clip: StringName = _clips.pick_clip(&"anim_death")
			if clip != &"":
				_clips.animation.speed_scale = float(_clips.row.get("death_anim_speed", Tuning.ZOMBIE_DEATH_ANIM_SPEED))
				_clips.animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)
				_clips.animation.seek(0.0)
		ZombieRules.State.SPAWN:
			_clips.play_timed(&"anim_spawn", 0.0, _body.state_duration)
		ZombieRules.State.CHASE:
			_clips.start_walk()
		ZombieRules.State.WINDUP:
			if _is_special() and not _clips.own_clips:
				_clips.play_loop(&"anim_attack", HOLD_ANIM_SPEED)
			else:
				# Klipteki vuruş anı (satırda varsa) hazırlığın sonuna denk gelir; 0 ise klip bütünüyle sığar.
				_clips.play_timed(&"anim_attack", _clips.row.get("attack_anim_hit_time", 0.0), _body.state_duration)
				if _clips.row.get("windup_glow", false):
					_swell.start(_body.state_duration)
					set_process(true)
				if _held != null:
					_held.begin(_clips.row["held_prop"], _body.state_duration, float(_clips.row["attack_anim_hit_time"]))
					set_process(true)
		ZombieRules.State.LUNGE, ZombieRules.State.SPRINT, ZombieRules.State.STRIKE:
			_clips.play_rush(new_state, _body.state_duration, LUNGE_ANIM_SPEED)
		ZombieRules.State.JUMP:
			_jump_age = 0.0
			_jump_total = maxf(_body.state_duration, 0.01)
			set_process(true)
			_clips.play_air(_body.state_duration)
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
			if _clips.own_clips and _clips.row.get("recover_walks", false):
				_clips.start_walk()
			elif _clips.own_clips and _clips.row.has("anim_land"):
				_clips.play_land()
			elif _clips.own_clips and _clips.row.get("recover_finishes_attack", false) and _clips.animation != null:
				_clips.animation.speed_scale = 1.0
			elif _clips.own_clips:
				_clips.play_loop(&"anim_idle", 1.0)
			elif _is_special():
				_clips.play_loop(&"anim_attack", HOLD_ANIM_SPEED)
			elif _clips.animation != null:
				_clips.animation.speed_scale = 1.0
		ZombieRules.State.INACTIVE:
			_hide_extras()
			_clips.reset_sync()
			_set_param(&"burn", 0.0)
			_flash_left = 0.0
			_set_param(&"flash", 0.0)
			set_process(false)
			# Havuzdaki (görünmeyen) zombi animasyon hesaplamasın.
			if _clips.animation != null:
				_clips.animation.stop()


func _set_param(param: StringName, value: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(param, value)


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
	var source: Variant = VC_MODELS[model_kind]
	var scene: PackedScene = (source as Array).pick_random() as PackedScene if source is Array else source as PackedScene
	var model: Node3D = scene.instantiate() as Node3D
	add_child(model)
	var mesh: MeshInstance3D = ModelVariants.keep(model, randi())
	mesh.material_override = ZombieMaterials.vc_shared()
	var t: float = 1.0 + randf_range(-VC_TINT_VARIANCE, VC_TINT_VARIANCE)
	_tint = Vector3(t, t * randf_range(0.97, 1.03), t)
	mesh.set_instance_shader_parameter(&"tint", _tint)
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
	if _tongue == null and EnemyData.tongues(row) and SpecialAttacks.is_special(row) and not Benchmark.flag("--bench-no-tongue"):
		_tongue = ZombieTongues.make(self, _body, _skeleton, _clips.own_clips, height)
	if _clips.animation == null:
		var box: MeshInstance3D = _meshes[0]
		box.mesh = ZombieMaterials.box_mesh(row)
		box.material_override = ZombieMaterials.box_material(row)
		box.position.y = height * 0.5
		return
	ZombieMaterials.apply_tint(_meshes[0], row, _clips.own_clips, _tint)
	if _clips.own_clips and row.has("swell_color"):
		_meshes[0].set_instance_shader_parameter(&"swell_color", row["swell_color"])
	if _held == null and _clips.own_clips and row.has("held_prop") and _skeleton != null:
		_held = ZombieHeldProp.new()
		_held.setup(_skeleton, row["held_prop"])
	if _boss == null and row.get("boss", false):
		_boss = ZombieBossLook.new(_clips, _set_param)
	if _boss != null:
		_boss.configure(row)
	var size: float = randf_range(1.0 - Tuning.ZOMBIE_SCALE_VARIANCE, 1.0 + Tuning.ZOMBIE_SCALE_VARIANCE)
	scale = Vector3.ONE * (size * height / _model_height)
	_clips.size_scale = scale.x


## Asit topunun çıkış noktası (dünya); satırda spit_mouth yoksa ya da iskelet yoksa sıfır vektörü.
func mouth_position() -> Vector3:
	if _skeleton == null or not _clips.row.has("spit_mouth"):
		return Vector3.ZERO
	return ZombieMouth.world_position(_skeleton, _clips.row["spit_mouth"])


func _is_special() -> bool:
	return not _clips.row.is_empty() and SpecialAttacks.is_special(_clips.row)


func _on_marker(data: Dictionary) -> void:
	if _marker.on_event(data, _clips.row):
		set_process(true)


func _hide_extras() -> void:
	if _swell.is_on():
		_swell.stop()
		_set_param(&"swell", 0.0)
	_jump_age = -1.0
	position.y = 0.0
	_marker.hide_marker()


## Havadaki yükseklik: yay (JumpRules.height_at); zıplama süresi dolunca yerde.
func _tick_jump(delta: float) -> void:
	if _jump_age < 0.0:
		return
	_jump_age += delta
	position.y = JumpRules.height_at(_jump_age / _jump_total, float(_clips.row.get("jump_height", 0.0)))
