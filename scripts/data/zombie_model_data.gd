class_name ZombieModelData
extends RefCounted
## Yeni hat (Aşama V) zombi modelleri: renk köşelerde (zombie_vc shader), klipler dosyanın kendi AnimationPlayer'ında.
## Tür satırındaki "model" adı buradan seçilir; dizi = ayrı dosyalarda çeşitler (örnek başına biri rastgele).

const VC_MODELS: Dictionary = {
	&"dilci": preload("res://assets/models/characters/zombie_dilci.glb"),
	&"walker_v": [
		preload("res://assets/models/characters/zombie_walker_office.glb"),
		preload("res://assets/models/characters/zombie_walker_worker.glb"),
		preload("res://assets/models/characters/zombie_walker_skinny.glb"),
		preload("res://assets/models/characters/zombie_walker_civilian.glb"),
	],
	&"runner_v": [
		preload("res://assets/models/characters/zombie_runner_jogger.glb"),
		preload("res://assets/models/characters/zombie_runner_torn.glb"),
		preload("res://assets/models/characters/zombie_runner_bare.glb"),
		preload("res://assets/models/characters/zombie_runner_marathon.glb"),
	],
	&"jumper_v": [
		preload("res://assets/models/characters/zombie_jumper_shorts.glb"),
		preload("res://assets/models/characters/zombie_jumper_overall.glb"),
		preload("res://assets/models/characters/zombie_jumper_track.glb"),
	],
	&"armored_v": [
		preload("res://assets/models/characters/zombie_armored_riot.glb"),
		preload("res://assets/models/characters/zombie_armored_swat.glb"),
		preload("res://assets/models/characters/zombie_armored_guard.glb"),
	],
	&"bloater_v": [
		preload("res://assets/models/characters/zombie_bloater_chef.glb"),
		preload("res://assets/models/characters/zombie_bloater_trucker.glb"),
		preload("res://assets/models/characters/zombie_bloater_bare.glb"),
	],
	&"screamer_v": [
		preload("res://assets/models/characters/zombie_screamer_gown.glb"),
		preload("res://assets/models/characters/zombie_screamer_nurse.glb"),
		preload("res://assets/models/characters/zombie_screamer_bare.glb"),
	],
	&"spitter_v": [
		preload("res://assets/models/characters/zombie_spitter_worker.glb"),
		preload("res://assets/models/characters/zombie_spitter_suit.glb"),
		preload("res://assets/models/characters/zombie_spitter_bare.glb"),
	],
	&"thrower_v": [
		preload("res://assets/models/characters/zombie_thrower_vest.glb"),
		preload("res://assets/models/characters/zombie_thrower_flannel.glb"),
		preload("res://assets/models/characters/zombie_thrower_bare.glb"),
	],
	&"tank_v": [
		preload("res://assets/models/characters/zombie_tank_overall.glb"),
		preload("res://assets/models/characters/zombie_tank_guard.glb"),
		preload("res://assets/models/characters/zombie_tank_heavy.glb"),
		preload("res://assets/models/characters/zombie_tank_bare.glb"),
	],
	&"boss_heap_v": preload("res://assets/models/characters/boss_heap.glb"),
}
