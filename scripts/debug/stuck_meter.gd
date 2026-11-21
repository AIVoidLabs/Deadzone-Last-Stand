class_name StuckMeter
extends Node
## Takılma ölçümü (8.2; debug): kovalayan zombilerin hızını örnekler. Askerden SKIP_NEAR m'den uzakta, nominal hızın
## SLOW_RATIO'sundan yavaş giden süre STUCK_TIME sn'yi geçerse zombi "takıldı" sayılır. Engele (SKIP kenar payı) yakınken
## takılanlar ayrıca sayılır (kalabalık sıkışmasından ayırmak için). Capture: `--capture-stuck`; sonda report().
## Karşılaştırma: Tuning.FEATURE_OBSTACLE_STEER açık / kapalı iki koşu (bkz. docs/PROGRESS.md 8.2 ölçümü).

const SKIP_NEAR: float = 3.0
const SLOW_RATIO: float = 0.2
const PROGRESS_RATIO: float = 0.2
const STUCK_TIME: float = 2.0
const EDGE_MARGIN: float = 1.0

var _enemies: EnemyManager
var _player: Player
var _rects: Array[Rect2] = CityLayout.solid_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH, Tuning.FEATURE_CITY_PROPS)
## Zombi düğümü (instance id) -> {last, slow, dist, flat}: slow = yavaş giden süre, flat = askere yaklaşmayan süre.
var _track: Dictionary = {}
var _stuck_ids: Dictionary = {}
var _stuck_edge_ids: Dictionary = {}
## Askere yaklaşma hızı nominal hızın PROGRESS_RATIO'sundan düşük kalan (kenarda yan kayan dahil) zombiler.
var _flat_ids: Dictionary = {}
var _flat_edge_ids: Dictionary = {}
var _seen_ids: Dictionary = {}
## Takılan zombilerin son konumu (rapor için).
var _stuck_at: Dictionary = {}
var _peak_now: int = 0
var _samples: int = 0


func _init(enemies: EnemyManager, player: Player) -> void:
	_enemies = enemies
	_player = player
	name = "StuckMeter"


func _physics_process(delta: float) -> void:
	var now: int = 0
	var target: Vector2 = _player.position_2d()
	for i in _enemies.slot_count():
		if not _enemies.debug_chasing(i):
			continue
		var id: int = _enemies.debug_node(i).get_instance_id()
		var p: Vector2 = _enemies.enemy_position(i)
		var entry: Dictionary = _track.get(id, {"last": p, "slow": 0.0, "dist": p.distance_to(target), "flat": 0.0})
		var moved: float = p.distance_to(entry["last"]) / delta
		entry["last"] = p
		_seen_ids[id] = true
		var dist: float = p.distance_to(target)
		var approach: float = (float(entry["dist"]) - dist) / delta
		entry["dist"] = dist
		var speed: float = _enemies.debug_speed(i)
		var near_player: bool = dist < SKIP_NEAR
		entry["slow"] = 0.0 if near_player or moved >= speed * SLOW_RATIO else float(entry["slow"]) + delta
		entry["flat"] = 0.0 if near_player or approach >= speed * PROGRESS_RATIO else float(entry["flat"]) + delta
		if float(entry["flat"]) >= STUCK_TIME:
			_flat_ids[id] = true
			if _near_obstacle(p, _enemies.enemy_radius(i)):
				_flat_edge_ids[id] = true
		_track[id] = entry
		if float(entry["slow"]) >= STUCK_TIME:
			now += 1
			_stuck_ids[id] = true
			_stuck_at[id] = p
			if _near_obstacle(p, _enemies.enemy_radius(i)):
				_stuck_edge_ids[id] = true
	_peak_now = maxi(_peak_now, now)
	_samples += 1


func _near_obstacle(p: Vector2, r: float) -> bool:
	for rect: Rect2 in _rects:
		if rect.grow(r + EDGE_MARGIN).has_point(p):
			return true
	return false


func report() -> String:
	return "STUCK steer=%s chased=%d slow=%d slow_at_obstacle=%d no_progress=%d no_progress_at_obstacle=%d peak_slow=%d" % [
		Tuning.FEATURE_OBSTACLE_STEER, _seen_ids.size(), _stuck_ids.size(), _stuck_edge_ids.size(), _flat_ids.size(), _flat_edge_ids.size(), _peak_now] + " at=" + str(_stuck_at.values().map(func(v: Vector2) -> String: return "(%.1f,%.1f)" % [v.x, v.y]))
