class_name BloatAttack
extends RefCounted
## Patlayıcı (attack_kind bloat; SpecialAttacks'ın parçası): temas + bloat_prime_range'de WINDUP (şişme), sonunda patlar.
## Silahla (ya da başka patlamayla) ölürse bloat_death_fuse sonra aynı yerde patlar: bekleyen patlamalar kuyrukta,
## sonraki karelerde işlenir (aynı karede zincirleme özyineleme yok). Kurallar BloatRules'ta.
## Görüntüye EnemyManager.bloat_exploded sinyali ve zombi `swell` olayı ile haber verilir.

const S = ZombieRules.State

var _m: EnemyManager
## Bekleyen ölüm fitilleri: konum, kalan süre, satır, zincir (başka patlama tetikledi) bayrağı.
var _fuse_pos: PackedVector2Array = PackedVector2Array()
var _fuse_left: PackedFloat32Array = PackedFloat32Array()
var _fuse_row: Array[Dictionary] = []
var _fuse_chain: PackedByteArray = PackedByteArray()
## Bir patlamanın hasar döngüsü sürerken true: o sırada ölenlerin fitili zincir sayılır.
var _blasting: bool = false


func _init(manager: EnemyManager) -> void:
	_m = manager


## Bu satır açık bir patlayıcı mı (bayrak kapalıyken yürüyen gibi).
static func active(row: Dictionary) -> bool:
	return Tuning.FEATURE_ZOMBIE_BLOAT and row.get("attack_kind") == &"bloat"


## Hazırlıktaki (şişen) patlayıcı sendelemez.
static func is_primed(row: Dictionary, state: ZombieRules.State) -> bool:
	return state == S.WINDUP and active(row)


func begin_windup(i: int, p: Vector2, target: Vector2) -> void:
	_m.bloat_primed += 1
	_m._aim[i] = Steering.seek(p, target)
	_m._nodes[i].event.emit(&"swell", {})


## Hazırlıkta asker yönüne döner.
func aim_tick(i: int, p: Vector2, target: Vector2) -> void:
	var dir: Vector2 = Steering.seek(p, target)
	if dir != Vector2.ZERO:
		_m._aim[i] = dir


## Hazırlık bitti: kendini (ceset ve ganimet yok) yok edip patlar. Dönüş: DYING.
func end_windup(i: int, row: Dictionary) -> ZombieRules.State:
	var at: Vector2 = _m._pos[i]
	_m._combat.kill(i, Vector2.ZERO, false, false)
	_blast(at, _m.scaled_row(i, row), false)
	return S.DYING


## Silahla ölen patlayıcının fitili (EnemyCombat.kill çağırır).
func queue_death_fuse(i: int, row: Dictionary) -> void:
	_fuse_pos.append(_m._pos[i])
	_fuse_left.append(float(row["bloat_death_fuse"]))
	_fuse_row.append(_m.scaled_row(i, row))
	_fuse_chain.append(1 if _blasting else 0)


## Her fizik karesi: fitiller yanar; süresi dolan patlar (yeni fitiller sonraki karelerde işlenir).
func tick(delta: float) -> void:
	if _fuse_left.is_empty():
		return
	var due: Array[int] = []
	for k in _fuse_left.size():
		_fuse_left[k] -= delta
		if _fuse_left[k] <= 0.0:
			due.append(k)
	var fired: Array[Array] = []
	for k in due:
		fired.append([_fuse_pos[k], _fuse_row[k], _fuse_chain[k] == 1])
	for k in range(due.size() - 1, -1, -1):
		_fuse_pos.remove_at(due[k])
		_fuse_left.remove_at(due[k])
		_fuse_row.remove_at(due[k])
		_fuse_chain.remove_at(due[k])
	for shot: Array in fired:
		_blast(shot[0], shot[1], shot[2])


## Patlama: askere mesafeye göre hasar, alandaki zombilere hasar + itme (zırh çarpanı damage içinde), görüntü sinyali.
func _blast(at: Vector2, row: Dictionary, chain: bool) -> void:
	var radius: float = row["bloat_radius"]
	_m.bloat_exploded_count += 1
	if chain:
		_m.bloat_chains += 1
	_m.bloat_exploded.emit(Vector3(at.x, 0.1, at.y), radius)
	var target: Vector2 = _m.player.position_2d()
	var hurt: float = BloatRules.player_damage(at.distance_to(target), radius, float(row["bloat_player_damage"]), float(row["bloat_edge_factor"]), Tuning.PLAYER_RADIUS)
	if hurt > 0.0 and _m.player.is_exposed():
		_m.bloat_player_hits += 1
		_m.player.take_hit(hurt, BloatRules.push_direction(at, target, Vector2.DOWN))
	_blasting = true
	for j in _m.query_circle(at, radius):
		var damage: float = BloatRules.zombie_damage(at.distance_to(_m._pos[j]), radius, float(row["bloat_zombie_damage"]), _m._radius[j])
		if damage > 0.0:
			_m.damage(j, damage, BloatRules.push_direction(at, _m._pos[j], Vector2.from_angle(_m._rng.randf() * TAU)), Tuning.BLOAT_ZOMBIE_KNOCKBACK)
	_blasting = false
