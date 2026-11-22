class_name ZombieSounds
extends RefCounted
## Zombi sesleri (8.4b): EnemyManager / SpawnDirector olaylarını Audio.play_at'a bağlar. Yalnız Tuning.FEATURE_SFX_ZOMBIES açıkken
## çağrılır (main.gd _add_sounds). Konumlu sesler uzaklığa göre kısılır; boss uyarısı konumsuz çalar.

const BOSS_SLAM_OFFSET_DB: float = 2.0
const BOSS_STUN_OFFSET_DB: float = -4.0


static func wire(enemies: EnemyManager, director: SpawnDirector) -> void:
	enemies.special_started.connect(_on_special_started)
	enemies.tongue_event.connect(_on_tongue_event)
	enemies.enemy_blocked.connect(func(at: Vector3, _dir: Vector2, _amount: float) -> void:
		Audio.play_at(SoundData.Z_SHIELD_THUNK, at))
	enemies.scream_emitted.connect(func(at: Vector3, _radius: float) -> void:
		Audio.play_at(SoundData.Z_SCREAMER_SCREAM, at))
	enemies.lob_launched.connect(func(kind: StringName, from: Vector3, _dest: Vector3, _flight: float, _arc: float, _radius: float) -> void:
		Audio.play_at(SoundData.Z_SPIT if kind == &"spit" else SoundData.Z_THROWER_GRUNT, from))
	enemies.lob_landed.connect(func(kind: StringName, at: Vector3, _radius: float) -> void:
		Audio.play_at(SoundData.Z_ACID_SPLASH if kind == &"spit" else SoundData.Z_ROCK_IMPACT, at))
	enemies.jump_landed.connect(func(at: Vector3, _radius: float) -> void:
		Audio.play_at(SoundData.Z_HEAVY_IMPACT, at))
	enemies.bloat_exploded.connect(func(at: Vector3, _radius: float) -> void:
		Audio.play_at(SoundData.Z_BLOATER_BURST, at))
	enemies.boss_event.connect(_on_boss_event)
	enemies.enemy_killed.connect(_on_enemy_killed)
	director.boss_warning.connect(func() -> void:
		Audio.play(SoundData.Z_BOSS_WARNING))


static func _on_special_started(kind: StringName, phase: StringName, at: Vector3) -> void:
	# Koşucu çığlığı uyarıdır: çömelip bağırmaya başlarken (windup) çalar; zıplayanın kalkışı için dosya yok.
	if kind == &"runner" and phase == &"windup":
		Audio.play_at(SoundData.Z_RUNNER_SCREECH, at)


static func _on_tongue_event(kind: StringName, at: Vector3) -> void:
	Audio.play_at(SoundData.Z_TONGUE_SLURP if kind == &"attach" else SoundData.Z_TONGUE_LASH, at)


static func _on_boss_event(event_name: StringName, data: Dictionary) -> void:
	match event_name:
		&"slam":
			if int(data["index"]) == 0:
				Audio.play_at(SoundData.Z_HEAVY_IMPACT, data["at"], BOSS_SLAM_OFFSET_DB)
		&"stun":
			Audio.play_at(SoundData.Z_HEAVY_IMPACT, data["at"], BOSS_STUN_OFFSET_DB)
		&"charge_start":
			Audio.play_at(SoundData.Z_BOSS_CHARGE, data["at"])
		&"summon", &"roar":
			Audio.play_at(SoundData.Z_BOSS_ROAR, data["at"])


static func _on_enemy_killed(at: Vector3, row: Dictionary) -> void:
	if row.get("boss", false):
		Audio.play_at(SoundData.Z_BOSS_ROAR, at)
	elif Tuning.FEATURE_SFX_ZOMBIE_BODYFALL:
		Audio.play_at(SoundData.Z_BODYFALL, at)
