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
		"height": 1.6,
		"color": Color(0.42, 0.6, 0.32),
	},
}


static func get_row(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen zombi türü: %s" % id)
	return TABLE[id]
