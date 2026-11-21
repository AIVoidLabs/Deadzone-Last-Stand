class_name WaveRun
extends RefCounted
## Dalga akışı: dalga → temizlik (kalanlar devrilir) → ara → sonraki dalga.
## Son dalganın temizliğinden sonra kazanılır. Sahneden bağımsız; satırlar parametreyle gelir.
## Boss dalgası (satırda "boss": {kind, spawn_time}; boss_enabled açıkken): spawn_time'da uyarı (boss_event &"warn"),
## uyarı süresi sonunda boss doğar (&"spawn"); boss canlıyken dalga süresi durur, dalga boss ölünce (boss_defeated) biter.

enum Phase { WAVE, CLEAR, BREAK, WON }
## NONE: bu dalgada boss yok; WAITING: doğmayı bekliyor; WARNING: uyarı sürüyor; ALIVE: doğdu (ölene dek dalga süresi durur).
enum BossStage { NONE, WAITING, WARNING, ALIVE }

const NO_CHANGE: int = -1
## Boss beklerken dalga süresi bu değerin altına inmez (dalga süresinden önce bitmesin).
const MIN_PHASE_LEFT: float = 0.001

var index: int = 0
var phase: Phase = Phase.WAVE
## Fazın bitmesine kalan süre (sn).
var phase_left: float = 0.0
var boss_stage: BossStage = BossStage.NONE
## Yönetmenin okuyup temizlediği olay: &"warn" (uyarı başladı) ya da &"spawn" (boss şimdi doğmalı); boş = yok.
var boss_event: StringName = &""

var _waves: Array
var _clear_time: float
var _break_time: float
var _boss_enabled: bool
var _warning_time: float
## Boss dalgasında dalga başından beri geçen süre (sn).
var _boss_clock: float = 0.0


func _init(waves: Array, clear_time: float, break_time: float, boss_enabled: bool = false, warning_time: float = 0.0) -> void:
	assert(not waves.is_empty(), "Dalga tablosu boş")
	_waves = waves
	_clear_time = clear_time
	_break_time = break_time
	_boss_enabled = boss_enabled
	_warning_time = warning_time
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
	if phase == Phase.WAVE and boss_stage != BossStage.NONE:
		_tick_boss(delta)
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


## Boss canlıyken sürü doğma hızının çarpanı (1 = değişmez); boss yokken 1.
func horde_factor() -> float:
	if boss_stage != BossStage.ALIVE:
		return 1.0
	return float(current().get("boss", {}).get("horde_factor", Tuning.BOSS_HORDE_FACTOR))


## Boss öldü: dalga hemen biter (temizliğe geçer, clear_time sn). Dönüş: bitti mi (boss beklenmiyorsa false).
func boss_defeated(clear_time: float) -> bool:
	if phase != Phase.WAVE or boss_stage != BossStage.ALIVE:
		return false
	boss_stage = BossStage.NONE
	_enter(Phase.CLEAR, clear_time)
	return true


## Debug: boss elle doğurulduysa (bu dalgada tanımlı olmasa da) dalga süresi durur, boss ölünce biter.
func force_boss() -> void:
	if _boss_enabled and phase == Phase.WAVE:
		boss_stage = BossStage.ALIVE
		boss_event = &""


## Dalgayı hemen bitirir (temizliğe geçer). Dalga dışında bir şey yapmaz.
func end_wave() -> void:
	if phase == Phase.WAVE:
		_enter(Phase.CLEAR, _clear_time)


## i. dalgayı baştan başlatır.
func start_at(i: int) -> void:
	index = clampi(i, 0, _waves.size() - 1)
	_boss_clock = 0.0
	boss_event = &""
	boss_stage = BossStage.WAITING if _boss_enabled and current().has("boss") else BossStage.NONE
	_enter(Phase.WAVE, current()["duration"])


## Boss dalgasında süre: doğmadan önce dalga saati akar (ama dalga bitmez), boss canlıyken durur.
func _tick_boss(delta: float) -> void:
	if boss_stage == BossStage.ALIVE:
		return
	phase_left = maxf(phase_left - delta, MIN_PHASE_LEFT)
	_boss_clock += delta
	var spawn_time: float = float(current()["boss"]["spawn_time"])
	if boss_stage == BossStage.WAITING and _boss_clock >= spawn_time:
		boss_stage = BossStage.WARNING
		boss_event = &"warn"
	if boss_stage == BossStage.WARNING and _boss_clock >= spawn_time + _warning_time:
		boss_stage = BossStage.ALIVE
		boss_event = &"spawn"


func _enter(next: Phase, duration: float) -> void:
	phase = next
	phase_left = duration
