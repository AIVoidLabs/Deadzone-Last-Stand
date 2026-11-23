class_name WaveData
extends RefCounted
## Dalga tablosu. Yeni dalga = yeni satır (Aşama 11'de sayılar hedefe çekilir).
## Dalga içinde doğma aralığı (sn) ve grup boyu başlangıçtan sona doğrusal değişir.
## max_alive: aynı anda en çok canlı zombi; kalite profilinin sınırıyla ayrıca kırpılır.
## mix: tür → ağırlık (EnemyData satırları); davranış bayrağı kapalı tür karışımdan düşer (active_mix).
## max_alive_kind (isteğe bağlı): tür → aynı anda en çok canlı sayısı; sınırdaki tür yerine başkası seçilir (SpawnRules.pick_kind_capped).
## boss (isteğe bağlı): {kind, spawn_time, horde_factor?}; WaveRun boss akışı (spawn_time'da uyarı, uyarı sonunda doğar, ölünce dalga biter).
## enemy_hp_mult / enemy_damage_mult (isteğe bağlı, yoksa 1.0): o dalgada doğan zombilerin can ve asker hasarı çarpanı (boss hariç; WaveScaling).
## 11.2 taslağı: 10 dalga. Türler kademeli girer (2 koşan, 3 zırhlı+sıçrayan, 4 tükürücü+şişkin, 5 tank, 6 dilci, 7 fırlatıcı+çığlıkçı); 10. dalgada boss. Sayılar 11.2 bot ölçümüyle ayarlandı (DECISIONS 2026-11-23 hedef bandı).

const WAVES: Array = [
	{
		"enemy_hp_mult": 1.00, "enemy_damage_mult": 1.00,
		"duration": 20.0,
		"interval_start": 1.1, "interval_end": 0.8,
		"batch_start": 1, "batch_end": 1,
		"max_alive": 50,
		"mix": {&"walker": 1.0},
	},
	{
		"enemy_hp_mult": 1.00, "enemy_damage_mult": 1.00,
		"duration": 25.0,
		"interval_start": 1.05, "interval_end": 0.74,
		"batch_start": 1, "batch_end": 2,
		"max_alive": 70,
		"mix": {&"walker": 1.0, &"runner": 0.1},
	},
	{
		"enemy_hp_mult": 1.00, "enemy_damage_mult": 1.00,
		"duration": 30.0,
		"interval_start": 0.99, "interval_end": 0.68,
		"batch_start": 1, "batch_end": 2,
		"max_alive": 90,
		"mix": {&"walker": 1.0, &"runner": 0.14, &"armored": 0.04, &"jumper": 0.05},
	},
	{
		"enemy_hp_mult": 1.04, "enemy_damage_mult": 1.00,
		"duration": 35.0,
		"interval_start": 0.93, "interval_end": 0.62,
		"batch_start": 1, "batch_end": 3,
		"max_alive": 110,
		"mix": {&"walker": 1.0, &"runner": 0.16, &"armored": 0.05, &"jumper": 0.06, &"spitter": 0.03, &"bloater": 0.04},
	},
	{
		"enemy_hp_mult": 1.08, "enemy_damage_mult": 1.03,
		"duration": 40.0,
		"interval_start": 0.86, "interval_end": 0.56, # 11.2: bot 5–6. dalgada yığılıyordu; sıçrama korunur, yumuşar
		"batch_start": 1, "batch_end": 3,
		"max_alive": 130,
		"mix": {&"walker": 1.0, &"runner": 0.18, &"armored": 0.05, &"jumper": 0.07, &"spitter": 0.04, &"bloater": 0.05, &"tank": 0.02},
	},
	{
		"enemy_hp_mult": 1.10, "enemy_damage_mult": 1.05,
		"duration": 45.0,
		"interval_start": 0.9, "interval_end": 0.6, # 11.2: 6–8. dalga duvarı yumuşatıldı
		"batch_start": 2, "batch_end": 4,
		"max_alive": 150,
		"mix": {&"walker": 1.0, &"runner": 0.19, &"armored": 0.06, &"jumper": 0.09, &"spitter": 0.05, &"bloater": 0.06, &"tank": 0.03, &"tongue": 0.025}, # 11.2: atıcı 7. dalgaya kaydı (6. dalga duvarı)
	},
	{
		"enemy_hp_mult": 1.20, "enemy_damage_mult": 1.09,
		"duration": 50.0,
		"interval_start": 0.82, "interval_end": 0.52,
		"batch_start": 2, "batch_end": 4,
		"max_alive": 170,
		"mix": {&"walker": 1.0, &"runner": 0.2, &"armored": 0.06, &"jumper": 0.1, &"spitter": 0.05, &"bloater": 0.06, &"tank": 0.035, &"thrower": 0.04, &"tongue": 0.03, &"screamer": 0.01},
		"max_alive_kind": {&"screamer": 2},
	},
	{
		"enemy_hp_mult": 1.32, "enemy_damage_mult": 1.14,
		"duration": 55.0,
		"interval_start": 0.76, "interval_end": 0.46,
		"batch_start": 2, "batch_end": 5,
		"max_alive": 200,
		"mix": {&"walker": 1.0, &"runner": 0.21, &"armored": 0.065, &"jumper": 0.1, &"spitter": 0.055, &"bloater": 0.065, &"tank": 0.04, &"thrower": 0.045, &"tongue": 0.04, &"screamer": 0.015},
		"max_alive_kind": {&"screamer": 2},
	},
	{
		"enemy_hp_mult": 1.48, "enemy_damage_mult": 1.20,
		"duration": 60.0,
		"interval_start": 0.56, "interval_end": 0.31, # 11.2: son dalgalar hayatta kalana rahattı
		"batch_start": 2, "batch_end": 5,
		"max_alive": 230,
		"mix": {&"walker": 1.0, &"runner": 0.22, &"armored": 0.07, &"jumper": 0.11, &"spitter": 0.06, &"bloater": 0.07, &"tank": 0.045, &"thrower": 0.05, &"tongue": 0.045, &"screamer": 0.018},
		"max_alive_kind": {&"screamer": 2},
	},
	{
		"enemy_hp_mult": 1.70, "enemy_damage_mult": 1.26,
		"duration": 70.0,
		"interval_start": 0.5, "interval_end": 0.25,
		"batch_start": 2, "batch_end": 5,
		"max_alive": 260,
		"mix": {&"walker": 1.0, &"runner": 0.22, &"armored": 0.07, &"jumper": 0.12, &"spitter": 0.06, &"bloater": 0.07, &"tank": 0.05, &"thrower": 0.05, &"tongue": 0.05, &"screamer": 0.02},
		"max_alive_kind": {&"screamer": 2},
		"boss": {"kind": &"boss_heap", "spawn_time": 15.0},
	},
]


## Karışımdan davranış bayrağı kapalı türleri çıkarır (yürüyen her zaman kalır).
static func active_mix(mix: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for kind: StringName in mix:
		if EnemyData.kind_enabled(kind):
			result[kind] = mix[kind]
	return result
