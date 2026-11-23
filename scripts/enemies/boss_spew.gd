class_name BossSpew
extends RefCounted
## Boss kusmuk yağmuru (BossAttack'in parçası; kurallar SpewRules): atış anında askerin o anki konumunun etrafına yelpaze
## asit topu. Toplar tükürücünün yay atışı + iniş + asit havuzu yolundan gider (LobAttack.launch_ball): aynı görsel, ses,
## havuz ve yavaşlatma/yanma; iniş askerin üstündeyse spew_damage (LobAttack._land).

var _m: EnemyManager
var _lob: LobAttack


func _init(manager: EnemyManager, lob: LobAttack) -> void:
	_m = manager
	_lob = lob


## Atış: dönüş atılan top sayısı (kaçış boşluğu bırakmak için bazı toplar elenebilir). Noktalar burada kırpılır; LobAttack.launch_ball kırpmaz.
func fire(i: int, row: Dictionary, raged: bool) -> int:
	var from: Vector2 = _m._pos[i]
	var target: Vector2 = _m.player.position_2d()
	var points: Array[Vector2] = SpewRules.landing_points(from, target, SpewRules.count(raged, row), float(row["spew_spread"]),
			float(row["spew_dist_lo"]), float(row["spew_dist_hi"]), _m._half, _m._rng)
	# Havuzlar engel kırpmasından sonraki gerçek iniş noktasına düşer: boşluk o noktalarla hesaplanır.
	var obstacles: bool = Tuning.FEATURE_OBSTACLE_STEER and Tuning.FEATURE_CITY_GREYBOX
	var blocks: Array[Rect2] = _m._blocks if obstacles else ([] as Array[Rect2])
	if obstacles:
		points = SpewRules.clip_points(from, points, Tuning.OBSTACLE_SHOT_RADIUS, Tuning.OBSTACLE_SHOT_MARGIN, blocks)
	points = SpewRules.ensure_gap(points, target, float(row["spew_pool_radius"]), Tuning.PLAYER_RADIUS, float(row["spew_escape_len"]), _m._half, blocks)
	var acid: Dictionary = SpewRules.acid_row(row)
	var origin: Vector3 = Vector3(from.x, float(row["spew_release_height"]), from.y)
	for point: Vector2 in points:
		var flight: float = SpewRules.flight(from.distance_to(point), row)
		_lob.launch_ball(acid, origin, from, point, flight, SpewRules.arc(flight, row))
	return points.size()
