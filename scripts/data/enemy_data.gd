class_name EnemyData
extends RefCounted
## Zombi türleri tablosu. Yeni tür = yeni satır.

const WALKER: StringName = &"walker"

const TABLE: Dictionary = {
	&"walker": {
		"id": &"walker",
		"max_hp": 30.0,
		"speed": 2.6,
		"contact_damage": 10.0,
		"radius": 0.45,
		# Saldırı (sn ve m): askere temas mesafesinin üstüne attack_range kadar yaklaşınca hazırlanır,
		# attack_windup sonra vurur; asker o an temas + attack_hit_range içindeyse hasar alır.
		"attack_range": 0.35,
		"attack_hit_range": 0.9,
		"attack_windup": 0.5,
		"attack_recover": 0.6,
		# Saldırı klibinde vuruşun indiği an (sn); klip hızı hazırlık süresine göre ayarlanır.
		"attack_anim_hit_time": 0.7,
		"spawn_time": 0.9,
		"height": 1.6,
		"color": Color(0.42, 0.6, 0.32),
		# Klip adları ZombieClipData tablosundan; birden çok varsa zombi başına rastgele biri.
		"anim_walk": [&"walk_a", &"walk_b", &"walk_c"],
		"anim_attack": [&"attack"],
		"anim_stagger": [&"stagger"],
		"anim_death": [&"death_a", &"death_b", &"death_c"],
		"anim_spawn": [&"spawn"],
	},
}


static func get_row(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen zombi türü: %s" % id)
	return TABLE[id]
