class_name ZombieClipPlayer
extends RefCounted
## Zombi klip çalma yardımcısı (ZombieVisual'in parçası): tür satırındaki anim_* adlarından klip seçer ve
## süreye/hıza uydurarak oynatır. animation yoksa (kutu) hiçbir şey yapmaz.

var animation: AnimationPlayer
var row: Dictionary = {}
## Modelin kendi klipleri (yeni hat) ya da paylaşılan "zombie" kütüphanesi.
var own_clips: bool = false


## Yürüyüşü rastgele bir kareden ve biraz farklı hızda başlatır; sürü aynı adımda yürümez.
func start_walk() -> void:
	var clip: StringName = pick_clip(&"anim_walk")
	if clip == &"":
		return
	var variance: float = Tuning.ZOMBIE_ANIM_SPEED_VARIANCE
	animation.speed_scale = randf_range(1.0 - variance, 1.0 + variance)
	animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)
	animation.seek(randf() * animation.current_animation_length)


## Klibi baştan oynatır; marker_time (0 ise klibin sonu) tam duration saniyede gelecek hızda.
func play_timed(row_key: StringName, marker_time: float, duration: float) -> void:
	var clip: StringName = pick_clip(row_key)
	if clip == &"":
		return
	var span: float = marker_time if marker_time > 0.0 else animation.get_animation(clip).length
	animation.speed_scale = span / maxf(duration, 0.01)
	animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)
	animation.seek(0.0)


## Şaklama klibi bir kez; eski mekanikte (LASH = bağ) çekiş döngüsü ardından gelir.
func play_lash() -> void:
	var clip: StringName = pick_clip(&"anim_lash")
	if clip == &"":
		return
	animation.speed_scale = 1.0
	animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND * 0.5)
	animation.seek(0.0)
	if not Tuning.FEATURE_TONGUE_PULL:
		animation.queue(pick_clip(&"anim_pull"))


## Klibi sabit hızda baştan oynatır (süreye uydurmadan).
func play_loop(row_key: StringName, speed: float) -> void:
	var clip: StringName = pick_clip(row_key)
	if clip == &"":
		return
	animation.speed_scale = speed
	animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)


func pick_clip(row_key: StringName) -> StringName:
	if animation == null:
		return &""
	var clips: Array = row.get(row_key, [])
	if clips.is_empty():
		return &""
	var clip: StringName = clips.pick_random()
	return clip if own_clips else ZombieClips.full_name(clip)
