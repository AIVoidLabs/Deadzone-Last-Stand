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
}
