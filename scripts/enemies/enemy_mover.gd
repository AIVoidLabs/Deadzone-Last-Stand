class_name EnemyMover
extends RefCounted
## Zombi hareket döngüsü (EnemyManager'dan ayrıldı): kovalama, özel saldırı adımı, engelden kaçınma, itme, askerle temas.
## Durum yöneticide kalır; bu sınıf onun dizilerini okur ve yazar.

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


func run(delta: float) -> void:
	var target: Vector2 = _m.player.position_2d()
	var hittable: bool = _m.player.is_hittable()
	var solid: bool = not (Tuning.FEATURE_DASH_PASS_THROUGH and _m.player.is_dashing())
	var sync_walk: bool = Tuning.FEATURE_WALK_SPEED_SYNC
	var target_vel: Vector2 = Vector2(_m.player.velocity.x, _m.player.velocity.z)
	var obstacles: bool = Tuning.FEATURE_OBSTACLE_STEER and Tuning.FEATURE_CITY_GREYBOX
	var anti_tunnel_sq: float = Tuning.OBSTACLE_ANTI_TUNNEL_STEP * Tuning.OBSTACLE_ANTI_TUNNEL_STEP
	for i in _m._pos.size():
		if _m._alive[i] == 0 or _m.debug_freeze:
			continue
		var state: ZombieRules.State = _m._state[i] as ZombieRules.State
		if ZombieRules.is_timed(state):
			_m._timer[i] -= delta
			if _m._timer[i] <= 0.0:
				state = _m._combat.on_timer(i, state, target)
		var p: Vector2 = _m._pos[i]
		var prev: Vector2 = p
		var dir: Vector2 = Steering.seek(p, target)
		var speed: float = _m._speed[i]
		var special: bool = SpecialAttacks.is_special(_m._rows[i])
		var steer: bool = false
		var move_dir: Vector2 = dir
		if special and SpecialAttacks.acts_in(state):
			var act_dir: Vector2 = dir
			if obstacles and (state == ZombieRules.State.SPRINT or state == ZombieRules.State.LUNGE):
				act_dir = _avoid(i, p, dir)
			p = _m._special.act(i, state, p, act_dir, delta, target, target_vel)
		elif ZombieRules.can_move(state) or (state == ZombieRules.State.RECOVER and ChaseSteer.walks_recovering(_m._rows[i])):
			steer = ChaseSteer.active(_m._rows[i])
			move_dir = _m._steer.heading(i, _m._rows[i], p, target, dir, delta) if steer else dir
			if obstacles:
				move_dir = _avoid(i, p, move_dir)
			var vel: Vector2 = move_dir * speed
			if Tuning.FEATURE_SEPARATION:
				vel += Steering.separation(i, _m._pos, _m._grid, _m._radius[i] * 2.0) * Tuning.ENEMY_SEPARATION_STRENGTH
			p += vel.limit_length(speed * Tuning.ENEMY_MAX_SPEED_FACTOR) * delta
		if obstacles and p.distance_squared_to(prev) > anti_tunnel_sq:
			p = CityLayout.anti_tunnel(prev, p, _m._radius[i], _m._blocks)
		if _m._knock[i] != Vector2.ZERO:
			p += _m._knock[i] * delta
			_m._knock[i] = Knockback.decay_to_rest(_m._knock[i], Tuning.KNOCKBACK_DAMPING, delta, EnemyManager.KNOCK_REST_SQ)
		# Askerle temas: içine girmez.
		var reach: float = Tuning.PLAYER_RADIUS + _m._radius[i]
		var away: Vector2 = p - target
		var dist: float = away.length()
		if state == ZombieRules.State.LUNGE:
			state = _m._special.lunge_contact(i, state, p, dist, reach, target)
			hittable = _m.player.is_hittable()
		# Havadaki zıplayan üstünden, pençeden sonra koşucu içinden geçer; itişme yok.
		if solid and dist < reach and _m._special.is_solid(i, state):
			if hittable and not Tuning.FEATURE_ZOMBIE_WINDUP_ATTACK:
				_m.player.take_hit(_m._damage[i], -away)
				hittable = _m.player.is_hittable()
			p = target + (away / dist if dist > 0.0001 else -dir) * reach
			dist = reach
		var lim: float = _m._half - _m._radius[i]
		p = p.clamp(Vector2(-lim, -lim), Vector2(lim, lim))
		if Tuning.FEATURE_CITY_GREYBOX:
			p = CityLayout.push_out(p, _m._radius[i], _m._blocks)
		_m._pos[i] = p
		var node: Zombie = _m._nodes[i]
		node.position = Vector3(p.x, 0.0, p.y)
		if special and SpecialAttacks.faces_in(state):
			_m._special.face_node(i, p, node)
		if sync_walk and (state == ZombieRules.State.CHASE or steer or (state == ZombieRules.State.SPRINT and _m._rows[i].has("sprint_ref_speed"))):
			node.ground_speed.emit(p.distance_to(prev) / delta)
		# Yalnız kovalarken (ya da mesafe koruyan çığlıkçı beklerken) döner; hazırlanırken yönü kilitlidir.
		var face_dir: Vector2 = _m._steer.facing(i) if steer else move_dir
		if face_dir != Vector2.ZERO and (steer or state == ZombieRules.State.CHASE):
			node.rotation.y = atan2(face_dir.x, face_dir.y)
		if state != ZombieRules.State.CHASE:
			continue
		if Tuning.FEATURE_ZOMBIE_WINDUP_ATTACK:
			_m._combat.begin_attack(i, p, target, target_vel, dist, reach, special, delta)


## Engele doğru giden yönü kenara kaydırır (FEATURE_OBSTACLE_STEER; çağıran bayrağı denetler).
func _avoid(i: int, p: Vector2, dir: Vector2) -> Vector2:
	return CityLayout.steer(p, dir, _m._radius[i], Tuning.OBSTACLE_STEER_LOOK, Tuning.OBSTACLE_STEER_BLEND, _m._blocks)
