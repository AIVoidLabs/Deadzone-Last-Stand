class_name WaveData
extends RefCounted
## Dalga tablosu. Yeni dalga = yeni satır (Aşama 11'de sayılar hedefe çekilir).
## Dalga içinde doğma aralığı (sn) ve grup boyu başlangıçtan sona doğrusal değişir.
## max_alive: aynı anda en çok canlı zombi; kalite profilinin sınırıyla ayrıca kırpılır.
## mix: tür → ağırlık (EnemyData satırları); davranış bayrağı kapalı tür karışımdan düşer (active_mix).
## max_alive_kind (isteğe bağlı): tür → aynı anda en çok canlı sayısı; sınırdaki tür yerine başkası seçilir (SpawnRules.pick_kind_capped).
## boss (isteğe bağlı): {kind, spawn_time, horde_factor?}; WaveRun boss akışı (spawn_time'da uyarı, uyarı sonunda doğar, ölünce dalga biter).
## 6.6 ilk denge: tabanca + 1–2 mağaza alımıyla 3. dalgayı, 3–4 silahla 5. dalgayı geçebilecek tırmanış.

const WAVES: Array = [
	{
		"duration": 20.0,
		"interval_start": 1.1, "interval_end": 0.8,
		"batch_start": 1, "batch_end": 1,
		"max_alive": 60,
		"mix": {&"walker": 1.0},
	},
	{
		"duration": 30.0,
		"interval_start": 0.9, "interval_end": 0.55,
		"batch_start": 1, "batch_end": 2,
		"max_alive": 90,
		"mix": {&"walker": 1.0, &"runner": 0.12, &"armored": 0.04},
	},
	{
		"duration": 40.0,
		"interval_start": 0.8, "interval_end": 0.5,
		"batch_start": 1, "batch_end": 3,
		"max_alive": 120,
		"mix": {&"walker": 1.0, &"runner": 0.18, &"jumper": 0.06, &"armored": 0.05, &"spitter": 0.04, &"bloater": 0.05},
	},
	{
		"duration": 50.0,
		"interval_start": 0.7, "interval_end": 0.4,
		"batch_start": 2, "batch_end": 4,
		"max_alive": 180,
		"mix": {&"walker": 1.0, &"runner": 0.2, &"jumper": 0.09, &"tongue": 0.03, &"tank": 0.03,
				&"armored": 0.06, &"spitter": 0.05, &"thrower": 0.04, &"bloater": 0.06, &"screamer": 0.015},
		"max_alive_kind": {&"screamer": 2},
	},
	{
		"duration": 60.0,
		"interval_start": 0.6, "interval_end": 0.3,
		"batch_start": 2, "batch_end": 5,
		"max_alive": 260,
		"mix": {&"walker": 1.0, &"runner": 0.22, &"jumper": 0.12, &"tongue": 0.05, &"tank": 0.05,
				&"armored": 0.07, &"spitter": 0.06, &"thrower": 0.05, &"bloater": 0.07, &"screamer": 0.02},
		"max_alive_kind": {&"screamer": 2},
		"boss": {"kind": &"boss_heap", "spawn_time": 12.0},
	},
]


## Karışımdan davranış bayrağı kapalı türleri çıkarır (yürüyen her zaman kalır).
static func active_mix(mix: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for kind: StringName in mix:
		if EnemyData.kind_enabled(kind):
			result[kind] = mix[kind]
	return result
