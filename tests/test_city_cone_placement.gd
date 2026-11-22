extends GutTest
## 8.3j: koni yerlesimi (CityConePlacement).

var _blocked: Array[Vector2] = [Vector2(6.0, 0.0)]
var _gap: float = Tuning.DRESS_CONE_CORPSE_GAP
var _half: float = Tuning.CITY_STREET_WIDTH * 0.5 - 1.0


func test_clear_cone_stays() -> void:
	var corpses: Array[Vector3] = [Vector3(-5.0, 0.0, 3.0)]
	var p: Vector3 = Vector3(2.0, 0.0, 0.0)
	assert_eq(CityConePlacement.pick_spot(p, corpses, _blocked, _gap, 2.8, _half), p)


func test_cone_on_corpse_is_moved_clear() -> void:
	var corpses: Array[Vector3] = [Vector3(1.0, 0.0, 1.0)]
	var p: Vector3 = Vector3(1.3, 0.0, 1.0)
	var q: Vector3 = CityConePlacement.pick_spot(p, corpses, _blocked, _gap, 2.8, _half)
	assert_ne(q, p)
	assert_true(CityConePlacement.is_clear(q, corpses, _blocked, _gap, 2.8))
	assert_true(CityConePlacement.on_street(q, _half))


func test_moved_cone_avoids_prop() -> void:
	var corpses: Array[Vector3] = [Vector3(4.0, 0.0, 0.0)]
	var q: Vector3 = CityConePlacement.pick_spot(Vector3(4.2, 0.0, 0.0), corpses, _blocked, _gap, 2.8, _half)
	assert_gte(Vector2(q.x, q.z).distance_to(_blocked[0]), 2.8)


func test_deterministic() -> void:
	var corpses: Array[Vector3] = [Vector3(0.0, 0.0, 0.0)]
	var a: Vector3 = CityConePlacement.pick_spot(Vector3(0.5, 0.0, 0.2), corpses, _blocked, _gap, 2.8, _half)
	var b: Vector3 = CityConePlacement.pick_spot(Vector3(0.5, 0.0, 0.2), corpses, _blocked, _gap, 2.8, _half)
	assert_eq(a, b)
