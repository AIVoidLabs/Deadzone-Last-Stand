class_name Weapon
extends Node3D
## Otomatik silah: kendi konumuna en yakın zombiye döner ve ateş eder. Değerler WeaponData tablosundan.
## Konumunu WeaponRig verir (askerin çevresinde süzülür); görüntü WeaponVisual'da, sinyalle haber alır.

signal fired(direction: Vector2)

var weapon_id: StringName
var row: Dictionary
## Birleştirme kademesi (1..WeaponData.max_tier()).
var tier: int = 1
## Bu silah az önce bir birleşmeden çıktıysa true (görüntü animasyonu oynatır).
var just_merged: bool = false
var enemies: EnemyManager
var projectiles: ProjectilePool
## XZ düzleminde nişan yönü; hedef yokken askerin baktığı yön.
var aim: Vector2 = Vector2(0.0, 1.0)
var has_target: bool = false
## Son savurmanın gerçek menzili (m, istatistik dahil); kesik izi görüntüsü okur.
var last_reach: float = 0.0

## Yakın dövüşte hedef seçerken menzile eklenen pay (m): zombinin gövdesi de vurulur.
const MELEE_TARGET_SLACK: float = 0.4

var _player: Player
## Görüş hattını kesen yüksek köşe binaları (FEATURE_BUILDING_LOS kapalıysa boş).
var _sight_blocks: Array[Rect2] = []
var _tier_row: Dictionary
var _cooldown: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(id: StringName, p_tier: int, player: Player, p_enemies: EnemyManager, p_projectiles: ProjectilePool) -> void:
	weapon_id = id
	tier = p_tier
	row = WeaponData.get_row(id)
	_tier_row = WeaponData.tier_row(tier)
	_player = player
	enemies = p_enemies
	projectiles = p_projectiles
	_rng.randomize()
	if Tuning.FEATURE_BUILDING_LOS:
		_sight_blocks = CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH)
	name = "Weapon_%s" % id
	if Tuning.FEATURE_FLOATING_WEAPONS:
		var visual: WeaponVisual = WeaponVisual.new()
		visual.name = "Visual"
		add_child(visual)


func position_2d() -> Vector2:
	return Vector2(global_position.x, global_position.z)


## WeaponRig konumu güncelledikten sonra çağırır.
func tick(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _player.state == Player.State.DEAD:
		has_target = false
		return
	var origin: Vector2 = position_2d()
	var max_range: float = _player.stats.weapon_range(row["max_range"])
	if row["behavior"] != &"projectile":
		_tick_area(origin, max_range)
		return
	var target: int = _pick_target(origin, max_range)
	has_target = target >= 0
	if not has_target:
		aim = _player.facing
		return
	var direction: Vector2 = Steering.seek(origin, enemies.enemy_position(target))
	if direction == Vector2.ZERO:
		return
	aim = direction
	if _cooldown > 0.0:
		return
	var muzzle: Vector2 = origin + direction * float(row["muzzle_offset"])
	var pellets: int = row["pellets"]
	var damage: float = _player.stats.weapon_damage(float(row["damage"]) * float(_tier_row["damage_mult"]))
	var spread: float = deg_to_rad(row["spread_deg"])
	var aim_jitter: float = deg_to_rad(row["aim_jitter_deg"])
	var opts: Dictionary = {"pierce": row["pierce"], "explode_radius": row["explode_radius"], "color": row["projectile_color"], "size": row["projectile_size"], "arc": row["projectile_arc"], "length": row["projectile_length"]}
	for i: int in pellets:
		var angle: float = Spread.angle_offset(i, pellets, spread) + Spread.jitter(pellets, spread, row["spread_jitter"], _rng.randf()) + aim_jitter * (_rng.randf() - 0.5)
		projectiles.fire(muzzle, direction.rotated(angle), row["projectile_speed"], damage, max_range, row["knockback"], opts)
	_cooldown = _player.stats.fire_interval(float(row["fire_interval"]) / float(_tier_row["rate_mult"]))
	fired.emit(direction)


func _pick_target(origin: Vector2, reach: float) -> int:
	if _sight_blocks.is_empty():
		return enemies.nearest_enemy(origin, reach)
	return enemies.nearest_visible_enemy(origin, reach, _sight_blocks)


## Alan silahı (yakın dövüş savurması ya da itme patlaması): menzildeki en yakın zombiye döner;
## bekleme bitince yayı (ya da tek hedefi) vurur.
func _tick_area(origin: Vector2, reach: float) -> void:
	var target: int = _pick_target(origin, reach + MELEE_TARGET_SLACK)
	has_target = target >= 0
	if not has_target:
		aim = _player.facing
		return
	var direction: Vector2 = Steering.seek(origin, enemies.enemy_position(target))
	if direction == Vector2.ZERO:
		return
	aim = direction
	if _cooldown > 0.0:
		return
	var damage: float = _player.stats.weapon_damage(float(row["damage"]) * float(_tier_row["damage_mult"]))
	var arc: float = deg_to_rad(row["melee_arc_deg"])
	var hits: PackedInt32Array = PackedInt32Array([target]) if arc <= 0.0 else enemies.query_arc(origin, direction, reach, arc)
	for i: int in hits:
		var away: Vector2 = Steering.seek(origin, enemies.enemy_position(i))
		enemies.damage(i, damage, away if away != Vector2.ZERO else direction, row["knockback"])
		enemies.ignite(i, row["burn_dps"], row["burn_time"])
	last_reach = reach
	_cooldown = _player.stats.fire_interval(float(row["fire_interval"]) / float(_tier_row["rate_mult"]))
	fired.emit(direction)
