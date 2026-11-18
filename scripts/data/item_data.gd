class_name ItemData
extends RefCounted
## Mağaza eşyaları. Yeni eşya = yeni satır. Eşyalar yığılır; etkiler PlayerStats'a eklenir.
## effects: [{stat, value}] (StatData kimlikleri; eksi değer bedeldir). price: temel kristal fiyatı.

const ITEMS: Dictionary = {
	&"armor_plate": {"name": "Zırh Plakası", "price": 25, "effects": [{"stat": &"armor", "value": 3.0}, {"stat": &"move_speed", "value": -3.0}]},
	&"drum_mag": {"name": "Büyük Şarjör", "price": 22, "effects": [{"stat": &"fire_rate", "value": 12.0}, {"stat": &"range", "value": -5.0}]},
	&"long_barrel": {"name": "Uzun Namlu", "price": 22, "effects": [{"stat": &"range", "value": 20.0}, {"stat": &"fire_rate", "value": -5.0}]},
	&"sharp_rounds": {"name": "Keskin Mermi", "price": 30, "effects": [{"stat": &"damage", "value": 10.0}, {"stat": &"max_hp", "value": -5.0}]},
	&"energy_drink": {"name": "Enerji İçeceği", "price": 20, "effects": [{"stat": &"move_speed", "value": 8.0}, {"stat": &"max_hp", "value": -5.0}]},
	&"med_kit": {"name": "Tıbbi Çanta", "price": 28, "effects": [{"stat": &"max_hp", "value": 25.0}, {"stat": &"move_speed", "value": -3.0}]},
	&"lucky_charm": {"name": "Şans Tılsımı", "price": 22, "effects": [{"stat": &"luck", "value": 15.0}, {"stat": &"armor", "value": -1.0}]},
	&"magnet": {"name": "Mıknatıs", "price": 15, "effects": [{"stat": &"pickup_range", "value": 50.0}]},
	&"regen_shot": {"name": "Yenileme Aşısı", "price": 30, "effects": [{"stat": &"hp_regen", "value": 3.0}, {"stat": &"damage", "value": -4.0}]},
	&"dash_boots": {"name": "Dash Çizmesi", "price": 24, "effects": [{"stat": &"dash_cooldown", "value": 12.0}, {"stat": &"armor", "value": -1.0}]},
}


static func ids() -> Array[StringName]:
	var list: Array[StringName] = []
	for id: StringName in ITEMS:
		list.append(id)
	return list


static func get_row(id: StringName) -> Dictionary:
	assert(ITEMS.has(id), "Bilinmeyen eşya: %s" % id)
	return ITEMS[id]
