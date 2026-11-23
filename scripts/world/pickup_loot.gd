class_name PickupLoot
extends Node
## Kristal bağlantısı: öldürmede düşer (drop_chance zarı), toplanınca RunLoot'a eklenir,
## dalga/tur geçişlerinde yerdekiler yönetilir. Kapalıyken (FEATURE_PICKUPS) hiç kurulmaz.

var pickups: Pickups
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Pickups düğümünü host'a ekler ve bağlar; kapalıyken null döner.
static func install(host: Node, player: Player, enemies: EnemyManager, director: SpawnDirector, loot: RunLoot) -> Pickups:
	if not Tuning.FEATURE_PICKUPS:
		return null
	var link: PickupLoot = PickupLoot.new()
	link.name = "PickupLoot"
	host.add_child(link)
	return link._setup(player, enemies, director, loot)


func _setup(player: Player, enemies: EnemyManager, director: SpawnDirector, loot: RunLoot) -> Pickups:
	_rng.randomize()
	pickups = Pickups.new()
	pickups.player = player
	add_child(pickups)
	enemies.enemy_killed.connect(_on_enemy_killed)
	pickups.collected.connect(func(value: int) -> void:
		if loot.add(value) > 0:
			UiSounds.play(UiSoundData.LEVEL_UP)
		if Tuning.FEATURE_SFX:
			Audio.play(SoundData.PICKUP_DARK if Tuning.FEATURE_SFX_PICKUP_DARK else SoundData.PICKUP))
	director.phase_changed.connect(_on_phase_changed)
	return pickups


func _on_enemy_killed(at: Vector3, row: Dictionary) -> void:
	# Boss her zaman kristal yağmuru bırakır (BossFx yağdırır); zar yalnız sıradan zombiler için.
	if not row.get("boss", false) and _rolls_drop(row):
		pickups.drop(at, row.get("drop_value", 0))


## Dalga sonu: eski akışta hepsi çekilir; yeni akışta kristaller yerde bekler, son dalgada (WON) tur sonu
## özeti doğru olsun diye hepsi anında toplanır, yeni dalgada kalanlar silinir.
func _on_phase_changed(phase: WaveRun.Phase, _wave_index: int) -> void:
	if not Tuning.FEATURE_WAVE_END_NO_AUTOCOLLECT:
		if phase == WaveRun.Phase.CLEAR:
			pickups.collect_all()
		elif phase == WaveRun.Phase.WAVE:
			pickups.pull_all = false
		return
	if phase == WaveRun.Phase.WON:
		pickups.take_all()
	elif phase == WaveRun.Phase.WAVE:
		pickups.pull_all = false
		pickups.clear_all()


## Zombi satırının drop_chance'ine göre kristal düşer mi (FEATURE_DROP_CHANCE kapalıysa hep).
func _rolls_drop(row: Dictionary) -> bool:
	if not Tuning.FEATURE_DROP_CHANCE:
		return true
	return PickupRules.should_drop(float(row.get("drop_chance", Tuning.DROP_CHANCE_DEFAULT)), _rng)
