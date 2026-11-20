extends GutTest
## Askerin bağlanma/kurtulma tek-sefer düğümleri bitmeli; bitmezse asker kurtulma pozunda kalır.

const SOLDIER: PackedScene = preload("res://assets/models/characters/soldier.glb")
const STEP: float = 1.0 / 60.0

var _model: Node3D
var _animator: PlayerAnimator
var _tree: AnimationTree


func before_each() -> void:
	_model = SOLDIER.instantiate() as Node3D
	add_child_autofree(_model)
	_animator = PlayerAnimator.new(_model)
	_tree = _model.get_node("AnimationTree") as AnimationTree


func _advance(seconds: float) -> void:
	for i: int in int(seconds / STEP):
		_tree.advance(STEP)


func test_break_free_clip_does_not_loop() -> void:
	var clip: Animation = _tree.get_animation(PlayerAnimator.break_free_clip())
	assert_eq(clip.loop_mode, Animation.LOOP_NONE)


func test_drag_clip_loops() -> void:
	var clip: Animation = _tree.get_animation(PlayerAnimator.struggle_clip())
	assert_eq(clip.loop_mode, Animation.LOOP_LINEAR, "sürüklenme bağ sürdükçe döner")


func test_struggle_runs_until_released() -> void:
	_animator.play_struggle()
	_advance(1.0)
	assert_true(_tree.get(&"parameters/struggle/active"))


func test_break_free_ends_and_returns_to_locomotion() -> void:
	_animator.play_struggle()
	_advance(1.0)
	_animator.release(true)
	_advance(_animator.break_free_time() + Tuning.PLAYER_ANIM_BLEND * 2.0 + 0.2)
	assert_false(_tree.get(&"parameters/struggle/active"))
	assert_false(_tree.get(&"parameters/free/active"))


## Hata (2026-11-20): dilci ısırıp bırakınca (kurtulma klibi yok) asker sürüklenme pozunda kalıyordu.
func test_bite_release_ends_drag_without_break_free() -> void:
	_animator.play_struggle()
	_advance(1.0)
	_animator.release(false)
	_advance(Tuning.PLAYER_ANIM_BLEND * 2.0 + 0.2)
	assert_false(_tree.get(&"parameters/struggle/active"), "sürüklenme kapanmalı")
	assert_false(_tree.get(&"parameters/free/active"), "ısırıp bırakmada kurtulma klibi oynamaz")


## Yakın mesafede bağ ve bırakma aynı karede gelebilir: yine sürüklenmede kalmamalı.
func test_same_frame_root_and_bite_release_ends_drag() -> void:
	_animator.play_struggle()
	_animator.release(false)
	_advance(Tuning.PLAYER_ANIM_BLEND * 2.0 + 0.2)
	assert_false(_tree.get(&"parameters/struggle/active"))
