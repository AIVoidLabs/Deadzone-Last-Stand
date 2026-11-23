class_name BattleHud
extends CanvasLayer
## Savaş HUD'ı (FEATURE_NEW_HUD): sol üst can/takla/XP, üst orta dalga + süre, sağ üst kristal ve öldürme,
## sol altta silah yuvaları, ortada afişler. Hasar sayısı yok; oyunu kapatmaz. Eski Hud ile aynı setup() imzası.
## Her kare yalnız değer okur; metin ve düğüm yalnız değişince güncellenir. Tur sonu özetini EndScreen gösterir.

const LAYER_INDEX: int = 1
## Sol alttaki silah yuvaları (soluk, isteğe bağlı).
const SHOW_WEAPON_SLOTS: bool = true
const SLOTS_POLL: float = 0.3
const BANNER_HOLD_WAVE: float = 1.3
const BANNER_HOLD_CLEARED: float = 1.5
const BANNER_HOLD_LEVEL: float = 1.0
const BANNER_LAST_COLOR: Color = Color("D01A22")
const BANNER_WAVE_COLOR: Color = Color("FF6A1C")
const BANNER_CLEARED_COLOR: Color = Color("7FA83A")
const BANNER_LEVEL_COLOR: Color = Color("D9A62E")
## Görüntü aracında gösterilecek sahte değerler.
const DEMO: Dictionary = {
	"hp": 83.0, "hp_max": 110.0, "dash": 1.0, "xp": 0.62, "level": 3, "wave": 2, "waves": 5, "time": 17.0,
	"crystals": 148, "kills": 236, "weapons": [{"id": &"pistol", "tier": 1}, {"id": &"shotgun", "tier": 2}, {"id": &"smg", "tier": 3}],
}

var _player: Player = null
var _enemies: EnemyManager = null
var _director: SpawnDirector = null
var _loot: RunLoot = null
var _weapons: WeaponRig = null
var _root: Control = null
var _vitals: HudVitals = null
var _clock: HudClock = null
var _tally: HudTally = null
var _slots: HudSlots = null
var _tooltip: WeaponTooltip = null
var _banner: WaveBanner = null
var _shown_level: int = 1
## Etiket metinleri yalnız değer değişince kurulur (her karede dize üretilmesin).
var _drawn_level: int = -1
var _clock_key: int = -1
var _slots_wait: float = 0.0
var _demo: Dictionary = {}
var _demo_slots: Array[Dictionary] = []


func setup(player: Player, enemies: EnemyManager, director: SpawnDirector, loot: RunLoot, weapons: WeaponRig = null) -> void:
	_player = player
	_enemies = enemies
	_director = director
	_loot = loot
	_weapons = weapons


func _ready() -> void:
	name = "BattleHud"
	layer = LAYER_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.theme = UiTheme.get_theme()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiAssets.fill(_root)
	add_child(_root)
	_vitals = HudVitals.new()
	_clock = HudClock.new()
	_tally = HudTally.new()
	_slots = HudSlots.new()
	for group: HudGroup in [_vitals, _clock, _tally, _slots]:
		_root.add_child(group)
	_slots.visible = SHOW_WEAPON_SLOTS
	if Tuning.FEATURE_WEAPON_TOOLTIP:
		_tooltip = WeaponTooltip.new()
		_root.add_child(_tooltip)
		_slots.slot_hovered.connect(_on_slot_hovered)
		_slots.slot_unhovered.connect(_tooltip.hide_tip)
	_banner = WaveBanner.new()
	_root.add_child(_banner)
	Settings.changed.connect(_on_setting_changed)
	_apply_scale()
	if _director != null:
		_director.phase_changed.connect(_on_wave_phase)
	else:
		set_demo({})


func _on_slot_hovered(cell: Control, id: StringName, tier: int) -> void:
	_tooltip.show_for(cell, id, tier)


## Görüntü aracı: i. silah yuvasının ipucunu açar.
func hover_slot(index: int) -> void:
	_slots.hover_cell(index)


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/hud_scale":
		_apply_scale()
	elif key == &"game/language":
		_vitals.set_level(_shown_level)
		_clock_key = -1


func _apply_scale() -> void:
	var factor: float = float(Settings.get_value(&"game/hud_scale"))
	for group: HudGroup in [_vitals, _clock, _tally, _slots]:
		group.apply_scale(factor)


func _process(delta: float) -> void:
	if _director == null:
		_feed_demo()
		return
	var health: Health = _player.health
	_vitals.set_health(health.current, health.maximum)
	_vitals.set_dash(_player.dash.readiness())
	_vitals.set_xp(_loot.level_progress())
	if _loot.level != _drawn_level:
		_drawn_level = _loot.level
		_vitals.set_level(_loot.level)
	if _loot.level > _shown_level:
		_shown_level = _loot.level
		_banner.flash(Loc.t(&"hud.level_n", [_loot.level]), BANNER_LEVEL_COLOR, BANNER_HOLD_LEVEL)
	_tally.set_crystals(_loot.crystals)
	_tally.set_kills(_enemies.kills)
	_feed_clock(_director.run)
	_slots_wait -= delta
	if _slots_wait <= 0.0 and _weapons != null and _slots.visible:
		_slots_wait = SLOTS_POLL
		_slots.set_slots(_weapons.slot_list())


func _feed_clock(run: WaveRun) -> void:
	if run == null:
		_set_clock(0, 0, false, HudRules.clock_seconds(_enemies.elapsed), 0, false)
		return
	var in_wave: bool = run.phase == WaveRun.Phase.WAVE
	_set_clock(run.index + 1, run.wave_count(), run.is_last(), HudRules.clock_seconds(run.phase_left), HudRules.final_second(run.phase_left) if in_wave else 0, not in_wave)


## Saat yalnız anahtar (dalga, saniye, durum) değişince güncellenir.
func _set_clock(number: int, total: int, last: bool, seconds: int, final_n: int, cleared: bool) -> void:
	var key: int = HudRules.clock_key(number, total, last, seconds, final_n, cleared)
	if key == _clock_key:
		return
	_clock_key = key
	_clock.set_wave(number, total, last)
	_clock.set_time(seconds, final_n, cleared)


func _on_wave_phase(phase: WaveRun.Phase, wave_index: int) -> void:
	var run: WaveRun = _director.run
	if phase == WaveRun.Phase.WAVE:
		if run.is_last():
			_banner.flash(Loc.t(&"hud.final_wave"), BANNER_LAST_COLOR, BANNER_HOLD_WAVE)
		else:
			_banner.flash(Loc.t(&"hud.wave_n", [wave_index + 1]), BANNER_WAVE_COLOR, BANNER_HOLD_WAVE)
	elif phase == WaveRun.Phase.CLEAR and not run.is_last():
		_banner.flash(Loc.t(&"hud.cleared"), BANNER_CLEARED_COLOR, BANNER_HOLD_CLEARED)


# --- Görüntü aracı ---

func _feed_demo() -> void:
	_vitals.set_health(_demo["hp"], _demo["hp_max"])
	_vitals.set_dash(_demo["dash"])
	_vitals.set_xp(_demo["xp"])
	_vitals.set_level(_demo["level"])
	_tally.set_crystals(_demo["crystals"])
	_tally.set_kills(_demo["kills"])
	_clock.set_wave(_demo["wave"], _demo["waves"], _demo["wave"] == _demo["waves"])
	var seconds: float = _demo["time"]
	_clock.set_time(int(seconds), HudRules.final_second(seconds), false)
	_slots.set_slots(_demo_slots)


## Sahte değerlerle özelleştirir (UiShot).
func set_demo(values: Dictionary) -> void:
	_demo = DEMO.duplicate(true)
	_demo.merge(values, true)
	_demo_slots.clear()
	for slot: Dictionary in _demo["weapons"]:
		_demo_slots.append(slot)


## Görüntü aracı için: tab 0 normal, 1 düşük can + son saniyeler, 2 son dalga + afiş.
static func ui_shot(host: Node, opts: Dictionary) -> void:
	ShotUnderlay.add(host)
	var hud: BattleHud = BattleHud.new()
	host.add_child(hud)
	var tab: int = int(opts.get("tab", 0))
	var values: Dictionary = {}
	if tab == 1:
		values = {"hp": 24.0, "hp_max": 110.0, "dash": 0.4, "time": 3.4, "xp": 0.1, "level": 12, "crystals": 12048, "kills": 3921}
	elif tab == 2:
		values = {"wave": 5, "time": 41.0, "dash": 0.7}
	hud.set_demo(values)
	var hover: int = int(opts.get("hover", -1))
	if hover >= 0:
		host.get_tree().create_timer(Tuning.UI_SHOT_SETTLE_TIME, true, false, true).timeout.connect(hud.hover_slot.bind(hover))
	if tab == 2:
		hud._banner.flash(Loc.t(&"hud.final_wave"), BANNER_LAST_COLOR, 5.0)
	else:
		hud._banner.flash(Loc.t(&"hud.wave_n", [2]), BANNER_WAVE_COLOR, 5.0)
