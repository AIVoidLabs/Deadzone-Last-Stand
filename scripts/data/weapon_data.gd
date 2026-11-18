class_name WeaponData
extends RefCounted
## Silah tablosu. Yeni silah = yeni satır.

const PISTOL: StringName = &"pistol"
const SHOTGUN: StringName = &"shotgun"
const KNIFE: StringName = &"knife"
const KATANA: StringName = &"katana"
const LIGHTSABER: StringName = &"lightsaber"
const FLAME_SWORD: StringName = &"flame_sword"

## Zorunlu olmayan alanlar ve varsayılanları (satırda yoksa bunlar geçerli):
## pellets: atış başına mermi (saçma) sayısı; damage ve knockback saçma başına.
## spread_deg: saçmaların yelpaze açısı; spread_jitter: saçma aralığının kesri kadar rastgele sapma.
## flash_scale: namlu parlaması büyütmesi; fire_shake: atışta kamera sarsıntısı payı.
## behavior: &"projectile" (mermi atar) ya da &"melee" (yakın dövüş, aşağıdaki alanlar).
## Yakın dövüş: max_range = vuruş menzili (m), melee_arc_deg = savurma yayı (0 = tek hedefe dürtme),
## melee_swing_time = savurma/dürtme animasyon süresi, burn_dps/burn_time = yanma (hasar/sn, süre).
## base_glow: modelin kademeden bağımsız ışıması (ışın/ateş). slash_color: kesik izinin rengi. Mağaza: min_wave = ilk görüneceği dalga (1 tabanlı), weight = çıkma ağırlığı.
const DEFAULTS: Dictionary = {
	"pellets": 1, "spread_deg": 0.0, "spread_jitter": 0.0, "flash_scale": 1.0, "fire_shake": 0.0,
	"behavior": &"projectile", "melee_arc_deg": 0.0, "melee_swing_time": 0.2, "burn_dps": 0.0, "burn_time": 0.0,
	"slash_color": Color(1.0, 1.0, 1.0), "min_wave": 1, "weight": 1.0, "base_glow": 0.0,
}

const TABLE: Dictionary = {
	&"pistol": {
		"id": &"pistol",
		# Mağaza: görünen ad ve temel kristal fiyatı.
		"name": "Tabanca",
		"price": 30,
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
		"name": "Pompalı",
		"price": 55,
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
	# --- Yakın dövüş (7.1): enerji çemberinden fırlayıp savrulur; mermi yok, kendi hasar alanı var. ---
	# Bıçak: çok hızlı, tek hedefe dürtme, kısa menzil.
	&"knife": {
		"id": &"knife", "name": "Bıçak", "price": 35,
		"behavior": &"melee", "damage": 9.0, "fire_interval": 0.28, "max_range": 1.9,
		"melee_arc_deg": 0.0, "melee_swing_time": 0.14, "knockback": 1.5,
		"model": &"Knife", "model_scale": 2.0, "recoil": 0.0, "muzzle_offset": 0.0,
		"sound": &"swing_light", "slash_color": Color(0.85, 0.9, 1.0),
		"weight": 1.0, "min_wave": 1,
	},
	# Katana: yay şeklinde savurma, önündeki herkese vurur.
	&"katana": {
		"id": &"katana", "name": "Katana", "price": 90,
		"behavior": &"melee", "damage": 18.0, "fire_interval": 0.7, "max_range": 2.8,
		"melee_arc_deg": 110.0, "melee_swing_time": 0.22, "knockback": 3.0,
		"model": &"Katana", "model_scale": 1.3, "recoil": 0.0, "muzzle_offset": 0.0,
		"sound": &"swing_medium", "slash_color": Color(0.9, 0.95, 1.0),
		"weight": 0.7, "min_wave": 3,
	},
	# Işın kılıcı: geniş savurma, yüksek hasar, yakar.
	&"lightsaber": {
		"id": &"lightsaber", "name": "Işın Kılıcı", "price": 240,
		"behavior": &"melee", "damage": 26.0, "fire_interval": 0.95, "max_range": 3.6,
		"melee_arc_deg": 200.0, "melee_swing_time": 0.3, "knockback": 5.0,
		"burn_dps": 6.0, "burn_time": 2.0,
		"model": &"Lightsaber", "model_scale": 1.3, "recoil": 0.0, "muzzle_offset": 0.0,
		"sound": &"swing_energy", "slash_color": Color(0.3, 0.75, 1.0), "base_glow": 0.7,
		"weight": 0.2, "min_wave": 8,
	},
	# Ateşli kılıç: orta yay, güçlü yanma.
	&"flame_sword": {
		"id": &"flame_sword", "name": "Ateşli Kılıç", "price": 200,
		"behavior": &"melee", "damage": 20.0, "fire_interval": 0.8, "max_range": 3.0,
		"melee_arc_deg": 130.0, "melee_swing_time": 0.26, "knockback": 3.0,
		"burn_dps": 10.0, "burn_time": 3.0,
		"model": &"FlameSword", "model_scale": 1.3, "recoil": 0.0, "muzzle_offset": 0.0,
		"sound": &"swing_fire", "slash_color": Color(1.0, 0.5, 0.1), "base_glow": 0.6,
		"weight": 0.3, "min_wave": 6,
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


static func ids() -> Array[StringName]:
	var list: Array[StringName] = []
	for id: StringName in TABLE:
		list.append(id)
	return list


## Mağazada wave. dalgada (1 tabanlı, biten dalga sayısı) çıkabilen silahlar: id → çıkma ağırlığı.
static func shop_pool(wave: int) -> Dictionary:
	var pool: Dictionary = {}
	for id: StringName in TABLE:
		var row: Dictionary = get_row(id)
		if int(row["min_wave"]) <= wave:
			pool[id] = float(row["weight"])
	return pool


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
