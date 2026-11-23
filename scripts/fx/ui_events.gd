class_name UiEvents
extends Node
## Akış olaylarının arayüz sesleri: dalga başı/sonu, ölüm, son ekranlar, düşük can kalp atışı.
## Düğüm sahneyle birlikte gider, GameFlow bağlantıları kendiliğinden kopar.

var player: Player
var director: SpawnDirector

var _low_health: LowHealthRule = LowHealthRule.new()


func _ready() -> void:
	name = "UiEvents"
	if not Tuning.FEATURE_SFX_UI:
		return
	director.phase_changed.connect(_on_phase)
	player.died.connect(func() -> void: UiSounds.play(UiSoundData.PLAYER_DEATH))
	# Yöntem olarak bağlanır: self'e dayanmayan lambda düğüm silinince kopmaz (her turda bir bağlantı birikirdi).
	GameFlow.game_over_started.connect(_on_game_over)
	GameFlow.victory_started.connect(_on_victory)
	set_process(Tuning.FEATURE_SFX_LOW_HEALTH)


func _process(delta: float) -> void:
	# Oyun bitince/duraklayınca (GameFlow durumu) kalp atışı susar.
	var ratio: float = player.health.ratio() if GameFlow.state == GameFlow.State.PLAYING else 0.0
	if _low_health.tick(delta, ratio, Tuning.LOW_HEALTH_THRESHOLD, Tuning.LOW_HEALTH_BEAT_INTERVAL):
		UiSounds.play(UiSoundData.LOW_HEALTH)


func _on_game_over() -> void:
	UiSounds.play(UiSoundData.GAME_OVER)


func _on_victory() -> void:
	UiSounds.play(UiSoundData.VICTORY)


func _on_phase(phase: WaveRun.Phase, _wave_index: int) -> void:
	if phase == WaveRun.Phase.WAVE:
		UiSounds.play(UiSoundData.WAVE_START)
	elif phase == WaveRun.Phase.CLEAR:
		UiSounds.play(UiSoundData.WAVE_END)