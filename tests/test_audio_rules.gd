extends GutTest
## Ses kuralları: aynı anda çalma sınırı, çalışlar arası bekleme, perde payı, adım sayacı, ses tablosu.

const ID: StringName = &"test"
const EPSILON: float = 0.0001


func test_limiter_blocks_when_voices_full() -> void:
	var limiter: VoiceLimiter = VoiceLimiter.new()
	assert_true(limiter.request(ID, 0.0, 1, 2, 0.0))
	assert_false(limiter.request(ID, 1.0, 2, 2, 0.0), "tüm kopyalar çalarken yeni ses reddedilmeli")


func test_limiter_enforces_min_interval_per_sound() -> void:
	var limiter: VoiceLimiter = VoiceLimiter.new()
	assert_true(limiter.request(ID, 0.0, 0, 4, 0.1))
	assert_false(limiter.request(ID, 0.05, 0, 4, 0.1))
	assert_true(limiter.request(&"other", 0.05, 0, 4, 0.1), "bekleme sese özel olmalı")
	assert_true(limiter.request(ID, 0.1 + EPSILON, 0, 4, 0.1))


func test_limiter_rejected_request_does_not_restart_wait() -> void:
	var limiter: VoiceLimiter = VoiceLimiter.new()
	limiter.request(ID, 0.0, 0, 4, 0.1)
	limiter.request(ID, 0.09, 0, 4, 0.1)
	assert_true(limiter.request(ID, 0.1 + EPSILON, 0, 4, 0.1))


func test_limiter_zero_voices_is_silent() -> void:
	assert_false(VoiceLimiter.new().request(ID, 0.0, 0, 0, 0.0))


func test_pitch_stays_inside_variance() -> void:
	assert_almost_eq(VoiceLimiter.pitch(0.1, 0.0), 0.9, EPSILON)
	assert_almost_eq(VoiceLimiter.pitch(0.1, 0.5), 1.0, EPSILON)
	assert_lt(VoiceLimiter.pitch(0.1, 0.9999), 1.1 + EPSILON)


func test_stride_first_step_comes_at_half_stride() -> void:
	var stride: Stride = Stride.new(1.0)
	assert_eq(stride.advance(0.49), 0)
	assert_eq(stride.advance(0.02), 1)
	assert_eq(stride.advance(0.98), 0)
	assert_eq(stride.advance(0.02), 1)


func test_stride_counts_several_steps_in_one_frame() -> void:
	assert_eq(Stride.new(0.5).advance(1.3), 3)


func test_stride_reset_restores_half_step() -> void:
	var stride: Stride = Stride.new(1.0)
	stride.advance(0.9)
	stride.reset()
	assert_eq(stride.advance(0.4), 0)
	assert_eq(stride.advance(0.2), 1)


func test_horde_silent_below_min_and_full_at_full_count() -> void:
	var lo: int = Tuning.HORDE_GROAN_MIN_COUNT
	var hi: int = Tuning.HORDE_GROAN_FULL_COUNT
	assert_eq(HordeGroan.intensity(lo - 1, lo, hi), 0.0)
	assert_gt(HordeGroan.intensity(lo + 1, lo, hi), 0.0)
	assert_eq(HordeGroan.intensity(hi, lo, hi), 1.0)
	assert_eq(HordeGroan.intensity(hi * 3, lo, hi), 1.0)


func test_horde_denser_means_more_often_and_louder() -> void:
	var sparse: float = HordeGroan.interval(0.1, Tuning.HORDE_GROAN_INTERVAL_SPARSE, Tuning.HORDE_GROAN_INTERVAL_DENSE, 0.0, 0.5)
	var dense: float = HordeGroan.interval(1.0, Tuning.HORDE_GROAN_INTERVAL_SPARSE, Tuning.HORDE_GROAN_INTERVAL_DENSE, 0.0, 0.5)
	assert_lt(dense, sparse)
	assert_almost_eq(dense, Tuning.HORDE_GROAN_INTERVAL_DENSE, EPSILON)
	assert_lt(HordeGroan.volume_offset(0.1, Tuning.HORDE_GROAN_SPARSE_DB), HordeGroan.volume_offset(1.0, Tuning.HORDE_GROAN_SPARSE_DB))
	assert_almost_eq(HordeGroan.volume_offset(1.0, Tuning.HORDE_GROAN_SPARSE_DB), 0.0, EPSILON)


func test_horde_interval_jitter_stays_positive() -> void:
	var shortest: float = HordeGroan.interval(1.0, Tuning.HORDE_GROAN_INTERVAL_SPARSE, Tuning.HORDE_GROAN_INTERVAL_DENSE,
		Tuning.HORDE_GROAN_JITTER, 0.0)
	assert_gt(shortest, 0.0)


func test_every_sound_row_has_existing_files() -> void:
	for id: StringName in SoundData.TABLE:
		var row: Dictionary = SoundData.get_row(id)
		assert_gt((row["files"] as Array).size(), 0, "%s: dosya yok" % id)
		assert_gt(int(row["max_voices"]), 0, "%s: max_voices" % id)
		for file: String in row["files"]:
			assert_true(ResourceLoader.exists(SoundData.path_of(file)), "eksik ses dosyası: %s" % file)


func test_every_weapon_sound_is_in_sound_table() -> void:
	for id: StringName in WeaponData.TABLE:
		var sound: StringName = WeaponData.get_row(id).get("sound", SoundData.SHOT)
		assert_true(SoundData.TABLE.has(sound), "%s silahının sesi tabloda yok: %s" % [id, sound])
