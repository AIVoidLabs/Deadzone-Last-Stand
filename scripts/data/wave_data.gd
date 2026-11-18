class_name WaveData
extends RefCounted
## Dalga tablosu. Yeni dalga = yeni satır (Aşama 11'de sayılar hedefe çekilir).
## Dalga içinde doğma aralığı (sn) ve grup boyu başlangıçtan sona doğrusal değişir.
## max_alive: aynı anda en çok canlı zombi; kalite profilinin sınırıyla ayrıca kırpılır.
## mix: tür → ağırlık (EnemyData satırları).
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
		"mix": {&"walker": 1.0, &"runner": 0.12},
	},
	{
		"duration": 40.0,
		"interval_start": 0.8, "interval_end": 0.5,
		"batch_start": 1, "batch_end": 3,
		"max_alive": 120,
		"mix": {&"walker": 1.0, &"runner": 0.18},
	},
	{
		"duration": 50.0,
		"interval_start": 0.7, "interval_end": 0.4,
		"batch_start": 2, "batch_end": 4,
		"max_alive": 180,
		"mix": {&"walker": 1.0, &"runner": 0.2, &"tank": 0.03},
	},
	{
		"duration": 60.0,
		"interval_start": 0.6, "interval_end": 0.3,
		"batch_start": 2, "batch_end": 5,
		"max_alive": 260,
		"mix": {&"walker": 1.0, &"runner": 0.22, &"tank": 0.05},
	},
]
