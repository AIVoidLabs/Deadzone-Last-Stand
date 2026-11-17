class_name Footsteps
extends Node
## Askerin adım sesleri. Gövdeyi yalnız okur. Adım boyu koşu klibinden türetilir:
## klip PLAYER_RUN_ANIM_SPEED hızında bir döngüde FOOTSTEP_STEPS_PER_CYCLE adım atar, hız değişince
## klip de aynı oranda hızlandığı için yola göre sayılan adımlar ayakla aynı tempoda kalır.

var player: Player

var _stride: Stride
var _last_position: Vector2


func _ready() -> void:
	name = "Footsteps"
	var clip: Animation = PlayerAnimator.LIBRARY.get_animation(String(PlayerAnimator.CLIP_RUN).get_slice("/", 1))
	var cycle_distance: float = Tuning.PLAYER_RUN_ANIM_SPEED * clip.length
	_stride = Stride.new(cycle_distance / Tuning.FOOTSTEP_STEPS_PER_CYCLE)
	_last_position = player.position_2d()


func _physics_process(_delta: float) -> void:
	var now: Vector2 = player.position_2d()
	var moved: float = now.distance_to(_last_position)
	_last_position = now
	if player.state != Player.State.MOVE or player.planar_speed() < Tuning.FOOTSTEP_MIN_SPEED:
		_stride.reset()
		return
	if _stride.advance(moved) > 0:
		Audio.play(SoundData.FOOTSTEP)
