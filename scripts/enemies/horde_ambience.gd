class_name HordeAmbience
extends Node
## Askerin çevresindeki zombi yoğunluğuna göre sürü homurtusu çalar. Yalnız okur.

var player: Player
var enemies: EnemyManager

var _check_left: float = 0.0
var _groan_left: float = 0.0
var _level: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	name = "HordeAmbience"
	_rng.randomize()


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = Tuning.HORDE_GROAN_CHECK_TIME
		var count: int = enemies.count_near(player.position_2d(), Tuning.HORDE_GROAN_RADIUS)
		_level = HordeGroan.intensity(count, Tuning.HORDE_GROAN_MIN_COUNT, Tuning.HORDE_GROAN_FULL_COUNT)
	if _level <= 0.0:
		# Sürü dağılınca ilk homurtu beklemeden değil, kısa bir aradan sonra gelsin.
		_groan_left = maxf(_groan_left, Tuning.HORDE_GROAN_INTERVAL_DENSE)
		return
	_groan_left -= delta
	if _groan_left > 0.0:
		return
	Audio.play(SoundData.HORDE_GROAN, HordeGroan.volume_offset(_level, Tuning.HORDE_GROAN_SPARSE_DB))
	_groan_left = HordeGroan.interval(_level, Tuning.HORDE_GROAN_INTERVAL_SPARSE, Tuning.HORDE_GROAN_INTERVAL_DENSE,
		Tuning.HORDE_GROAN_JITTER, _rng.randf())
