class_name PlayerAnimator
extends RefCounted
## Askerin animasyon ağacını kodla kurar ve sürer:
## bekleme<->koşu harmanı -> koşu hızı -> vurulma (yalnız üst gövde) -> takla -> sürüklenme (dil bağında) ->
## kurtulma (bağ çözülünce) -> hayatta/ölü. Sürüklenme ve kurtulma Blender'da elle anahtarlanmış
## klipler (player_anims.glb); FEATURE_PLAYER_DRAG_CLIPS kapalıysa eski türetilmiş klipler.

const LIBRARY_NAME: StringName = &"ual1"
const LIBRARY: AnimationLibrary = preload("res://assets/models/anim/ual1.glb")
const CLIP_IDLE: StringName = &"ual1/Idle"
const CLIP_RUN: StringName = &"ual1/Sprint"
const CLIP_HIT: StringName = &"ual1/Hit_Chest"
const CLIP_ROLL: StringName = &"ual1/Roll"
const CLIP_DEATH: StringName = &"ual1/Death01"
const SKELETON_PATH: String = "%GeneralSkeleton"
const DRAG_LIBRARY_NAME: StringName = &"player_v"
const DRAG_LIBRARY: AnimationLibrary = preload("res://assets/models/anim/player_anims.glb")
## Eski (türetilmiş) çırpınma döngüsünün hızı ve kurtulma klibinin süresi (sn); yeni klipler kendi hızında.
const STRUGGLE_SPEED: float = 1.8
const BREAK_FREE_TIME: float = 0.5
## Vurulma klibi yalnız bu kemikleri oynatır; bacaklar koşmayı sürdürür.
const UPPER_BODY: Array[String] = [
	"Spine", "Chest", "UpperChest", "Neck", "Head",
	"LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand",
]
const LIFE_ALIVE: String = "alive"
const LIFE_DEAD: String = "dead"

var _tree: AnimationTree


func _init(model: Node3D) -> void:
	# AnimationTree kendi kütüphanesini taşır; ayrı bir AnimationPlayer gerekmez.
	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	_tree.add_animation_library(LIBRARY_NAME, LIBRARY)
	var skeleton: Skeleton3D = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	var extra: AnimationLibrary = PlayerClipData.library(skeleton)
	_tree.add_animation_library(PlayerClipData.LIBRARY_NAME, extra)
	if Tuning.FEATURE_PLAYER_DRAG_CLIPS:
		_tree.add_animation_library(DRAG_LIBRARY_NAME, DRAG_LIBRARY)
	_tree.tree_root = _build_graph()
	model.add_child(_tree)
	_tree.active = true
	if not Tuning.FEATURE_PLAYER_DRAG_CLIPS:
		_tree.set(&"parameters/struggle_scale/scale", STRUGGLE_SPEED)
		_tree.set(&"parameters/free_scale/scale", extra.get_animation(&"break_free").length / BREAK_FREE_TIME)
	# Geçiş düğümü kendiliğinden bir girişle başlamaz; ilk durumu açıkça iste.
	set_dead(false)


## blend: 0 bekleme, 1 koşu. run_scale: koşu klibinin oynatma hızı.
func set_locomotion(blend: float, run_scale: float) -> void:
	_tree.set(&"parameters/move/blend_position", blend)
	_tree.set(&"parameters/run_scale/scale", run_scale)


func play_hit() -> void:
	_tree.set(&"parameters/hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func play_roll() -> void:
	_tree.set(&"parameters/roll/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## Dil bağında: sürüklenme (eski: çırpınma) döngüsü başlar.
func play_struggle() -> void:
	_tree.set(&"parameters/struggle/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## Bağ çözülünce: çırpınma biter, kollar açılarak kurtulma klibi bir kez oynar.
func play_break_free() -> void:
	_tree.set(&"parameters/struggle/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	_tree.set(&"parameters/free/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func set_dead(dead: bool) -> void:
	_tree.set(&"parameters/life/transition_request", LIFE_DEAD if dead else LIFE_ALIVE)


func _build_graph() -> AnimationNodeBlendTree:
	var graph: AnimationNodeBlendTree = AnimationNodeBlendTree.new()

	var move: AnimationNodeBlendSpace1D = AnimationNodeBlendSpace1D.new()
	move.min_space = 0.0
	move.max_space = 1.0
	move.add_blend_point(_clip(CLIP_IDLE), 0.0, -1, &"idle")
	move.add_blend_point(_clip(CLIP_RUN), 1.0, -1, &"run")
	graph.add_node(&"move", move)
	graph.add_node(&"run_scale", AnimationNodeTimeScale.new())
	graph.connect_node(&"run_scale", 0, &"move")

	var hit: AnimationNodeOneShot = _one_shot(Tuning.PLAYER_ANIM_HIT_FADE)
	hit.filter_enabled = true
	for bone: String in UPPER_BODY:
		hit.set_filter_path(NodePath("%s:%s" % [SKELETON_PATH, bone]), true)
	graph.add_node(&"hit_clip", _clip(CLIP_HIT))
	graph.add_node(&"hit", hit)
	graph.connect_node(&"hit", 0, &"run_scale")
	graph.connect_node(&"hit", 1, &"hit_clip")

	graph.add_node(&"roll_clip", _clip(CLIP_ROLL))
	graph.add_node(&"roll_scale", AnimationNodeTimeScale.new())
	graph.connect_node(&"roll_scale", 0, &"roll_clip")
	graph.add_node(&"roll", _one_shot(Tuning.PLAYER_ANIM_BLEND))
	graph.connect_node(&"roll", 0, &"hit")
	graph.connect_node(&"roll", 1, &"roll_scale")

	graph.add_node(&"struggle_clip", _clip(struggle_clip()))
	graph.add_node(&"struggle_scale", AnimationNodeTimeScale.new())
	graph.connect_node(&"struggle_scale", 0, &"struggle_clip")
	graph.add_node(&"struggle", _one_shot(Tuning.PLAYER_ANIM_BLEND))
	graph.connect_node(&"struggle", 0, &"roll")
	graph.connect_node(&"struggle", 1, &"struggle_scale")

	graph.add_node(&"free_clip", _clip(break_free_clip()))
	graph.add_node(&"free_scale", AnimationNodeTimeScale.new())
	graph.connect_node(&"free_scale", 0, &"free_clip")
	graph.add_node(&"free", _one_shot(Tuning.PLAYER_ANIM_BLEND))
	graph.connect_node(&"free", 0, &"struggle")
	graph.connect_node(&"free", 1, &"free_scale")

	var life: AnimationNodeTransition = AnimationNodeTransition.new()
	life.xfade_time = Tuning.PLAYER_ANIM_BLEND
	life.add_input(LIFE_ALIVE)
	life.add_input(LIFE_DEAD)
	graph.add_node(&"death_clip", _clip(CLIP_DEATH))
	graph.add_node(&"life", life)
	graph.connect_node(&"life", 0, &"free")
	graph.connect_node(&"life", 1, &"death_clip")
	graph.connect_node(&"output", 0, &"life")
	return graph


## Bağlıyken oynayan döngü: Blender klibi ya da eski türetilmiş çırpınma.
static func struggle_clip() -> StringName:
	if Tuning.FEATURE_PLAYER_DRAG_CLIPS:
		return StringName("%s/drag" % DRAG_LIBRARY_NAME)
	return PlayerClipData.full_name(&"struggle")


static func break_free_clip() -> StringName:
	if Tuning.FEATURE_PLAYER_DRAG_CLIPS:
		return StringName("%s/break_free" % DRAG_LIBRARY_NAME)
	return PlayerClipData.full_name(&"break_free")


## Kurtulma klibinin ekrandaki süresi (sn).
func break_free_time() -> float:
	if Tuning.FEATURE_PLAYER_DRAG_CLIPS:
		return DRAG_LIBRARY.get_animation(&"break_free").length
	return BREAK_FREE_TIME


## Takla klibini verilen süreye sığdırır (dash süresi Tuning'den gelir).
func set_roll_duration(seconds: float) -> void:
	var clip_length: float = LIBRARY.get_animation(String(CLIP_ROLL).get_slice("/", 1)).length
	_tree.set(&"parameters/roll_scale/scale", clip_length / maxf(seconds, 0.01))


static func _clip(clip: StringName) -> AnimationNodeAnimation:
	var node: AnimationNodeAnimation = AnimationNodeAnimation.new()
	node.animation = clip
	return node


static func _one_shot(fade: float) -> AnimationNodeOneShot:
	var node: AnimationNodeOneShot = AnimationNodeOneShot.new()
	node.fadein_time = fade
	node.fadeout_time = fade
	return node
