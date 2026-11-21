class_name EnemyDataSpecials
extends RefCounted
## 7.3 beş özel tür satırları (tek kaynak: build/briefs/s73_design.md). EnemyData._build() bunları yürüyen satırının üstüne yazar.
## Hızlar "tempo öncesi"dir (EnemyData GAME_PACE ile çarpar). Model GLB'si yokken (FEATURE_<ID>_MODEL kapalı) satır
## yürüyenin modelini ve kliplerini kullanır; tür farkı `tint` ile (köşe rengi çarpanı) görünür.
## Model bayrağı açılınca `look_v` alanları üste yazılır (model `<id>_v`, modelin kendi klipleri).
## attack_kind: &"melee" (zırhlı: zırh + dönüş C2), &"spit" / &"throw" (LobAttack; <ön ek>_range/_lock/_lead/_flight/_arc),
## &"scream" (çığlıkçı) ve &"bloat" (patlayıcı) C2'de işlenir.

const ROWS: Dictionary = {
	# Zırhlı: önden mermi hasarı azalır (ArmorRules); armor_turn_rate ile yavaş döner.
	&"armored": {
		"id": &"armored",
		"max_hp": 90.0,
		"speed": 2.0,
		"contact_damage": 16.0,
		"radius": 0.5,
		"attack_kind": &"melee",
		"attack_range": 0.45,
		"attack_hit_range": 1.0,
		"attack_windup": 0.7,
		"attack_recover": 0.7,
		"attack_anim_hit_time": 0.7,
		"spawn_time": 1.1,
		"prewarm": 12,
		"drop_value": 10,
		"weight": 2.5,
		"stagger_time": 0.15,
		"height": 1.9,
		"color": Color(0.2, 0.28, 0.5),
		"tint": Color(0.45, 0.55, 1.0),
		"steer": &"armor",
		"armor_front_half_deg": 60.0,
		"armor_front_factor": 0.25,
		"armor_back_factor": 1.3,
		"armor_turn_rate": 1.8,
		"look_v": {
			"model": &"armored_v", "tint": Color.WHITE, "walk_ref_speed": Tuning.ARMORED_WALK_REF_SPEED,
			"anim_idle": [&"idle"], "anim_walk": [&"walk"], "anim_attack": [&"attack"], "anim_stagger": [&"stagger"],
			"anim_death": [&"death_a", &"death_b"], "anim_spawn": [&"spawn"],
			# Vuruş klipte 0.70 sn (= attack_windup); toparlanmada klip sonuna dek oynar.
			"recover_finishes_attack": true,
		},
	},
	# Çığlıkçı: mesafe korur (scream_keep_min), scream_time sn çığlık atıp scream_count yürüyen çağırır.
	&"screamer": {
		"id": &"screamer",
		"max_hp": 30.0,
		"speed": 2.2,
		"contact_damage": 6.0,
		"radius": 0.38,
		"attack_kind": &"scream",
		"steer": &"scream",
		"recover_walks": true,
		"scream_range": 10.0,
		"scream_keep_min": 6.0,
		"scream_time": 1.2,
		"scream_radius": 2.5,
		"scream_count": 3,
		"scream_max_alive": 6,
		"scream_cooldown": 6.0,
		# Çığlık hazırlıktır (WINDUP), bekleme toparlanmadır (RECOVER).
		"attack_windup": 1.2,
		"attack_recover": 6.0,
		"attack_anim_hit_time": 0.0,
		"spawn_time": 1.0,
		"prewarm": 4,
		"drop_value": 12,
		"weight": 0.8,
		"stagger_time": 0.25,
		"height": 1.95,
		"color": Color(0.6, 0.5, 0.7),
		"tint": Color(0.85, 0.7, 1.0),
		"look_v": {
			"model": &"screamer_v", "tint": Color.WHITE, "walk_ref_speed": Tuning.SCREAMER_WALK_REF_SPEED,
			"anim_idle": [&"idle"], "anim_walk": [&"walk"], "anim_attack": [&"scream"], "anim_stagger": [&"stagger"],
			"anim_death": [&"death_a", &"death_b"], "anim_spawn": [&"spawn"],
			# Klipte çığlık tepe anı (sn).
			"scream_peak_start": 0.55, "scream_peak_end": 1.0,
		},
	},
	# Tükürücü: spit_range'de durur, askerin gideceği yere asit topu atar; düştüğü yerde asit havuzu kalır.
	&"spitter": {
		"id": &"spitter",
		"max_hp": 35.0,
		"speed": 2.4,
		"contact_damage": 8.0,
		"radius": 0.42,
		"attack_kind": &"spit",
		"spit_range": 8.0,
		"attack_windup": 0.8,
		"spit_lock": 0.25,
		"spit_lead": 0.5,
		"spit_flight": 0.9,
		"spit_arc": 2.5,
		"acid_radius": 1.6,
		"acid_time": 5.0,
		"acid_tick": 0.5,
		"acid_damage": 4.0,
		"attack_recover": 2.2,
		"attack_anim_hit_time": 0.8,
		"spawn_time": 1.0,
		"prewarm": 10,
		"drop_value": 8,
		"weight": 1.0,
		"stagger_time": 0.22,
		"height": 1.7,
		"color": Color(0.35, 0.7, 0.25),
		"tint": Color(0.6, 1.0, 0.5),
		"look_v": {
			"model": &"spitter_v", "tint": Color.WHITE, "walk_ref_speed": Tuning.SPITTER_WALK_REF_SPEED,
			"anim_idle": [&"idle"], "anim_walk": [&"walk"], "anim_attack": [&"spit"], "anim_stagger": [&"stagger"],
			"anim_death": [&"death_a", &"death_b"], "anim_spawn": [&"spawn"],
			# Bırakış WINDUP'un sonunda (0.80); toparlanmada klip sonuna dek oynar. Top ağızdan (Head kemiği) çıkar;
			# hazırlıkta kese parlar (yeşil swell).
			"recover_finishes_attack": true,
			"spit_mouth": {"bone": "Head", "offset": Vector3(0.0, 0.014, 0.14)},
			"windup_glow": true, "swell_color": Vector3(0.4, 1.0, 0.15),
		},
	},
	# Taş fırlatan: throw_range'de durur, kaya fırlatır (throw_radius içinde contact_damage); yakında dev kolla vurur (swat).
	&"thrower": {
		"id": &"thrower",
		"max_hp": 45.0,
		"speed": 2.3,
		"contact_damage": 14.0,
		"radius": 0.48,
		"attack_kind": &"throw",
		"throw_range": 11.0,
		"attack_windup": 0.9,
		"throw_lock": 0.3,
		"throw_lead": 0.6,
		"throw_flight": 1.0,
		"throw_arc": 3.5,
		"throw_radius": 1.1,
		"attack_recover": 1.8,
		# Yakın vuruş: temas + throw_melee_range içindeyse; vuruş yürüyenin vuruşu gibi hasar verir.
		"throw_melee_range": 0.6,
		"throw_melee_windup": 0.6,
		"throw_melee_hit_range": 0.9,
		"throw_melee_recover": 0.8,
		"attack_anim_hit_time": 0.9,
		"spawn_time": 1.1,
		"prewarm": 8,
		"drop_value": 9,
		"weight": 1.6,
		"stagger_time": 0.2,
		"height": 1.8,
		"color": Color(0.5, 0.35, 0.22),
		"tint": Color(1.0, 0.8, 0.55),
		"look_v": {
			"model": &"thrower_v", "tint": Color.WHITE, "walk_ref_speed": Tuning.THROWER_WALK_REF_SPEED,
			"anim_idle": [&"idle"], "anim_walk": [&"walk"], "anim_attack": [&"throw"], "anim_swat": [&"swat"],
			"throw_melee_anim_hit_time": 0.6, "anim_stagger": [&"stagger"],
			# Kaya WINDUP'ta klibin 0.30 sn'sinden bırakışa dek sağ elde (kemik yerel ofseti); toparlanmada klip sonuna dek oynar.
			"recover_finishes_attack": true,
			"held_prop": {"bone": "RightHand", "offset": Vector3(0.049, -0.18, 0.162), "show_time": 0.3},
			"anim_death": [&"death_a", &"death_b"], "anim_spawn": [&"spawn"],
		},
	},
	# Patlayıcı: temas + bloat_prime_range'e girince şişer (bloat_prime_time) ve bloat_radius'ta patlar.
	&"bloater": {
		"id": &"bloater",
		"max_hp": 50.0,
		"speed": 2.4,
		"contact_damage": 0.0,
		"radius": 0.6,
		"attack_kind": &"bloat",
		"bloat_prime_range": 1.4,
		"bloat_prime_time": 0.9,
		"bloat_radius": 3.0,
		"bloat_player_damage": 28.0,
		# Askere hasar mesafeye göre: merkezde tam, kenarda bu kesir.
		"bloat_edge_factor": 0.5,
		"bloat_zombie_damage": 80.0,
		"bloat_death_fuse": 0.15,
		"attack_range": 1.4,
		"attack_windup": 0.9,
		"attack_recover": 0.0,
		"attack_anim_hit_time": 0.0,
		"spawn_time": 1.2,
		"prewarm": 12,
		"drop_value": 7,
		"weight": 2.0,
		"stagger_time": 0.3,
		"height": 1.75,
		"color": Color(0.85, 0.5, 0.15),
		"tint": Color(1.0, 0.7, 0.4),
		"look_v": {
			"model": &"bloater_v", "tint": Color.WHITE, "walk_ref_speed": Tuning.BLOATER_WALK_REF_SPEED,
			"anim_idle": [&"idle"], "anim_walk": [&"walk"], "anim_attack": [&"swell"], "anim_stagger": [&"stagger"],
			"anim_death": [&"death_a"], "anim_spawn": [&"spawn"],
		},
	},
}


## Bu türün davranış bayrağı açık mı (kapalı tür dalga karışımına girmez; bkz. WaveData.active_mix).
static func behavior_enabled(id: StringName) -> bool:
	match id:
		&"armored":
			return Tuning.FEATURE_ZOMBIE_ARMOR
		&"screamer":
			return Tuning.FEATURE_ZOMBIE_SCREAM
		&"spitter":
			return Tuning.FEATURE_ZOMBIE_SPIT
		&"thrower":
			return Tuning.FEATURE_ZOMBIE_THROW
		&"bloater":
			return Tuning.FEATURE_ZOMBIE_BLOAT
	return true


## Bu türün Blender modeli açık mı (kapalıyken yürüyenin modeli + tint).
static func model_enabled(id: StringName) -> bool:
	match id:
		&"armored":
			return Tuning.FEATURE_ARMORED_MODEL
		&"screamer":
			return Tuning.FEATURE_SCREAMER_MODEL
		&"spitter":
			return Tuning.FEATURE_SPITTER_MODEL
		&"thrower":
			return Tuning.FEATURE_THROWER_MODEL
		&"bloater":
			return Tuning.FEATURE_BLOATER_MODEL
	return false
