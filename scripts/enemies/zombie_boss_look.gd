class_name ZombieBossLook
extends RefCounted
## Boss Yığın'ın görüntü yardımcısı (ZombieVisual'in parçası; yalnız satırda `boss` varsa): saldırı türüne göre klip seçer
## (zombi `boss_attack` olayı hazırlık durumundan önce gelir), WINDUP / CHARGE / STUN / ROAR / RECOVER durumlarını oynatır,
## göğüs yarığı parıltısını (swell kanalı; maske = köşe rengi alfası) dinlenirken kısık, `rage` olayında güçlü tutar.
## Klip adları satırdaki anim_* anahtarlarından (model yokken tank klipleri, Blender modeliyle s74_boss.md adları).

const S = ZombieRules.State

var _clips: ZombieClipPlayer
var _set_param: Callable
var _attack: StringName = &"slam"


func _init(clips: ZombieClipPlayer, set_param: Callable) -> void:
	_clips = clips
	_set_param = set_param


## Satır uygulandı (havuzdan yeniden doğuş dahil): parıltı dinlenme düzeyine döner.
func configure(row: Dictionary) -> void:
	_attack = &"slam"
	_set_param.call(&"swell", float(row["glow_rest"]))


## Boss olayları. Dönüş: olay işlendi mi.
func on_event(event_name: StringName, data: Dictionary) -> bool:
	match event_name:
		&"boss_attack":
			_attack = data["kind"]
		&"rage":
			_set_param.call(&"swell", float(_clips.row["glow_rage"]))
		_:
			return false
	return true


## Kusmuk hazırlığı: anim_spew klibi modelde varsa o (anı spew_anim_hit_time), yoksa yedek roar klibi (anı spew_fallback_hit_time).
func _play_spew(duration: float) -> void:
	if _has_clip(&"anim_spew"):
		_clips.play_timed(&"anim_spew", float(_clips.row.get("spew_anim_hit_time", 0.0)), duration)
	else:
		_clips.play_timed(&"anim_roar", float(_clips.row.get("spew_fallback_hit_time", 0.0)), duration)


func _has_clip(row_key: StringName) -> bool:
	if _clips.animation == null:
		return false
	for clip: StringName in _clips.row.get(row_key, []):
		if _clips.animation.has_animation(clip if _clips.own_clips else ZombieClips.full_name(clip)):
			return true
	return false


## Durum girişi. Dönüş: bu durumu boss görüntüsü oynattı mı (false ise ZombieVisual kendi akışını sürdürür).
func on_state(state: int, duration: float) -> bool:
	match state:
		S.WINDUP:
			if _attack == &"slam":
				_clips.play_timed(&"anim_slam", float(_clips.row.get("slam_anim_hit_time", 0.0)), duration)
			elif _attack == &"spew":
				_play_spew(duration)
			else:
				_clips.play_timed(&"anim_charge_windup" if _attack == &"charge" else &"anim_summon", 0.0, duration)
		S.CHARGE:
			_clips.play_loop(&"anim_charge", float(_clips.row.get("charge_anim_speed", 1.0)))
		S.STUN:
			_clips.play_timed(&"anim_stun", 0.0, duration)
		S.ROAR:
			_clips.play_timed(&"anim_roar", 0.0, duration)
		S.RECOVER:
			# Yer dövmesinin ve kusmuğun klibi toparlanmayı da içerir (sonuna dek oynar); hücum ve çağrıdan sonra bekleme duruşu.
			if (_attack == &"slam" or _attack == &"spew") and _clips.animation != null:
				_clips.animation.speed_scale = 1.0
			else:
				_clips.play_loop(&"anim_idle", 1.0)
		_:
			return false
	return true
