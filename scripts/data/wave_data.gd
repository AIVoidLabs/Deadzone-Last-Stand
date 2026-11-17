class_name WaveData
extends RefCounted
## Dalga tablosu. Yeni dalga = yeni satır (Aşama 11'de sayılar hedefe çekilir).
## Dalga içinde doğma aralığı (sn) ve grup boyu başlangıçtan sona doğrusal değişir.
## max_alive: aynı anda en çok canlı zombi; kalite profilinin sınırıyla ayrıca kırpılır.
## mix: tür → ağırlık (EnemyData satırları).

const WAVES: Array = [
	{
		"duration": 20.0,
		"interval_start": 0.9, "interval_end": 0.6,
		"batch_start": 1, "batch_end": 2,
		"max_alive": 60,
		"mix": {&"walker": 1.0},
	},
	{
		"duration": 30.0,
		"interval_start": 0.8, "interval_end": 0.45,
		"batch_start": 1, "batch_end": 3,
		"max_alive": 100,
		"mix": {&"walker": 1.0},
	},
	{
		"duration": 40.0,
		"interval_start": 0.7, "interval_end": 0.35,
		"batch_start": 2, "batch_end": 4,
		"max_alive": 160,
		"mix": {&"walker": 1.0},
	},
	{
		"duration": 50.0,
		"interval_start": 0.6, "interval_end": 0.25,
		"batch_start": 2, "batch_end": 5,
		"max_alive": 240,
		"mix": {&"walker": 1.0},
	},
	{
		"duration": 60.0,
		"interval_start": 0.5, "interval_end": 0.15,
		"batch_start": 3, "batch_end": 6,
		"max_alive": 350,
		"mix": {&"walker": 1.0},
	},
]
