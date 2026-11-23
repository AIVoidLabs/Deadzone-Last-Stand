class_name WaveScaling
extends RefCounted
## Dalgaya göre zombi gücü (saf): dalga satırındaki enemy_hp_mult / enemy_damage_mult (yoksa 1.0).
## Doğma anında temel tür satırından hesaplanır; havuzdaki zombiye birikmez. Boss ölçeklenmez.

## Ölçeklenen oyuncuya-hasar alanları (tür satırında varsa).
const DAMAGE_KEYS: Array[StringName] = [&"contact_damage", &"acid_damage", &"bloat_player_damage"]


static func hp_mult(wave_row: Dictionary, base_row: Dictionary, enabled: bool) -> float:
	if not enabled or base_row.get("boss", false):
		return 1.0
	return float(wave_row.get("enemy_hp_mult", 1.0))


static func damage_mult(wave_row: Dictionary, base_row: Dictionary, enabled: bool) -> float:
	if not enabled or base_row.get("boss", false):
		return 1.0
	return float(wave_row.get("enemy_damage_mult", 1.0))


## Temel satırdan ölçeklenmiş hasar alanlı kopya (çarpan 1 ise satırın kendisi; satır asla değiştirilmez).
static func scaled_row(base_row: Dictionary, mult: float) -> Dictionary:
	if is_equal_approx(mult, 1.0):
		return base_row
	var row: Dictionary = base_row.duplicate()
	for key in DAMAGE_KEYS:
		if row.has(key):
			row[key] = float(row[key]) * mult
	return row
