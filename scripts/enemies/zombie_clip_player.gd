class_name ZombieClipPlayer
extends RefCounted
## Zombi klip çalma yardımcısı (ZombieVisual'in parçası): tür satırındaki anim_* adlarından klip seçer ve
## süreye/hıza uydurarak oynatır. animation yoksa (kutu) hiçbir şey yapmaz.

var animation: AnimationPlayer
var row: Dictionary = {}
## Modelin kendi klipleri (yeni hat) ya da paylaşılan "zombie" kütüphanesi.
var own_clips: bool = false
## Örneğin boy ölçeği (yürüme hızı senkronu için).
var size_scale: float = 1.0
## Hıza bağlı oynayan klip (yürüme ya da koşu) ve anahtarlandığı ref hız; &"" = senkron yok.
var _sync_clip: StringName = &""
var _sync_ref: float = 0.0


## Yürüyüşü rastgele bir kareden ve biraz farklı hızda başlatır; sürü aynı adımda yürümez.
func start_walk() -> void:
	var clip: StringName = pick_clip(&"anim_walk")
	if clip == &"":
		return
	if is_walk_synced():
		animation.speed_scale = 1.0
	else:
		var variance: float = Tuning.ZOMBIE_ANIM_SPEED_VARIANCE
		animation.speed_scale = randf_range(1.0 - variance, 1.0 + variance)
	animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND)
	animation.seek(randf() * animation.current_animation_length)
	if is_walk_synced():
		_sync_clip = clip
		_sync_ref = float(row["walk_ref_speed"])


func is_walk_synced() -> bool:
	return Tuning.FEATURE_WALK_SPEED_SYNC and row.has("walk_ref_speed")


## Klip ve hız senkronu durumunu sıfırlar (ölüm, havuza dönüş).
func reset_sync() -> void:
	_sync_clip = &""
	_sync_ref = 0.0


## Yürüme ya da koşu klibini gerçek hıza uydurur (yumuşatılmış); boy ölçeği örnek başınadır.
## Yalnız senkronlu klip oynuyorsa çalışır (pençe, çığlık, sendeleme vb. kendi hızında).
func sync_walk(speed: float) -> void:
	if animation == null or _sync_clip == &"" or animation.current_animation != _sync_clip:
		return
	var target: float = ZombieClipRules.walk_speed_scale(speed, _sync_ref, size_scale,
			Tuning.WALK_SPEED_SCALE_MIN, Tuning.WALK_SPEED_SCALE_MAX)
	animation.speed_scale = lerpf(animation.speed_scale, target, Tuning.WALK_SPEED_SMOOTH)


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


## Koşucu: atılış döngüsü (LUNGE), koşu döngüsü (SPRINT) ya da koşarken pençe (STRIKE; klipteki vuruş anı
## strike_hit_time'a denk gelir).
func play_rush(state: ZombieRules.State, duration: float, lunge_speed: float) -> void:
	match state:
		ZombieRules.State.SPRINT:
			play_loop(&"anim_sprint", float(row.get("sprint_anim_speed", 1.0)))
			# Yeni modelde koşu klibi gerçek hıza bağlanır (sprint_ref_speed).
			if row.has("sprint_ref_speed") and Tuning.FEATURE_WALK_SPEED_SYNC and animation != null:
				_sync_clip = animation.current_animation
				_sync_ref = float(row["sprint_ref_speed"])
		ZombieRules.State.STRIKE:
			play_timed(&"anim_strike", float(row.get("strike_anim_hit_time", 0.0)), float(row.get("strike_hit_time", duration)))
		_:
			play_loop(&"anim_lunge", lunge_speed)


## Zıplayan havada: yeni modelde leap klibi jump_time'a uydurulur (çömelmeden kısa harmanla); eskide döngü.
func play_air(duration: float) -> void:
	if not own_clips:
		play_loop(&"anim_air", 1.0)
		return
	var clip: StringName = pick_clip(&"anim_air")
	if clip == &"":
		return
	animation.speed_scale = animation.get_animation(clip).length / maxf(duration, 0.01)
	animation.play(clip, Tuning.JUMPER_LEAP_BLEND)
	animation.seek(0.0)


## Zıplayan inişi: land klibi bir kez, ardından idle döngüsü.
func play_land() -> void:
	var clip: StringName = pick_clip(&"anim_land")
	if clip == &"":
		return
	animation.speed_scale = 1.0
	animation.play(clip, Tuning.ZOMBIE_ANIM_BLEND * 0.5)
	animation.seek(0.0)
	var idle: StringName = pick_clip(&"anim_idle")
	if idle != &"":
		animation.queue(idle)


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
