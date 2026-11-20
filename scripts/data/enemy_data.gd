class_name EnemyData
extends RefCounted
## Zombi türleri tablosu. Yeni tür = yeni satır (eksik alanlar yürüyen zombiden gelir).
## attack_kind: &"melee" (yaklaşıp vurur), &"lunge" (hazırlanıp düz atılır; lunge_*), &"jump" (havaya sıçrayıp
## işaretli yere iner; jump_*, land_radius), &"tongue" (uzaktan dil atıp askeri bağlar; tongue_*, root_time),
## &"sprint" (koşucunun yeni saldırısı: çığlık, durmadan koşu, koşarken pençe; sprint_*, strike_*),
## &"spit" / &"throw" (yay atışı: asit topu, kaya), &"scream", &"bloat". 7.3 beş türün satırları enemy_data_specials.gd'de.

const WALKER: StringName = &"walker"
const RUNNER: StringName = &"runner"
const TANK: StringName = &"tank"
const JUMPER: StringName = &"jumper"
const TONGUE: StringName = &"tongue"
const ARMORED: StringName = &"armored"
const SCREAMER: StringName = &"screamer"
const SPITTER: StringName = &"spitter"
const THROWER: StringName = &"thrower"
const BLOATER: StringName = &"bloater"

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
	"anim_air": [],
	"anim_stagger": [&"stagger"],
	"anim_death": [&"death_a", &"death_b", &"death_c"],
	"anim_spawn": [&"spawn"],
}

# Yeni yürüyen (Tuning.FEATURE_WALKER_MODEL): 4 çeşit GLB, kendi klipleri (ZombieVisual.VC_MODELS[walker_v]).
# Satırın üstüne yazılır; ölüm klipleri yalnız death_a/b. Vuruş anı attack_anim_hit_time (0.7 sn), saldırı
# klibi RECOVER'da sonuna dek tamamlanır.
const _WALKER_LOOK_V: Dictionary = {
	"model": &"walker_v",
	"anim_idle": [&"idle"],
	"anim_walk": [&"walk"],
	"anim_attack": [&"attack"],
	"anim_stagger": [&"stagger"],
	"anim_death": [&"death_a", &"death_b"],
	"anim_spawn": [&"spawn"],
	"recover_finishes_attack": true,
	"walk_ref_speed": Tuning.WALK_REF_SPEED,
}

# Yeni koşucu (Tuning.FEATURE_RUNNER_MODEL, FEATURE_RUNNER_SPRINT açıkken): 4 çeşit GLB (ZombieVisual.VC_MODELS[runner_v]).
# Çığlık (scream 0.6 sn) WINDUP'a, sprint döngüsü SPRINT'e, strike (vuruş 0.25 sn) STRIKE'a oturur. Boy 1.30 m:
# ref hızlar bu boya göre (Tuning.RUNNER_*_REF_SPEED). Satırın üstüne sprint_v'den sonra yazılır.
const _RUNNER_LOOK_V: Dictionary = {
	"model": &"runner_v",
	"height": 1.3,
	"anim_idle": [&"idle"],
	"anim_walk": [&"walk"],
	"anim_attack": [&"scream"],
	"anim_sprint": [&"sprint"],
	"anim_strike": [&"strike"],
	"anim_stagger": [&"stagger"],
	"anim_death": [&"death_a", &"death_b"],
	"anim_spawn": [&"spawn"],
	"strike_anim_hit_time": 0.25,
	"sprint_anim_speed": 1.0,
	"walk_ref_speed": Tuning.RUNNER_WALK_REF_SPEED,
	"sprint_ref_speed": Tuning.RUNNER_SPRINT_REF_SPEED,
}

# Yeni zıplayan (Tuning.FEATURE_JUMPER_MODEL): 3 çeşit GLB (ZombieVisual.VC_MODELS[jumper_v]). Çömelme (0.7 sn) WINDUP'a,
# leap (0.9 sn) JUMP'a, land (0.8 sn, bir kez; sonra idle) RECOVER'a oturur. Boy 1.38 m (walk 2.4 m/sn bu boya göre).
const _JUMPER_LOOK_V: Dictionary = {
	"model": &"jumper_v",
	"height": 1.38,
	"anim_idle": [&"idle"],
	"anim_walk": [&"walk"],
	"anim_attack": [&"crouch"],
	"anim_air": [&"leap"],
	"anim_land": [&"land"],
	"anim_stagger": [&"stagger"],
	"anim_death": [&"death_a", &"death_b"],
	"anim_spawn": [&"spawn"],
	"walk_ref_speed": Tuning.JUMPER_WALK_REF_SPEED,
}

# Yeni tank (Tuning.FEATURE_TANK_MODEL): 4 çeşit GLB (ZombieVisual.VC_MODELS[tank_v]). Saldırı klibi (1.6 sn) vuruşu
# 0.90 sn'de: attack_windup (0.9) ile birebir; WINDUP'ta hızı ~1.0, RECOVER'da sonuna dek tamamlanır.
# Boy 2.3 m (Taha 2026-11-20: 1.85 küçük kaldı; yarıçap 0.75 ve erişim 1.5 eski 2.4 m tanka göreydi, uyar).
const _TANK_LOOK_V: Dictionary = {
	"model": &"tank_v",
	"height": 2.3,
	"anim_idle": [&"idle"],
	"anim_walk": [&"walk"],
	"anim_attack": [&"attack"],
	"anim_stagger": [&"stagger"],
	"anim_death": [&"death_a", &"death_b"],
	"anim_spawn": [&"spawn"],
	"attack_anim_hit_time": 0.9,
	"recover_finishes_attack": true,
	"walk_ref_speed": Tuning.TANK_WALK_REF_SPEED,
}

const _OVERRIDES: Dictionary = {
	# Zıplayan: askere 7 m kala çömelir, yerde işaret çıkar (ilk 0.4 sn askeri önden izler, son 0.3 sn kilitli),
	# yay çizerek havalanıp işaretli yere iner. Havadayken vurulamaz. İniş: alan hasarı (land_radius).
	# Kurtulmak: halkadan çıkmak ya da dash dokunulmazlığı. İnişten sonra jump'ın toparlanması zayıf nokta.
	&"jumper": {
		"id": &"jumper",
		"model": &"jumper",
		"max_hp": 40.0,
		"speed": 3.0,
		"contact_damage": 14.0,
		"radius": 0.42,
		"attack_kind": &"jump",
		"jump_range": 7.0,
		"attack_windup": 0.7,
		"attack_recover": 1.6,
		"jump_time": 0.9,
		"jump_height": 3.5,
		"jump_lock_time": 0.3,
		"jump_lead": 0.9,
		"jump_max_range": 9.0,
		"land_radius": 1.5,
		"attack_anim_hit_time": 0.0,
		"prewarm": 12,
		"drop_value": 6,
		"weight": 0.9,
		"stagger_time": 0.2,
		"height": 1.75,
		"color": Color(0.85, 0.6, 0.2),
		"anim_attack": [&"pounce_windup"],
		"anim_air": [&"leap"],
	},
	# Dilci: uzakta (tongue_range) durup 0.55 sn hazırlanır (son 0.25 sn yön kilitli), dilini fırlatır.
	# Yeni mekanik (Tuning.FEATURE_TONGUE_PULL): dil tongue_speed m/sn ile düz uçar; ucun yolu askere
	# (yarıçap + tongue_hit_radius) değerse yakalar (dash dokunulmazlığı kaçırır). Yakalanan asker dilciye
	# tongue_pull_speed m/sn ile çekilir (hareket ve dash yok, silahlar çalışır); dilci ölünce, tongue_pull_time
	# dolunca ya da asker temas + tongue_release_gap'e gelince bırakır (yakına geldiyse ısırır: contact_damage).
	# Eski mekanik: anlık ışın, isabette root_time sn bağ.
	# Yakın vuruş (Tuning.FEATURE_TONGUE_MELEE): hazırlığa girerken asker temas + tongue_melee_range içindeyse dil
	# atılmaz; tongue_melee_windup sn hazırlanıp şaklar, vuruş anında asker temas + tongue_melee_hit_range içindeyse
	# contact_damage vurur, tongue_melee_recover sn toparlanır.
	&"tongue": {
		"id": &"tongue",
		"model": &"tongue",
		"max_hp": 35.0,
		"speed": 3.2, # eski 2.4
		"contact_damage": 6.0,
		"radius": 0.42,
		"attack_kind": &"tongue",
		"tongue_range": 7.5,
		"attack_windup": 0.55, # eski 0.8
		"tongue_lock_time": 0.25, # eski 0.3
		"tongue_melee_range": 0.9,
		"tongue_melee_windup": 0.3,
		"tongue_melee_hit_range": 0.8,
		"tongue_melee_recover": 0.8,
		"tongue_hit_radius": 0.35,
		"root_time": 1.0,
		"tongue_speed": 16.0,
		"tongue_lead": 0.0,
		"tongue_pull_speed": 1.8,
		"tongue_pull_time": 3.0,
		"tongue_release_gap": 0.25,
		"attack_recover": 3.0, # eski 5.0
		"tongue_miss_recover": 1.2, # eski 2.0
		"attack_anim_hit_time": 0.0,
		"prewarm": 8,
		"drop_value": 8,
		"weight": 1.0,
		"stagger_time": 0.22,
		"height": 1.7,
		"color": Color(0.7, 0.35, 0.5),
		"anim_attack": [&"tongue_windup"],
		# Yeni hat (Tuning.FEATURE_DILCI_MODEL): model ZombieVisual.VC_MODELS'tan, klipler modelin kendi
		# klipleri (tools/blender/dilci_anims.py). Açıkken bu alanlar satırın üstüne yazılır.
		"look_v": {
			"model": &"dilci",
			"anim_idle": [&"idle"],
			"anim_walk": [&"walk"],
			"anim_attack": [&"windup"],
			"anim_lash": [&"lash"],
			"anim_pull": [&"pull"],
			"anim_stagger": [&"stagger"],
			"anim_death": [&"death_a"],
			"anim_spawn": [&"spawn"],
		},
	},
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
		# Yeni koşu saldırısı (Tuning.FEATURE_RUNNER_SPRINT): askere sprint_trigger_range kala yerinde bir kez
		# çığlık (WINDUP = scream_time), sonra ölene dek SPRINT: sprint_speed ile koşar, dönüşü sprint_turn_rate
		# (rad/sn) ile sınırlı (yana dash ıskalatır, geniş yay çizip geri döner, durmaz). Temas + strike_range'e
		# girince STRIKE: strike_hit_time sn sonra pençe iner (temas + strike_hit_range içindeyse contact_damage),
		# ardından strike_recover sn dönmeden geçip gider (askerin içinden; temas çözümü yok) ve yine SPRINT: yay çizip
		# yeniden gelir. Hız çarpanları: vuruşa kadar strike_move_factor, geçerken strike_recover_factor. Pençe yalnız
		# koşu yönü askere dönükken başlar (aim · askere yön >= strike_face_dot). Asker sprint_trigger_range ×
		# sprint_give_up_factor'dan uzaklaşırsa CHASE.
		# Açıkken bu alanlar satırın üstüne yazılır (attack_kind &"sprint").
		"sprint_v": {
			"attack_kind": &"sprint",
			"sprint_trigger_range": 9.0,
			"scream_time": 0.6,
			"sprint_speed": 6.5,
			"sprint_turn_rate": 2.4,
			"sprint_give_up_factor": 2.0,
			"strike_range": 0.5,
			"strike_hit_range": 0.9,
			"strike_hit_time": 0.25,
			"strike_recover": 0.5,
			"strike_move_factor": 0.8,
			"strike_recover_factor": 1.0,
			"strike_face_dot": 0.5,
			# Eski modelde paylaşılan klipler: koşu run_a/b, pençe yürüyenin attack klibi (vuruşu 0.7 sn'de).
			# Yeni modelde: anim_sprint [sprint], anim_strike [strike], strike_anim_hit_time 0.25.
			"anim_sprint": [&"run_a", &"run_b"],
			"anim_strike": [&"attack"],
			"strike_anim_hit_time": 0.7,
			"sprint_anim_speed": 1.15,
		},
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

## Genel tempoyla (Tuning.GAME_PACE) çarpılan hız alanları (m/sn). Referans hızlar (walk_ref_speed) çarpılmaz.
const PACED_KEYS: Array[String] = ["speed", "lunge_speed", "sprint_speed", "tongue_speed", "tongue_pull_speed"]

static var TABLE: Dictionary = _build()


static func _build() -> Dictionary:
	var walker: Dictionary = _WALKER_ROW.duplicate()
	if Tuning.FEATURE_WALKER_MODEL:
		walker.merge(_WALKER_LOOK_V, true)
	var table: Dictionary = {&"walker": _paced(walker.duplicate())}
	_add_specials(table, walker)
	for id: StringName in _OVERRIDES:
		var row: Dictionary = _WALKER_ROW.duplicate()
		row.merge(_OVERRIDES[id], true)
		if Tuning.FEATURE_DILCI_MODEL and row.has("look_v"):
			row.merge(row["look_v"], true)
		if Tuning.FEATURE_RUNNER_SPRINT and row.has("sprint_v"):
			row.merge(row["sprint_v"], true)
			# Çığlık, hazırlık (WINDUP) süresidir.
			row["attack_windup"] = row["scream_time"]
			if id == RUNNER and Tuning.FEATURE_RUNNER_MODEL:
				row.merge(_RUNNER_LOOK_V, true)
		if id == JUMPER and Tuning.FEATURE_JUMPER_MODEL:
			row.merge(_JUMPER_LOOK_V, true)
		if id == TANK and Tuning.FEATURE_TANK_MODEL:
			row.merge(_TANK_LOOK_V, true)
		table[id] = _paced(row)
	return table


## 7.3 beş özel tür (EnemyDataSpecials): yürüyenin modeli ve klipleri üstüne satır; model bayrağı açıksa look_v.
static func _add_specials(table: Dictionary, walker: Dictionary) -> void:
	for id: StringName in EnemyDataSpecials.ROWS:
		var row: Dictionary = walker.duplicate()
		row.merge(EnemyDataSpecials.ROWS[id], true)
		if EnemyDataSpecials.model_enabled(id):
			row.merge(row["look_v"], true)
		table[id] = _paced(row)


## Bu tür oyunda açık mı (davranış bayrağı); kapalıysa dalga karışımına girmez.
static func kind_enabled(id: StringName) -> bool:
	return EnemyDataSpecials.behavior_enabled(id)


static func _paced(row: Dictionary) -> Dictionary:
	for key: String in PACED_KEYS:
		if row.has(key):
			row[key] = float(row[key]) * Tuning.GAME_PACE
	return row


static func get_row(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen zombi türü: %s" % id)
	return TABLE[id]


static func lunges(row: Dictionary) -> bool:
	return row["attack_kind"] == &"lunge"


static func sprints(row: Dictionary) -> bool:
	return row["attack_kind"] == &"sprint"


static func jumps(row: Dictionary) -> bool:
	return row["attack_kind"] == &"jump"


static func tongues(row: Dictionary) -> bool:
	return row["attack_kind"] == &"tongue"


## Yürüyenden farklı saldırı düzeni var mı (hazırlıkta duruşu tutar, saldırı manager'da özel).
static func is_special(row: Dictionary) -> bool:
	return row["attack_kind"] != &"melee"
