class_name BossTrail
extends RefCounted
## Hücumun yanan yarık izi (saf; sayılar boss satırından): hücum yolunda trail_step aralıkla parça bırakılır, her parça
## trail_life sn yanar (son trail_fade sn söner), asker (trail_radius) parçanın üstündeyken saniyede trail_burn_dps yanar
## (trail_burn_tick'te bir parça hasar; zırh/dokunulmazlık çağıranda). En çok trail_max parça; dolunca en eskisi gider.

var _step: float
var _life: float
var _fade: float
var _radius: float
var _dps: float
var _tick: float
var _max: int
var _pos: PackedVector2Array = PackedVector2Array()
var _age: PackedFloat32Array = PackedFloat32Array()
var _slot: PackedInt32Array = PackedInt32Array()
var _next_slot: int = 0
## Son parçadan beri yürünen yol (ilk parça hücumun başında hemen düşer) ve yanık tik birikimi.
var _carry: float = 0.0
var _acc: float = 0.0
## Boss öldü: iz artık yakmaz (parçalar yaşlanıp gider).
var _harmless: bool = false


func _init(row: Dictionary) -> void:
	_step = float(row["trail_step"])
	_life = float(row["trail_life"])
	_fade = float(row["trail_fade"])
	_radius = float(row["trail_radius"])
	_dps = float(row["trail_burn_dps"])
	_tick = float(row["trail_burn_tick"])
	_max = int(row["trail_max"])
	_carry = _step


func count() -> int:
	return _pos.size()


func life() -> float:
	return _life


func fade_time() -> float:
	return _fade


func radius() -> float:
	return _radius


## Boss öldü: bundan sonra yanık hasarı yok.
func stop_burning() -> void:
	_harmless = true


## Yeni hücum başlıyor: ilk parça başlangıçta düşer.
func begin() -> void:
	_carry = _step


## a→b adımında düşecek parça noktaları (her trail_step yolda bir; kare sınırları arasında artan yol taşınır).
func points_along(a: Vector2, b: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var dist: float = a.distance_to(b)
	var d: float = _step - _carry
	while d <= dist:
		out.append(a.lerp(b, d / dist) if dist > 0.0 else a)
		d += _step
	_carry = _carry + dist if out.is_empty() else dist - (d - _step)
	return out


## Parça ekler; sahne tarafı için yuva numarası (0..trail_max-1) döner. Doluysa en eski parçanın yuvası yeniden kullanılır.
func add(at: Vector2) -> int:
	if _pos.size() >= _max:
		_pos.remove_at(0)
		_age.remove_at(0)
		_slot.remove_at(0)
	var slot: int = _next_slot % _max
	_next_slot += 1
	_pos.append(at)
	_age.append(0.0)
	_slot.append(slot)
	return slot


## Parçanın parlaklığı: yaşam boyu 1, son fade sn'de 0'a söner.
static func intensity(age: float, lifetime: float, fade: float) -> float:
	return clampf((lifetime - age) / maxf(fade, 0.001), 0.0, 1.0)


## Asker parçanın yarıçapı içinde mi (gövde merkezi, parça dairesi).
static func touching(part: Vector2, target: Vector2, hit_radius: float) -> bool:
	return part.distance_to(target) <= hit_radius


## Bir kare: parçalar yaşlanır, ömrü dolan gider. exposed ise ve asker bir parçadaysa tik birikir; dönüş: bu karede vurulacak hasar.
func tick(delta: float, target: Vector2, exposed: bool) -> float:
	var k: int = _pos.size() - 1
	var burning: bool = false
	while k >= 0:
		_age[k] += delta
		if _age[k] >= _life:
			_pos.remove_at(k)
			_age.remove_at(k)
			_slot.remove_at(k)
		elif touching(_pos[k], target, _radius):
			burning = true
		k -= 1
	if not burning or not exposed or _harmless:
		_acc = 0.0
		return 0.0
	var step: Vector2 = LobRules.advance_tick(_acc, delta, _tick)
	_acc = step.x
	return step.y * _dps * _tick
