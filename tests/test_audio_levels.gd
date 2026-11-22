extends GutTest


func test_level_db_identity_and_mute() -> void:
	assert_eq(AudioBuses.level_db(-4.0, 1.0), -4.0, "düzey 1: tablo dB'si aynen")
	assert_eq(AudioBuses.level_db(0.0, 0.0), AudioBuses.SILENT_DB, "0 sessiz")
	assert_almost_eq(AudioBuses.level_db(0.0, 0.5), linear_to_db(0.5), 0.0001)
	assert_almost_eq(AudioBuses.level_db(-4.0, 0.5), -4.0 + linear_to_db(0.5), 0.0001, "tablo dB'sinin üstüne")
