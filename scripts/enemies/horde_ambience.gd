class_name HordeAmbience
extends Node
## Askerin çevresindeki zombi yoğunluğuna göre sürü homurtusu çalar; büyük sürüde ek olarak tek zombinin inlemesi. Yalnız okur.

var player: Player
var enemies: EnemyManager

var _check_left: float = 0.0
var _groan_left: float = 0.0
var _moan_left: float = 0.0
var _level: float = 0.0
var _count: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	name = "HordeAmbience"
	_rng.randomize()


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = Tuning.HORDE_GROAN_CHECK_TIME
		_count = enemies.count_near(player.position_2d(), Tuning.HORDE_GROAN_RADIUS)
		_level = HordeGroan.intensity(_count, Tuning.HORDE_GROAN_MIN_COUNT, Tuning.HORDE_GROAN_FULL_COUNT)
	_update_groan(delta)
	_update_moan(delta)


func _update_groan(delta: float) -> void:
	if _level <= 0.0:
		# Sürü dağılınca ilk homurtu beklemeden değil, kısa bir aradan sonra gelsin.
		_groan_left = maxf(_groan_left, Tuning.HORDE_GROAN_INTERVAL_DENSE)
		return
	_groan_left -= delta
	if _groan_left > 0.0:
		return
	Audio.play(SoundData.ZOMBIE_GROAN if Tuning.FEATURE_SFX_ZOMBIES else SoundData.HORDE_GROAN, HordeGroan.volume_offset(_level, Tuning.HORDE_GROAN_SPARSE_DB))
	_groan_left = HordeGroan.interval(_level, Tuning.HORDE_GROAN_INTERVAL_SPARSE, Tuning.HORDE_GROAN_INTERVAL_DENSE,
		Tuning.HORDE_GROAN_JITTER, _rng.randf())


## Kalabalık inlemesi: kendi zamanlayıcısı; sürüden rastgele bir zombinin konumunda çalar.
func _update_moan(delta: float) -> void:
	if not (Tuning.FEATURE_SFX_ZOMBIES and Tuning.FEATURE_SFX_HORDE_MOANS):
		return
	if not HordeMoan.active(_count, Tuning.HORDE_MOAN_MIN_COUNT):
		_moan_left = maxf(_moan_left, Tuning.HORDE_MOAN_INTERVAL_DENSE)
		return
	_moan_left -= delta
	if _moan_left > 0.0:
		return
	_moan_left = HordeMoan.interval(_count, Tuning.HORDE_MOAN_MIN_COUNT, Tuning.HORDE_GROAN_FULL_COUNT,
		Tuning.HORDE_MOAN_INTERVAL_SPARSE, Tuning.HORDE_MOAN_INTERVAL_DENSE, Tuning.HORDE_MOAN_JITTER, _rng.randf())
	var pos: Vector2 = enemies.pick_near(player.position_2d(), Tuning.HORDE_GROAN_RADIUS, _rng.randf())
	if pos == Vector2.INF:
		return
	Audio.play_at(SoundData.Z_MOAN, Vector3(pos.x, 0.0, pos.y))