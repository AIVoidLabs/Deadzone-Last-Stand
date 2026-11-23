class_name MarketSlotBar
extends VBoxContainer
## Mağaza alt şeridi: silah yuvaları + başlık. Yuvaya tıkla: sat için ARM_TIME sn "silahlı" olur, ikinci tıkla satar.
## Son silah satılamaz (sarsılır). Esc silahlı yuvayı bırakır (MarketScreen sorar).

signal sell_pressed(index: int)

const SLOT_SIZE: float = 62.0
const SLOT_GAP: int = 6
const LABEL_SIZE: int = 15
const LABEL_GAP: int = 4
const ARM_TIME: float = 2.5

var _label: Label = null
var _slots: Array[MarketSlot] = []
var _weapons: Array = []
var _signature: Array = []
var _armed: int = -1
var _arm_tween: Tween = null


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", LABEL_GAP)
	_label = Label.new()
	_label.add_theme_font_override("font", UiFonts.heading())
	_label.add_theme_font_size_override("font_size", LABEL_SIZE)
	_label.add_theme_color_override("font_color", UiPalette.ASH)
	add_child(_label)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", SLOT_GAP)
	add_child(row)
	for i: int in Tuning.WEAPON_SLOTS:
		var slot: MarketSlot = MarketSlot.new()
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.pressed.connect(_on_slot_pressed.bind(i))
		UiSounds.hook(slot)
		row.add_child(slot)
		_slots.append(slot)


func set_texts() -> void:
	_label.text = "%s  /  %s" % [Loc.t(&"run.shop.slots"), Loc.t(&"run.shop.slots_hint")]


func is_armed() -> bool:
	return _armed >= 0


## weapons: [{id, tier, sell, sellable}]. Silahlar değişince silahlı yuva bırakılır.
func sync(weapons: Array) -> void:
	_weapons = weapons
	var sig: Array = []
	for weapon: Dictionary in weapons:
		sig.append([weapon["id"], weapon["tier"]])
	if sig != _signature:
		disarm()
		_signature = sig
	for i: int in _slots.size():
		if i < weapons.size():
			_slots[i].setup(weapons[i], int(weapons[i]["sell"]))
		else:
			_slots[i].setup({}, 0)


func disarm() -> void:
	if _arm_tween != null:
		_arm_tween.kill()
		_arm_tween = null
	if _armed >= 0 and _armed < _slots.size():
		_slots[_armed].armed = false
	_armed = -1


func _on_slot_pressed(index: int) -> void:
	if index >= _weapons.size():
		return
	if not _weapons[index]["sellable"]:
		MarketFx.wobble(_slots[index])
		UiSounds.play(UiSoundData.DENY)
		return
	if _armed == index:
		disarm()
		sell_pressed.emit(index)
		return
	disarm()
	_armed = index
	_slots[index].armed = true
	if Tuning.FEATURE_UI_MOTION:
		_arm_tween = create_tween()
		_arm_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_arm_tween.tween_interval(ARM_TIME)
		_arm_tween.tween_callback(disarm)
