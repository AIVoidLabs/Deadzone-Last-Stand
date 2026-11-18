class_name Weapon
extends Node3D
## Otomatik silah: kendi konumuna en yakın zombiye döner ve ateş eder. Değerler WeaponData tablosundan.
## Konumunu WeaponRig verir (askerin çevresinde süzülür); görüntü WeaponVisual'da, sinyalle haber alır.

signal fired(direction: Vector2)

var weapon_id: StringName
var row: Dictionary
## Birleştirme kademesi (1..WeaponData.max_tier()).
var tier: int = 1
var enemies: EnemyManager
var projectiles: ProjectilePool
## XZ düzleminde nişan yönü; hedef yokken askerin baktığı yön.
var aim: Vector2 = Vector2(0.0, 1.0)
var has_target: bool = false

var _player: Player
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
	var target: int = enemies.nearest_enemy(origin, max_range)
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
	for i: int in pellets:
		var angle: float = Spread.angle_offset(i, pellets, spread) + Spread.jitter(pellets, spread, row["spread_jitter"], _rng.randf())
		projectiles.fire(muzzle, direction.rotated(angle), row["projectile_speed"], damage, max_range, row["knockback"])
	_cooldown = _player.stats.fire_interval(float(row["fire_interval"]) / float(_tier_row["rate_mult"]))
	fired.emit(direction)
