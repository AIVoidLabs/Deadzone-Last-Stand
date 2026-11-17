extends GutTest
## Pompalı saçılması: yelpaze açıları ve rastgele sapma sınırı.

const EPSILON: float = 0.0001


func test_spread_fan_is_symmetric_and_spans_full_angle() -> void:
	var spread: float = deg_to_rad(30.0)
	assert_almost_eq(Spread.angle_offset(0, 6, spread), -spread * 0.5, EPSILON)
	assert_almost_eq(Spread.angle_offset(5, 6, spread), spread * 0.5, EPSILON)
	assert_almost_eq(Spread.angle_offset(1, 6, spread), -Spread.angle_offset(4, 6, spread), EPSILON)
	assert_almost_eq(Spread.angle_offset(1, 3, spread), 0.0, EPSILON, "tek sayıda saçmada ortadaki tam nişanda")


func test_single_pellet_goes_straight() -> void:
	assert_eq(Spread.angle_offset(0, 1, 1.0), 0.0)
	assert_eq(Spread.jitter(1, 1.0, 1.0, 0.9), 0.0)


func test_spread_jitter_stays_inside_half_gap() -> void:
	var spread: float = deg_to_rad(30.0)
	var gap: float = spread / 5.0
	for roll: float in [0.0, 0.25, 0.75, 0.9999]:
		assert_lt(absf(Spread.jitter(6, spread, 1.0, roll)), gap * 0.5 + EPSILON)
