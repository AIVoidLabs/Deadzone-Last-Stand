class_name WaveRun
extends RefCounted
## Dalga akışı: dalga → temizlik (kalanlar devrilir) → ara → sonraki dalga.
## Son dalganın temizliğinden sonra kazanılır. Sahneden bağımsız; satırlar parametreyle gelir.

enum Phase { WAVE, CLEAR, BREAK, WON }

const NO_CHANGE: int = -1

var index: int = 0
var phase: Phase = Phase.WAVE
## Fazın bitmesine kalan süre (sn).
var phase_left: float = 0.0

var _waves: Array
var _clear_time: float
var _break_time: float


func _init(waves: Array, clear_time: float, break_time: float) -> void:
	assert(not waves.is_empty(), "Dalga tablosu boş")
	_waves = waves
	_clear_time = clear_time
	_break_time = break_time
	start_at(0)


func wave_count() -> int:
	return _waves.size()


func current() -> Dictionary:
	return _waves[index]


func is_last() -> bool:
	return index == _waves.size() - 1


## Dalga içinde geçen sürenin oranı (0..1); dalga dışında 1.
func progress() -> float:
	if phase != Phase.WAVE:
		return 1.0
	var duration: float = current()["duration"]
	return clampf(1.0 - phase_left / duration, 0.0, 1.0)


## Süreyi ilerletir. Faz değiştiyse yeni fazı (Phase), değişmediyse NO_CHANGE döner.
func tick(delta: float) -> int:
	if phase == Phase.WON:
		return NO_CHANGE
	phase_left -= delta
	if phase_left > 0.0:
		return NO_CHANGE
	match phase:
		Phase.WAVE:
			_enter(Phase.CLEAR, _clear_time)
		Phase.CLEAR:
			if is_last():
				_enter(Phase.WON, 0.0)
			else:
				_enter(Phase.BREAK, _break_time)
		Phase.BREAK:
			start_at(index + 1)
	return phase


## Dalgayı hemen bitirir (temizliğe geçer). Dalga dışında bir şey yapmaz.
func end_wave() -> void:
	if phase == Phase.WAVE:
		_enter(Phase.CLEAR, _clear_time)


## i. dalgayı baştan başlatır.
func start_at(i: int) -> void:
	index = clampi(i, 0, _waves.size() - 1)
	_enter(Phase.WAVE, current()["duration"])


func _enter(next: Phase, duration: float) -> void:
	phase = next
	phase_left = duration
