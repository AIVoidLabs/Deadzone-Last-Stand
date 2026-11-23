class_name SpecialAttackTable
extends RefCounted
## Saldırı türüne göre mesafe ve durum tabloları (SpecialAttacks'ın yardımcısı; sahneden bağımsız).


## Kovalarken saldırıyı başlatan mesafe payı (temasın üstüne).
static func start_range(row: Dictionary) -> float:
	if not SpecialAttacks.is_special(row):
		return row["attack_range"]
	match row["attack_kind"]:
		&"lunge":
			return row["lunge_range"]
		&"sprint":
			return row["sprint_trigger_range"]
		&"jump":
			return row["jump_range"]
		&"spit":
			return row["spit_range"]
		&"throw":
			return row["throw_range"]
		&"bloat":
			return row["bloat_prime_range"]
		&"scream":
			return row["scream_range"]
	return row["tongue_range"]


## Hazırlıktan sonra geçilecek durum (özel saldırı kapalıysa RECOVER: yürüyenin vuruşu).
static func windup_next(row: Dictionary) -> ZombieRules.State:
	if not SpecialAttacks.is_special(row):
		return ZombieRules.State.RECOVER
	match row["attack_kind"]:
		&"lunge":
			return ZombieRules.State.LUNGE
		&"sprint":
			return ZombieRules.State.SPRINT
		&"jump":
			return ZombieRules.State.JUMP
		&"spit", &"throw", &"bloat", &"scream":
			return ZombieRules.State.RECOVER
	return ZombieRules.State.LASH
