class_name WeaponData
extends RefCounted
## Silah tablosu. Yeni silah = yeni satır.

const PISTOL: StringName = &"pistol"

const TABLE: Dictionary = {
	&"pistol": {
		"id": &"pistol",
		"damage": 10.0,
		"fire_interval": 0.35,
		"max_range": 12.0,
		"projectile_speed": 30.0,
	},
}


static func get_row(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen silah: %s" % id)
	return TABLE[id]
