class_name BagSchedule
extends RefCounted
## Bir dalganın çanta takvimi (saf): ilk çanta BAG_FIRST_DELAY'de, sonra BAG_INTERVAL'de bir, dalga başına en çok BAG_MAX_PER_WAVE.
## Süre yalnız tick ile akar (duraklatma/ara fazda çağrılmaz).

var wave: int = 0
var money_count: int = 0
var xp_count: int = 0

var _clock: float = 0.0
var _next: float = Tuning.BAG_FIRST_DELAY


func spawned() -> int:
	return money_count + xp_count


## Yeni dalga (no 1'den): sayaçlar ve saat sıfırlanır.
func start_wave(wave_no: int) -> void:
	wave = wave_no
	money_count = 0
	xp_count = 0
	_clock = 0.0
	_next = Tuning.BAG_FIRST_DELAY


## Süreyi ilerletir; true dönerse çanta doğurmayı DENE (ardından register ya da boş geçilir). active_bag: sahnede çanta var.
func tick(delta: float, active_bag: bool) -> bool:
	_clock += delta
	if spawned() >= Tuning.BAG_MAX_PER_WAVE or active_bag or _clock < _next:
		return false
	_next = _clock + Tuning.BAG_INTERVAL
	return true


## Doğan çantayı sayar.
func register(kind: StringName) -> void:
	if kind == BagRules.KIND_MONEY:
		money_count += 1
	else:
		xp_count += 1
