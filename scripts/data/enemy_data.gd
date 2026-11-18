class_name EnemyData
extends RefCounted
## Zombi türleri tablosu. Yeni tür = yeni satır (eksik alanlar yürüyen zombiden gelir).
## attack_kind: &"melee" (yaklaşıp vurur) ya da &"lunge" (uzaktan hazırlanıp atılır; lunge_* alanları).

const WALKER: StringName = &"walker"
const RUNNER: StringName = &"runner"
const TANK: StringName = &"tank"

const _WALKER_ROW: Dictionary = {
	"id": &"walker",
	# Model dosyası ZombieVisual.MODELS anahtarı.
	"model": &"walker",
	"max_hp": 30.0,
	"speed": 2.6,
	"contact_damage": 10.0,
	"radius": 0.45,
	"attack_kind": &"melee",
	# Saldırı (sn ve m): askere temas mesafesinin üstüne attack_range kadar yaklaşınca hazırlanır,
	# attack_windup sonra vurur; asker o an temas + attack_hit_range içindeyse hasar alır.
	"attack_range": 0.35,
	"attack_hit_range": 0.9,
	"attack_windup": 0.5,
	"attack_recover": 0.6,
	# Saldırı klibinde vuruşun indiği an (sn); klip hızı hazırlık süresine göre ayarlanır.
	"attack_anim_hit_time": 0.7,
	"spawn_time": 0.9,
	# Ölünce bıraktığı kristal (hem XP hem para).
	"drop_value": 3,
	# İtilmeye direnç (büyük = az itilir) ve vurulunca sendeleme süresi (sn); 0 = sendelemez.
	"weight": 1.0,
	"stagger_time": 0.22,
	"height": 1.6,
	"color": Color(0.42, 0.6, 0.32),
	# Klip adları ZombieClipData tablosundan; birden çok varsa zombi başına rastgele biri.
	"anim_walk": [&"walk_a", &"walk_b", &"walk_c"],
	"anim_attack": [&"attack"],
	"anim_lunge": [],
	"anim_stagger": [&"stagger"],
	"anim_death": [&"death_a", &"death_b", &"death_c"],
	"anim_spawn": [&"spawn"],
}

const _OVERRIDES: Dictionary = {
	# Koşucu: zayıf ama hızlı. Yaklaşınca çömelip (belirgin hazırlık) askerin gideceği yere atılır.
	# Atılış: hazırlığın başında oyuncunun hızını önceden hesaplar (lead), son lunge_lock_time saniyede yönü kilitler,
	# atılırken lunge_turn_rate (rad/sn) ile hafifçe izler. Dash dokunulmazlığı ve zamanlı yan kaçış ıskalatır.
	&"runner": {
		"id": &"runner",
		"model": &"runner",
		"max_hp": 18.0,
		"speed": 3.8,
		"contact_damage": 14.0,
		"radius": 0.38,
		"attack_kind": &"lunge",
		"lunge_range": 4.2,
		"attack_windup": 0.65,
		"attack_recover": 0.9,
		"lunge_speed": 9.0,
		"lunge_time": 0.6,
		"lunge_lead": 0.9,
		"lunge_lock_time": 0.22,
		"lunge_turn_rate": 2.0,
		"lunge_hit_range": 0.5,
		"attack_anim_hit_time": 0.0,
		"prewarm": 24,
		"drop_value": 5,
		"weight": 0.7,
		"stagger_time": 0.2,
		"height": 1.7,
		"color": Color(0.7, 0.3, 0.25),
		"anim_walk": [&"run_a", &"run_b"],
		"anim_attack": [&"pounce_windup"],
		"anim_lunge": [&"pounce"],
	},
	# Tank: iri, yavaş, çok dayanıklı; sendelemez, zor itilir. Geniş ve ağır savurur: hazırlığı uzun, erişimi geniş.
	&"tank": {
		"id": &"tank",
		"model": &"tank",
		"max_hp": 220.0,
		"speed": 1.5,
		"contact_damage": 35.0,
		"radius": 0.75,
		"attack_range": 0.7,
		"attack_hit_range": 1.5,
		"attack_windup": 0.9,
		"attack_recover": 1.1,
		"attack_anim_hit_time": 0.55,
		"spawn_time": 1.1,
		"prewarm": 8,
		"drop_value": 25,
		"weight": 4.0,
		"stagger_time": 0.0,
		"height": 2.4,
		"color": Color(0.35, 0.4, 0.38),
		"anim_walk": [&"tank_walk_a", &"tank_walk_b"],
		"anim_attack": [&"tank_slam"],
	},
}

static var TABLE: Dictionary = _build()


static func _build() -> Dictionary:
	var table: Dictionary = {&"walker": _WALKER_ROW}
	for id: StringName in _OVERRIDES:
		var row: Dictionary = _WALKER_ROW.duplicate()
		row.merge(_OVERRIDES[id], true)
		table[id] = row
	return table


static func get_row(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen zombi türü: %s" % id)
	return TABLE[id]


static func lunges(row: Dictionary) -> bool:
	return row["attack_kind"] == &"lunge"
