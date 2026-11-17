class_name CardData
extends RefCounted
## Seviye kartları ve nadirlik kademeleri. Yeni kart = yeni satır.
## CARDS: values kademe sırasıyla (sıradan, nadir, destansı, efsanevi).
## TIERS: from_level'dan itibaren seviye başına per_level kadar şans, en çok max_chance;
## şans istatistiği bu olasılığı (1 + şans/100) ile çarpar. İlk kademe her zaman olasıdır.

const CARDS: Array = [
	{"stat": &"max_hp", "values": [10.0, 20.0, 30.0, 40.0]},
	{"stat": &"damage", "values": [5.0, 8.0, 12.0, 16.0]},
	{"stat": &"fire_rate", "values": [5.0, 10.0, 15.0, 20.0]},
	{"stat": &"range", "values": [5.0, 10.0, 15.0, 20.0]},
	{"stat": &"move_speed", "values": [3.0, 6.0, 9.0, 12.0]},
	{"stat": &"armor", "values": [1.0, 2.0, 3.0, 4.0]},
	{"stat": &"luck", "values": [5.0, 10.0, 15.0, 20.0]},
	{"stat": &"hp_regen", "values": [1.0, 2.0, 3.0, 4.0]},
	{"stat": &"pickup_range", "values": [15.0, 30.0, 45.0, 60.0]},
	{"stat": &"dash_cooldown", "values": [5.0, 10.0, 15.0, 20.0]},
]

const TIERS: Array = [
	{"name": "SIRADAN", "color": Color(0.82, 0.84, 0.86), "from_level": 1, "per_level": 0.0, "max_chance": 1.0},
	{"name": "NADİR", "color": Color(0.35, 0.65, 1.0), "from_level": 1, "per_level": 0.06, "max_chance": 0.6},
	{"name": "DESTANSI", "color": Color(0.72, 0.42, 1.0), "from_level": 3, "per_level": 0.02, "max_chance": 0.25},
	{"name": "EFSANEVİ", "color": Color(1.0, 0.55, 0.2), "from_level": 6, "per_level": 0.0075, "max_chance": 0.08},
]
