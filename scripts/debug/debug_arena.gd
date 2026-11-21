class_name DebugArena
extends Node
## 1v1 debug arenası: dalga, kart ve mağaza yok; asker + tek zombi (seçilen tür). Yalnız debug yapıda.
## Başlatma: `godot --path . -- --arena[=tür]` ya da scenes/debug/arena.tscn (F6).
## Tuşlar: 1-9 ve 0 tür seç (sırası KINDS) (anında yeniden doğur), R yeniden doğur, G silahlar aç/kapa, H (ya da F5) ölümsüz,
## T zombiyi dondur/çöz, K zombiyi öldür; F7 silah ekle. B: boss Yığın (1-0 listesine sığmaz; --arena=boss_heap de olur). Köşedeki etiket durumu gösterir.

const KINDS: Array[StringName] = [EnemyData.WALKER, EnemyData.RUNNER, EnemyData.TANK, EnemyData.JUMPER, EnemyData.TONGUE,
	EnemyData.ARMORED, EnemyData.SCREAMER, EnemyData.SPITTER, EnemyData.THROWER, EnemyData.BLOATER,
	EnemyData.BOSS_HEAP]
const LAYER: int = 11
const FONT_SIZE: int = 16

## Ana sahne kurulurken true yapılır; SpawnDirector ve main.gd dalga akışını bu bayrağa göre atlar.
static var active: bool = false

var player: Player
var enemies: EnemyManager
var weapons: WeaponRig

var _kind: StringName = EnemyData.WALKER
var _respawn: ArenaRespawn = ArenaRespawn.new(Tuning.DEBUG_ARENA_RESPAWN_DELAY)
var _frozen: bool = false
var _label: Label
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Komut satırında --arena ya da --arena=<tür> var mı (ya da sahne bayrağı kuruldu mu).
static func requested() -> bool:
	if not OS.is_debug_build() or not Tuning.FEATURE_DEBUG_ARENA:
		return false
	if active:
		return true
	for arg in OS.get_cmdline_user_args():
		if arg == "--arena" or arg.begins_with("--arena="):
			return true
	return false


static func kind_from_args() -> StringName:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--arena="):
			var id: StringName = StringName(arg.trim_prefix("--arena="))
			if KINDS.has(id):
				return id
	return EnemyData.WALKER


func _ready() -> void:
	name = "DebugArena"
	_rng.randomize()
	_kind = kind_from_args()
	_respawn.fire_next()
	# --no-weapons Capture'a bağlı kalmasın (--capture olmadan da geçerli); G ile aynı durum.
	if OS.get_cmdline_user_args().has("--no-weapons"):
		_set_weapons(false)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = LAYER
	add_child(layer)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.offset_left = 16.0
	_label.offset_bottom = -16.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_label)


func _physics_process(delta: float) -> void:
	if _respawn.tick(enemies.active_count() > 0, delta):
		_spawn()


func _process(_delta: float) -> void:
	_label.text = _build_text()


func _unhandled_input(input_event: InputEvent) -> void:
	var key: InputEventKey = input_event as InputEventKey
	if key == null or not key.pressed or key.echo or key.ctrl_pressed:
		return
	var number: int = 9 if key.physical_keycode == KEY_0 else key.physical_keycode - KEY_1
	if number >= 0 and number < mini(KINDS.size(), 10):
		_kind = KINDS[number]
		_clear()
		_spawn()
		return
	match key.physical_keycode:
		KEY_B:
			_kind = EnemyData.BOSS_HEAP
			_clear()
			_spawn()
		KEY_R:
			_clear()
			_spawn()
		KEY_G:
			_set_weapons(weapons.process_mode == Node.PROCESS_MODE_DISABLED)
		KEY_H:
			player.god_mode = not player.god_mode
		KEY_T:
			_frozen = not _frozen
			enemies.debug_freeze = _frozen
		KEY_K:
			var index: int = enemies.debug_alive_index()
			if index >= 0:
				enemies.debug_kill(index)


func _set_weapons(on: bool) -> void:
	weapons.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


## Sahnedeki zombiyi kaldırır (ölüm animasyonuyla, öldürme sayılmadan).
func _clear() -> void:
	enemies.dismiss(enemies.active_count())


func _spawn() -> void:
	_respawn.reset()
	var half: float = Tuning.ARENA_SIZE * 0.5 - Tuning.SPAWN_EDGE_INSET
	var from: Vector2 = player.position_2d()
	# Ekranın üst yarısında (kamera yönünde) doğsun ki görünsün.
	var angle: float = _rng.randf_range(-PI * 0.75, -PI * 0.25)
	var at: Vector2 = (from + Vector2.from_angle(angle) * Tuning.DEBUG_ARENA_SPAWN_DIST).clamp(Vector2(-half, -half), Vector2(half, half))
	enemies.spawn(_kind, at)


func _build_text() -> String:
	var index: int = enemies.debug_alive_index()
	var state: String = "yok"
	if index >= 0:
		state = String(ZombieRules.State.keys()[enemies.debug_state(index)])
	return "\n".join([
		"TÜR %s   durum %s%s" % [_kind, state, "  [DONDU]" if _frozen else ""],
		"silah %s   ölümsüz %s" % ["kapalı" if weapons.process_mode == Node.PROCESS_MODE_DISABLED else "AÇIK", "AÇIK" if player.god_mode else "kapalı"],
		"1-0 tür · B boss · R doğur · G silah · H ölümsüz · T dondur · K öldür · F7 +silah",
	])
