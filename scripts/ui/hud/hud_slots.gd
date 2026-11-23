class_name HudSlots
extends HudGroup
## Sol alt: küçük silah yuvaları (amblem + kademe çizgileri), soluk. Yalnız silahlar değişince yeniden çizilir.

## Silah ipucu (FEATURE_WEAPON_TOOLTIP): fare dolu yuvaya girince / çıkınca.
signal slot_hovered(cell: Control, id: StringName, tier: int)
signal slot_unhovered

const SLOT_SIZE: float = 42.0
const SLOT_GAP: int = 5
const FADE: float = 0.62
const SLOT_COUNT: int = Tuning.WEAPON_SLOTS

var _cells: Array[HudSlotCell] = []
var _last: Array[Dictionary] = []


func _init() -> void:
	configure(Vector2(0.0, 1.0), 14.0, "", Color.WHITE, Vector2i(0, 0))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", SLOT_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.modulate.a = FADE
	add_content(row)
	for i: int in SLOT_COUNT:
		var cell: HudSlotCell = HudSlotCell.new()
		cell.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		row.add_child(cell)
		_cells.append(cell)
		if Tuning.FEATURE_WEAPON_TOOLTIP:
			cell.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.mouse_entered.connect(hover_cell.bind(i))
			cell.mouse_exited.connect(slot_unhovered.emit)


func hover_cell(index: int) -> void:
	if index < _last.size():
		slot_hovered.emit(_cells[index], _last[index]["id"], int(_last[index]["tier"]))


## list: [{id, tier}] (WeaponRig.slot_list). Aynıysa hiçbir şey yapmaz.
func set_slots(list: Array[Dictionary]) -> void:
	if list == _last:
		return
	_last = list.duplicate(true)
	slot_unhovered.emit()
	for i: int in _cells.size():
		if i < list.size():
			_cells[i].set_weapon(list[i]["id"], int(list[i]["tier"]))
		else:
			_cells[i].set_weapon(&"", 0)


class HudSlotCell extends Control:
	var _id: StringName = &""
	var _tier: int = 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_weapon(id: StringName, tier: int) -> void:
		_id = id
		_tier = tier
		queue_redraw()

	func _draw() -> void:
		var rect: Rect2 = Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(UiPalette.INK, 0.62))
		draw_rect(rect, Color(UiPalette.ASH, 0.45 if _id != &"" else 0.2), false, 1.5)
		if _id == &"":
			return
		draw_texture_rect(Emblems.tex(StringName("weapon_" + _id)), rect.grow(-3.0), false)
		for i: int in _tier:
			draw_rect(Rect2(4.0 + i * 7.0, size.y - 5.0, 5.0, 2.5), UiPalette.tier_color(clampi(_tier - 1, 0, 3)))
