class_name ItemData
extends RefCounted
## Mağaza eşyaları. Yeni eşya = yeni satır. Eşyalar yığılır; etkiler PlayerStats'a eklenir.
## effects: [{stat, value}] (StatData kimlikleri; eksi değer bedeldir). price: temel kristal fiyatı.

const ITEMS: Dictionary = {
	&"armor_plate": {"name": "Zırh Plakası", "price": 25, "effects": [{"stat": &"armor", "value": 2.0}, {"stat": &"move_speed", "value": -3.0}]},
	&"drum_mag": {"name": "Büyük Şarjör", "price": 22, "effects": [{"stat": &"fire_rate", "value": 6.0}, {"stat": &"range", "value": -5.0}]},
	&"long_barrel": {"name": "Uzun Namlu", "price": 22, "effects": [{"stat": &"range", "value": 10.0}, {"stat": &"fire_rate", "value": -5.0}]},
	&"sharp_rounds": {"name": "Keskin Mermi", "price": 30, "effects": [{"stat": &"damage", "value": 5.0}, {"stat": &"max_hp", "value": -5.0}]},
	&"energy_drink": {"name": "Enerji İçeceği", "price": 20, "effects": [{"stat": &"move_speed", "value": 4.0}, {"stat": &"max_hp", "value": -5.0}]},
	&"med_kit": {"name": "Tıbbi Çanta", "price": 28, "effects": [{"stat": &"max_hp", "value": 13.0}, {"stat": &"move_speed", "value": -3.0}]},
	&"lucky_charm": {"name": "Şans Tılsımı", "price": 22, "effects": [{"stat": &"luck", "value": 7.5}, {"stat": &"armor", "value": -1.0}]},
	&"magnet": {"name": "Mıknatıs", "price": 15, "effects": [{"stat": &"pickup_range", "value": 25.0}]},
	&"regen_shot": {"name": "Yenileme Aşısı", "price": 30, "effects": [{"stat": &"hp_regen", "value": 2.0}, {"stat": &"damage", "value": -4.0}]},
	&"dash_boots": {"name": "Takla Çizmesi", "price": 24, "effects": [{"stat": &"dash_cooldown", "value": 6.0}, {"stat": &"armor", "value": -1.0}]},
	&"dash_coil": {"name": "Takla Bobini", "price": 26, "effects": [{"stat": &"dash_distance", "value": 10.0}, {"stat": &"max_hp", "value": -5.0}]},
	&"light_boots": {"name": "Hafif Çizme", "price": 22, "effects": [{"stat": &"move_speed", "value": 3.0}, {"stat": &"dash_cooldown", "value": 3.0}, {"stat": &"armor", "value": -1.0}]},
	&"scope": {"name": "Dürbün", "price": 20, "effects": [{"stat": &"range", "value": 7.5}, {"stat": &"move_speed", "value": -2.0}]},
	&"hollow_point": {"name": "Oyuk Uçlu Mermi", "price": 24, "effects": [{"stat": &"damage", "value": 3.0}, {"stat": &"range", "value": -4.0}]},
	&"oiled_bolt": {"name": "Yağlı Sürgü", "price": 18, "effects": [{"stat": &"fire_rate", "value": 4.0}, {"stat": &"damage", "value": -2.0}]},
	&"war_cannon": {"name": "Savaş Topu", "price": 70, "effects": [{"stat": &"damage", "value": 11.0}, {"stat": &"fire_rate", "value": 6.0}, {"stat": &"max_hp", "value": -15.0}, {"stat": &"move_speed", "value": -8.0}]},
	&"laser_sight": {"name": "Lazer Nişangâh", "price": 15, "effects": [{"stat": &"range", "value": 4.0}]},
	&"spiked_gloves": {"name": "Çivili Eldiven", "price": 26, "effects": [{"stat": &"damage", "value": 4.0}, {"stat": &"armor", "value": -1.0}]},
	&"sprint_spikes": {"name": "Koşu Çivisi", "price": 15, "effects": [{"stat": &"move_speed", "value": 2.0}]},
	&"adrenaline": {"name": "Adrenalin", "price": 45, "effects": [{"stat": &"move_speed", "value": 7.0}, {"stat": &"dash_cooldown", "value": 5.0}, {"stat": &"max_hp", "value": -10.0}]},
	&"spring_legs": {"name": "Yaylı Bacak", "price": 20, "effects": [{"stat": &"dash_distance", "value": 7.0}, {"stat": &"move_speed", "value": -2.0}]},
	&"blitz_core": {"name": "Yıldırım Çekirdeği", "price": 60, "effects": [{"stat": &"move_speed", "value": 9.0}, {"stat": &"dash_cooldown", "value": 10.0}, {"stat": &"dash_distance", "value": 10.0}, {"stat": &"armor", "value": -3.0}, {"stat": &"max_hp", "value": -10.0}]},
	&"kevlar_vest": {"name": "Kevlar Yelek", "price": 35, "effects": [{"stat": &"armor", "value": 2.0}, {"stat": &"move_speed", "value": -4.0}]},
	&"steel_helmet": {"name": "Çelik Miğfer", "price": 15, "effects": [{"stat": &"armor", "value": 1.0}]},
	&"field_ration": {"name": "Sahra Erzağı", "price": 15, "effects": [{"stat": &"max_hp", "value": 5.0}]},
	&"stim_pack": {"name": "Uyarıcı Paketi", "price": 28, "effects": [{"stat": &"hp_regen", "value": 1.0}, {"stat": &"move_speed", "value": -2.0}]},
	&"fortress_shield": {"name": "Kale Kalkanı", "price": 75, "effects": [{"stat": &"armor", "value": 3.0}, {"stat": &"max_hp", "value": 20.0}, {"stat": &"move_speed", "value": -9.0}, {"stat": &"dash_distance", "value": -15.0}]},
	&"four_leaf": {"name": "Dört Yapraklı Yonca", "price": 15, "effects": [{"stat": &"luck", "value": 4.0}]},
	&"scavenger_bag": {"name": "Leşçi Çantası", "price": 30, "effects": [{"stat": &"pickup_range", "value": 45.0}, {"stat": &"move_speed", "value": -2.0}]},
	&"gamblers_dice": {"name": "Kumarbaz Zarı", "price": 35, "effects": [{"stat": &"luck", "value": 12.5}, {"stat": &"max_hp", "value": -10.0}]},
}


static func ids() -> Array[StringName]:
	var list: Array[StringName] = []
	for id: StringName in ITEMS:
		list.append(id)
	return list


static func get_row(id: StringName) -> Dictionary:
	assert(ITEMS.has(id), "Bilinmeyen eşya: %s" % id)
	return ITEMS[id]
