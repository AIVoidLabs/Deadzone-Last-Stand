extends Node3D
## Ana sahne: dünyayı kodla kurar ve parçaları birbirine bağlar.


func _ready() -> void:
	# 1v1 debug arenası: dalga, kart ve mağaza kapalı (DebugArena.active SpawnDirector'u da etkiler).
	var arena_mode: bool = DebugArena.requested()
	DebugArena.active = arena_mode
	add_child(Arena.new())

	var player: Player = Player.new()
	add_child(player)

	var enemies: EnemyManager = EnemyManager.new()
	enemies.player = player
	add_child(enemies)

	var director: SpawnDirector = SpawnDirector.new()
	director.enemies = enemies
	enemies.spawning_enabled = not arena_mode
	add_child(director)

	var loot: RunLoot = RunLoot.new()
	var pickups: Pickups = _add_pickups(player, enemies, director, loot)

	var projectiles: ProjectilePool = ProjectilePool.new()
	projectiles.enemies = enemies
	add_child(projectiles)
	if Tuning.FEATURE_IMPACT_SPARKS:
		var sparks: ImpactSparks = ImpactSparks.new()
		add_child(sparks)
		projectiles.impact.connect(func(at: Vector3, direction: Vector2) -> void:
			sparks.burst(at, direction))
		enemies.enemy_blocked.connect(func(at: Vector3, direction: Vector2, _amount: float) -> void:
			sparks.burst(at + Vector3.UP * Tuning.PROJECTILE_HEIGHT, direction, true))

	if Tuning.FEATURE_EXPLOSION_FX:
		projectiles.explosion.connect(func(at: Vector3, radius: float) -> void:
			ExplosionFx.play(self, at, radius))

	var weapons: WeaponRig = WeaponRig.new()
	weapons.player = player
	weapons.enemies = enemies
	weapons.projectiles = projectiles
	add_child(weapons)
	weapons.add_weapon(WeaponData.PISTOL)

	var camera: FollowCamera = FollowCamera.new()
	camera.target = player
	camera.velocity_source = player.get_real_velocity
	add_child(camera)
	player.event.connect(func(event_name: StringName, _data: Dictionary) -> void:
		if event_name == &"hit":
			camera.add_trauma(Tuning.CAMERA_SHAKE_ON_PLAYER_HIT))

	if Tuning.FEATURE_FIRE_SHAKE:
		weapons.weapon_fired.connect(func(row: Dictionary) -> void:
			camera.add_trauma(row["fire_shake"]))
	_add_hit_feedback(enemies, camera)
	enemies.jump_landed.connect(func(at: Vector3, radius: float) -> void:
		LandingFx.play(self, at, radius)
		camera.add_trauma(Tuning.CAMERA_SHAKE_ON_LAND)
		if not Tuning.FEATURE_SFX_ZOMBIES:
			Audio.play(SoundData.explosion_id()))
	projectiles.explosion.connect(func(_at: Vector3, _radius: float) -> void:
		camera.add_trauma(Tuning.CAMERA_SHAKE_ON_EXPLOSION))
	_add_lob_fx(enemies, camera)
	if Tuning.FEATURE_BOSS:
		var boss_fx: BossFx = BossFx.new()
		boss_fx.setup(enemies, camera, pickups)
		add_child(boss_fx)
	var wave: ScreamWave = ScreamWave.new()
	add_child(wave)
	enemies.scream_emitted.connect(func(at: Vector3, radius: float) -> void:
		wave.play(at, radius)
		camera.add_trauma(Tuning.CAMERA_SHAKE_ON_SCREAM))
	enemies.bloat_exploded.connect(func(at: Vector3, radius: float) -> void:
		ExplosionFx.play(self, at, radius)
		camera.add_trauma(Tuning.CAMERA_SHAKE_ON_BLOAT)
		if not Tuning.FEATURE_SFX_ZOMBIES:
			Audio.play(SoundData.explosion_id()))
	_add_sounds(player, enemies, weapons, projectiles, director)

	if Tuning.FEATURE_HURT_VIGNETTE:
		var vignette: HurtVignette = HurtVignette.new()
		vignette.setup(player)
		add_child(vignette)

	var hud: Hud = Hud.new()
	hud.setup(player, enemies, director, loot)
	add_child(hud)
	if Tuning.FEATURE_BOSS:
		var boss_bar: BossBar = BossBar.new()
		boss_bar.enemies = enemies
		add_child(boss_bar)
		var boss_warning: BossWarning = BossWarning.new()
		boss_warning.director = director
		add_child(boss_warning)

	var level_up: LevelUpFlow = null
	if Tuning.FEATURE_LEVEL_CARDS and not arena_mode:
		level_up = LevelUpFlow.new()
		level_up.loot = loot
		level_up.stats = player.stats
		level_up.director = director
		level_up.pickups = pickups
		add_child(level_up)

	var shop: ShopFlow = null
	if Tuning.FEATURE_SHOP and Tuning.FEATURE_WAVES and not arena_mode:
		shop = ShopFlow.new()
		shop.loot = loot
		shop.stats = player.stats
		shop.director = director
		shop.weapons = weapons
		shop.pickups = pickups
		shop.level_up = level_up
		add_child(shop)

	player.died.connect(GameFlow.game_over)
	Quality.apply_to_viewport(get_viewport())

	if OS.is_debug_build():
		_add_debug_tools(player, enemies, projectiles, camera, weapons, director, pickups, loot)
		if arena_mode:
			var arena_tool: DebugArena = DebugArena.new()
			arena_tool.player = player
			arena_tool.enemies = enemies
			arena_tool.weapons = weapons
			add_child(arena_tool)
		if Autoplay.requested() and shop != null:
			var bot: Autoplay = Autoplay.new()
			bot.player = player
			bot.enemies = enemies
			bot.director = director
			bot.loot = loot
			bot.weapons = weapons
			bot.shop = shop
			add_child(bot)


## Kristaller: öldürmede düşer, toplanınca RunLoot'a eklenir, dalga sonunda hepsi çekilir.
## Kapalıyken null döner.
func _add_pickups(player: Player, enemies: EnemyManager, director: SpawnDirector, loot: RunLoot) -> Pickups:
	if not Tuning.FEATURE_PICKUPS:
		return null
	var pickups: Pickups = Pickups.new()
	pickups.player = player
	add_child(pickups)
	enemies.enemy_killed.connect(func(at: Vector3, row: Dictionary) -> void:
		# Boss kristal yağmurunu BossFx yağdırır.
		if not row.get("boss", false):
			pickups.drop(at, row.get("drop_value", 0)))
	pickups.collected.connect(func(value: int) -> void:
		if loot.add(value) > 0:
			UiSounds.play(UiSoundData.LEVEL_UP)
		if Tuning.FEATURE_SFX:
			Audio.play(SoundData.PICKUP_DARK if Tuning.FEATURE_SFX_PICKUP_DARK else SoundData.PICKUP))
	director.phase_changed.connect(func(phase: WaveRun.Phase, _wave_index: int) -> void:
		if phase == WaveRun.Phase.CLEAR:
			pickups.collect_all()
		elif phase == WaveRun.Phase.WAVE:
			pickups.pull_all = false)
	return pickups


## Vuruş geri bildirimi: kan, lekeler, hasar sayıları, öldürmede duraksama ve sarsıntı.
func _add_hit_feedback(enemies: EnemyManager, camera: FollowCamera) -> void:
	if Tuning.FEATURE_BLOOD:
		var blood: BloodFx = BloodFx.new()
		add_child(blood)
		enemies.enemy_damaged.connect(blood.on_enemy_damaged)
	if Tuning.FEATURE_DAMAGE_NUMBERS:
		var numbers: DamageNumbers = DamageNumbers.new()
		add_child(numbers)
		enemies.enemy_damaged.connect(numbers.on_enemy_damaged)
		enemies.enemy_blocked.connect(numbers.on_enemy_blocked)
	enemies.enemy_damaged.connect(func(_at: Vector3, _dir: Vector2, _amount: float, killed: bool) -> void:
		if not killed:
			return
		GameFlow.hit_stop(Tuning.HIT_STOP_KILL_TIME)
		if Tuning.FEATURE_KILL_SHAKE:
			camera.add_trauma(Tuning.CAMERA_SHAKE_ON_KILL))


## Yay atışı görüntüsü (7.3): uçan asit topu / kaya + gölge işareti, asit havuzları; kaya inişinde toz ve sarsıntı.
func _add_lob_fx(enemies: EnemyManager, camera: FollowCamera) -> void:
	if Tuning.FEATURE_ZOMBIE_SPIT or Tuning.FEATURE_ZOMBIE_THROW:
		var lobs: LobProjectiles = LobProjectiles.new()
		add_child(lobs)
		enemies.lob_launched.connect(lobs.launch)
	if Tuning.FEATURE_ZOMBIE_SPIT:
		var pools: AcidPools = AcidPools.new()
		add_child(pools)
		enemies.acid_pool_started.connect(pools.add_pool)
	enemies.lob_landed.connect(func(kind: StringName, at: Vector3, radius: float) -> void:
		if kind == &"throw":
			LandingFx.play(self, at, radius)
			camera.add_trauma(Tuning.CAMERA_SHAKE_ON_ROCK))


## Ses efektleri: olaylar Audio.play'e bağlanır; hangi sesin açık olduğu SoundData/Tuning'den.
func _add_sounds(player: Player, enemies: EnemyManager, weapons: WeaponRig, projectiles: ProjectilePool, director: SpawnDirector) -> void:
	if Tuning.FEATURE_SFX_AMBIENCE:
		var rig: AmbienceRig = AmbienceRig.new()
		rig.target = player
		add_child(rig)
	if not Tuning.FEATURE_SFX:
		return
	weapons.weapon_fired.connect(func(row: Dictionary) -> void:
		Audio.play(SoundData.weapon_sound(row)))
	projectiles.explosion.connect(func(_at: Vector3, _radius: float) -> void:
		Audio.play(SoundData.explosion_id()))
	enemies.enemy_damaged.connect(func(_at: Vector3, _dir: Vector2, _amount: float, killed: bool) -> void:
		Audio.play(SoundData.ZOMBIE_DEATH if killed else SoundData.HIT))
	enemies.enemy_blocked.connect(func(_at: Vector3, _dir: Vector2, _amount: float) -> void:
		if not Tuning.FEATURE_SFX_ZOMBIES:
			Audio.play(SoundData.HIT))
	if Tuning.FEATURE_SFX_ZOMBIES:
		Audio.listener = func() -> Vector3:
			return player.global_position if is_instance_valid(player) else Vector3.ZERO
		ZombieSounds.wire(enemies, director)
	player.event.connect(func(event_name: StringName, _data: Dictionary) -> void:
		if event_name == &"hit":
			Audio.play(SoundData.PLAYER_HURT)
		elif event_name == &"dash_started":
			Audio.play(SoundData.DASH_ARMORED if Tuning.FEATURE_SFX_DASH_ARMORED else SoundData.DASH))
	var ui_events: UiEvents = UiEvents.new()
	ui_events.player = player
	ui_events.director = director
	add_child(ui_events)
	var steps: Footsteps = Footsteps.new()
	steps.player = player
	add_child(steps)
	if Tuning.FEATURE_SFX_HORDE_GROAN:
		var horde: HordeAmbience = HordeAmbience.new()
		horde.player = player
		horde.enemies = enemies
		add_child(horde)


func _add_debug_tools(player: Player, enemies: EnemyManager, projectiles: ProjectilePool, camera: FollowCamera, weapons: WeaponRig, director: SpawnDirector, pickups: Pickups, loot: RunLoot) -> void:
	var panel: DebugPanel = DebugPanel.new()
	panel.player = player
	panel.enemies = enemies
	panel.projectiles = projectiles
	panel.weapons = weapons
	panel.director = director
	panel.pickups = pickups
	panel.loot = loot
	add_child(panel)
	if Benchmark.requested():
		var bench: Benchmark = Benchmark.new()
		bench.player = player
		bench.enemies = enemies
		add_child(bench)
	elif Capture.requested():
		var capture: Capture = Capture.new()
		capture.player = player
		capture.enemies = enemies
		capture.debug_panel = panel
		capture.camera = camera
		capture.weapons = weapons
		capture.director = director
		capture.loot = loot
		add_child(capture)
