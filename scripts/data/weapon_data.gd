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
		# Ağırlığı 1 olan zombiye verilen ilk itme hızı (m/sn).
		"knockback": 5.0,
		# Görüntü: weapons.glb içindeki nesne, büyütme, geri tepme (m) ve namlu ağzının merkeze uzaklığı (m).
		"model": &"Pistol",
		"model_scale": 2.2,
		"recoil": 0.12,
		"muzzle_offset": 0.25,
		# Atış sesi (SoundData satırı).
		"sound": &"shot",
	},
}


static func get_row(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen silah: %s" % id)
	return TABLE[id]
