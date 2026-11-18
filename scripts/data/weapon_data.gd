class_name WeaponData
extends RefCounted
## Silah tablosu. Yeni silah = yeni satır.

const PISTOL: StringName = &"pistol"
const SHOTGUN: StringName = &"shotgun"

## Zorunlu olmayan alanlar ve varsayılanları (satırda yoksa bunlar geçerli):
## pellets: atış başına mermi (saçma) sayısı; damage ve knockback saçma başına.
## spread_deg: saçmaların yelpaze açısı; spread_jitter: saçma aralığının kesri kadar rastgele sapma.
## flash_scale: namlu parlaması büyütmesi; fire_shake: atışta kamera sarsıntısı payı.
const DEFAULTS: Dictionary = {
	"pellets": 1, "spread_deg": 0.0, "spread_jitter": 0.0, "flash_scale": 1.0, "fire_shake": 0.0,
}

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
	# Pompalı: yakın menzil, yavaş, saçılan atış ve güçlü itme (saçma başına itme toplanır).
	&"shotgun": {
		"id": &"shotgun",
		"damage": 7.0,
		"pellets": 6,
		"spread_deg": 30.0,
		"spread_jitter": 0.6,
		"fire_interval": 1.1,
		"max_range": 7.0,
		"projectile_speed": 28.0,
		"knockback": 3.5,
		"model": &"Shotgun",
		"model_scale": 1.0,
		"recoil": 0.22,
		"muzzle_offset": 0.66,
		"flash_scale": 1.7,
		"fire_shake": 0.1,
		"sound": &"shotgun",
	},
}


## Kademe sütunu (dizin = kademe - 1). damage_mult: hasar çarpanı; rate_mult: atış hızı çarpanı.
## tint: model rengi çarpanı; glow: kendi ışıma payı; scale: model büyütme çarpanı.
const TIERS: Array[Dictionary] = [
	{"damage_mult": 1.0, "rate_mult": 1.0, "tint": Color(1.0, 1.0, 1.0), "glow": 0.0, "scale": 1.0},
	{"damage_mult": 1.5, "rate_mult": 1.12, "tint": Color(0.45, 1.0, 0.55), "glow": 0.3, "scale": 1.07},
	{"damage_mult": 2.2, "rate_mult": 1.25, "tint": Color(0.4, 0.65, 1.0), "glow": 0.5, "scale": 1.14},
	{"damage_mult": 3.2, "rate_mult": 1.4, "tint": Color(1.0, 0.78, 0.2), "glow": 0.8, "scale": 1.22},
]


static func max_tier() -> int:
	return TIERS.size()


static func tier_row(tier: int) -> Dictionary:
	return TIERS[clampi(tier, 1, TIERS.size()) - 1]


## Satır + eksik alanlar için DEFAULTS.
static func get_row(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen silah: %s" % id)
	var row: Dictionary = (TABLE[id] as Dictionary).duplicate()
	row.merge(DEFAULTS)
	return row
