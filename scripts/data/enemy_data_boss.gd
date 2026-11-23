class_name EnemyDataBoss
extends RefCounted
## 7.4 boss "Yığın" satırı (tek kaynak: build/briefs/s74_boss.md). EnemyData._build() bunu yürüyen satırının üstüne yazar.
## Hızlar "tempo öncesi"dir (EnemyData GAME_PACE ile çarpar; charge_speed PACED_KEYS'te). Blender modeli yokken
## (FEATURE_BOSS_MODEL kapalı) büyütülmüş tank modeli + kızıl tint; model hazır olunca `look_v` üste yazılır
## (ZombieModelData.VC_MODELS[boss_heap_v]) ve klipler modelin kendi klipleridir.
## Saldırı düzeni: BossRules + BossAttack. Hazırlık süreleri WINDUP, bekleme RECOVER, hücum CHARGE, duvar sersemi STUN, öfke kükremesi ROAR.

const ID: StringName = &"boss_heap"

const ROW: Dictionary = {
	"id": &"boss_heap",
	"boss": true,
	"model": &"tank_v",
	"max_hp": 2200.0,
	"speed": 1.6,
	"contact_damage": 30.0,
	"radius": 1.4,
	"attack_kind": &"boss",
	"spawn_time": 2.0,
	"prewarm": 1,
	"drop_value": 150,
	# drop_chance yok: boss her zaman kristal yağmuru bırakır (BossFx).
	"weight": 50.0,
	"stagger_time": 0.0,
	"height": 3.6,
	"color": Color(0.5, 0.22, 0.2),
	"tint": Color(1.0, 0.42, 0.38),
	# Ölüm klibi + gövde yere yatıp kalma + solma (sn); klip hızı 1.0 (boss ağır düşer).
	"death_duration": 4.5,
	"death_anim_speed": 1.0,
	"walk_ref_speed": Tuning.BOSS_WALK_REF_SPEED,
	# Göğüs yarığı (parıltı maskesi = köşe rengi alfası): dinlenirken, öfkede (swell kanalı) ve rengi.
	"glow_rest": 0.45,
	"glow_rage": 1.0,
	"swell_color": Vector3(1.0, 0.12, 0.05),
	# Saldırı düzeni: iki saldırı arası bekleme (sn, CHASE'de akar) ve ağırlıklar (BossRules.pick).
	"boss_pause": 1.2,
	"attack_weights": {&"slam": 3.0, &"charge": 3.0, &"summon": 4.0},
	# Yer dövme: slam_range içinde; iniş anında şok halkası (hız m/sn, son yarıçap, kalınlık), halka isabeti ve merkez hasarı.
	"slam_range": 6.0,
	"slam_windup": 1.1,
	"slam_recover": 1.0,
	"slam_ring_speed": 7.0,
	"slam_ring_max": 9.0,
	"slam_ring_width": 0.6,
	"slam_damage": 22.0,
	"slam_center_radius": 2.2,
	"slam_center_damage": 30.0,
	# Öfkede ikinci halka bu kadar sn sonra.
	"slam_ring_gap": 0.45,
	# Hücum: charge_min..charge_max mesafede; hazırlıkta şerit işareti (son charge_lock_time sn yön kilitli), sonra kilitli yönde koşu.
	"charge_min": 6.0,
	"charge_max": 14.0,
	"charge_windup": 1.0,
	"charge_lock_time": 0.3,
	"charge_speed": 11.0,
	"charge_time": 1.1,
	"charge_damage": 35.0,
	"charge_zombie_damage": 40.0,
	"charge_recover": 0.8,
	# Duvara çarpınca sersem (fırsat penceresi).
	"charge_stun_time": 1.4,
	# Çağrı: her mesafede, summon_cooldown arayla; summon_first_delay ilk çağrıya kadar; çevresine summon_kind doğar.
	"summon_cooldown": 14.0,
	"summon_first_delay": 6.0,
	"summon_windup": 1.3,
	"summon_recover": 0.8,
	"summon_count": 5,
	"summon_kind": &"runner",
	# Doğan zombiler boss gövdesinin bu kadar dışında halkada belirir (m).
	"summon_ring_gap": 2.0,
	# Öfke evresi: can oranı eşiği, kükreme süresi/ses dalgası yarıçapı, hız ve hazırlık çarpanları.
	"rage_threshold": 0.5,
	"rage_roar": 1.5,
	"roar_radius": 3.5,
	"rage_speed_factor": 1.3,
	"rage_windup_factor": 0.8,
	# Klipler (yedek: tank_v klipleri). Yer dövme klibinin iniş anı (sn); hazırlık süresine oturur.
	"anim_idle": [&"idle"],
	"anim_walk": [&"walk"],
	"anim_attack": [&"attack"],
	"anim_slam": [&"attack"],
	"slam_anim_hit_time": 0.9,
	"anim_charge_windup": [&"attack"],
	"anim_charge": [&"walk"],
	# Yedek model: yürüme klibi hücumda hızlı döner (gerçek modelde klip hücum hızına anahtarlı, 1.0).
	"charge_anim_speed": 2.5,
	"anim_stun": [&"stagger"],
	"anim_summon": [&"attack"],
	"anim_roar": [&"attack"],
	"anim_stagger": [&"stagger"],
	"anim_death": [&"death_a"],
	"anim_spawn": [&"spawn"],
	"attack_anim_hit_time": 0.9,
	"recover_finishes_attack": true,
}

# 11.F kusmuk yağmuru (FEATURE_BOSS_SPEW): yalnız bayrak açıkken ROW'un üstüne yazılır. Asker spew_min..spew_max arasında;
# spew_far_dist'ten uzaktaysa ağırlık spew_far_mult katı. Hazırlıkta askere döner; atış anı (klibin kusma anı) spew_anim_hit_time.
# spew_count top (öfkede spew_count_rage), spew_spread derecelik yelpaze; top askere uzaklığın [spew_dist_lo, spew_dist_hi] katına iner.
# Toplar tükürücünün yay atışı + asit havuzu yolunu kullanır (spew_pool_*, spew_acid_*); doğrudan isabet spew_damage.
# Yedek klip: roar (modelde spew klibi yokken / FEATURE_BOSS_SPEW_CLIP kapalıyken), kusma anı spew_fallback_hit_time.
## Kusmuğun seçim ağırlığı; ROW'daki attack_weights'e eklenir (diğerleri korunur).
const SPEW_WEIGHT: float = 4.0
const SPEW_ROW: Dictionary = {
	"spew_min": 10.0,
	"spew_max": 30.0,
	"spew_far_dist": 14.0,
	"spew_far_mult": 2.0,
	"spew_windup": 1.3,
	"spew_recover": 1.0,
	"spew_count": 5,
	"spew_count_rage": 7,
	"spew_spread": 50.0,
	"spew_dist_lo": 0.7,
	"spew_dist_hi": 1.15,
	"spew_ball_speed": 16.0,
	"spew_flight_min": 0.7,
	"spew_flight_max": 1.8,
	"spew_arc_per_sec": 2.8,
	"spew_release_height": 2.6,
	"spew_escape_len": 3.0,
	"spew_pool_radius": 1.6,
	"spew_pool_life": 5.0,
	"spew_acid_tick": 0.5,
	"spew_acid_damage": 4.0,
	"spew_damage": 14.0,
	"anim_spew": [&"roar"],
	"spew_anim_hit_time": 0.9,
	"spew_fallback_hit_time": 0.9,
}

# 11.F zincir hücum (FEATURE_BOSS_CHAIN_CHARGE): öfkede hücum bitince (duvara çarpmadıysa) toplam charge_chain_rage hücum;
# aralarında charge_chain_windup sn yeniden nişan (şerit askere döner, son charge_lock_time sn kilitli).
const CHAIN_ROW: Dictionary = {
	"charge_chain_rage": 3,
	"charge_chain_windup": 0.45,
}

# 11.F yanan yarık izi (FEATURE_BOSS_CHARGE_TRAIL): hücumda trail_step aralıkla parça; trail_life sn yanar (son trail_fade sn söner).
const TRAIL_ROW: Dictionary = {
	"trail_step": 1.2,
	"trail_life": 3.5,
	"trail_fade": 0.8,
	"trail_radius": 0.9,
	"trail_burn_dps": 10.0,
	"trail_burn_tick": 0.25,
	"trail_max": 40,
}

# Modelde spew klibi hazır olunca (FEATURE_BOSS_SPEW_CLIP) kusmuk klibi ve anı.
const LOOK_V_SPEW: Dictionary = {
	"anim_spew": [&"spew"],
	"spew_anim_hit_time": 0.85,
}

# Blender modeli (assets/models/characters/boss_heap.glb) bağlanınca: modelin kendi klipleri, birebir adlar (s74_boss.md).
const LOOK_V: Dictionary = {
	"model": &"boss_heap_v",
	"tint": Color.WHITE,
	"anim_slam": [&"slam"],
	"slam_anim_hit_time": 1.1,
	"anim_charge_windup": [&"charge_windup"],
	"anim_charge": [&"charge"],
	"anim_stun": [&"stun"],
	"anim_summon": [&"summon"],
	"anim_roar": [&"roar"],
	"anim_attack": [&"slam"],
	"attack_anim_hit_time": 1.1,
	"anim_stagger": [&"idle"],
	"anim_death": [&"death"],
	"charge_anim_speed": 1.0,
}


## Boss satırı: yürüyenin üstüne ROW (+ model hazırsa LOOK_V).
## Bayraklar parametreyle (testler kapalı hâli de kurabilsin); varsayılan Tuning'den. Kapalı bayrağın anahtarları satırda olmaz.
static func build(walker: Dictionary, spew: bool = Tuning.FEATURE_BOSS_SPEW, chain: bool = Tuning.FEATURE_BOSS_CHAIN_CHARGE,
		trail: bool = Tuning.FEATURE_BOSS_CHARGE_TRAIL, spew_clip: bool = Tuning.FEATURE_BOSS_SPEW_CLIP) -> Dictionary:
	var row: Dictionary = walker.duplicate()
	row.merge(ROW, true)
	if spew:
		var weights: Dictionary = (row["attack_weights"] as Dictionary).duplicate()
		weights[&"spew"] = SPEW_WEIGHT
		row.merge(SPEW_ROW, true)
		row["attack_weights"] = weights
	if chain:
		row.merge(CHAIN_ROW, true)
	if trail:
		row.merge(TRAIL_ROW, true)
	if Tuning.FEATURE_BOSS_MODEL:
		row.merge(LOOK_V, true)
		if spew and spew_clip:
			row.merge(LOOK_V_SPEW, true)
	return row
