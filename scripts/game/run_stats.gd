class_name RunStats
extends RefCounted
## Tur içi sayaçlar (saf). Oyun kodu ona yalnız basit çağrılarla yazar; tur sonunda summary() özeti verir.
## Silah başına hasar sinyalde yok; toplam hasarla yetinilir (sürü yolunda ek maliyet yok).

var time: float = 0.0
var kills: int = 0
var kills_by_kind: Dictionary = {}
## Toplanan kristal (harcananlar düşmez).
var crystals: int = 0
## XP çantalarından gelen XP (para çantası crystals'a yazılır).
var bag_xp: int = 0
var damage_taken: float = 0.0
var damage_dealt: float = 0.0
var dashes: int = 0
var shots: int = 0
var level: int = 1
## Ulaşılan dalga (1'den).
var wave: int = 1
## Alınan kartlar: [{stat, tier}]
var cards: Array[Dictionary] = []
## Eşya kimliği -> adet
var items: Dictionary = {}
## Tur sonundaki silahlar: [{id, tier}]
var weapons: Array[Dictionary] = []
var won: bool = false
var finished: bool = false


func tick(delta: float) -> void:
	if not finished:
		time += delta


func on_kill(kind: StringName) -> void:
	kills += 1
	kills_by_kind[kind] = int(kills_by_kind.get(kind, 0)) + 1


func on_damage_dealt(amount: float) -> void:
	damage_dealt += amount


func on_damage_taken(amount: float) -> void:
	damage_taken += amount


func on_crystal(value: int) -> void:
	crystals += value


func on_bag(kind: StringName, value: int) -> void:
	if kind == BagRules.KIND_MONEY:
		crystals += value
	else:
		bag_xp += value


func on_dash() -> void:
	dashes += 1


func on_shot() -> void:
	shots += 1


func set_level(value: int) -> void:
	level = maxi(level, value)


func set_wave(value: int) -> void:
	wave = maxi(wave, value)


func add_card(stat: StringName, tier: int) -> void:
	cards.append({"stat": stat, "tier": tier})


func add_item(id: StringName) -> void:
	items[id] = int(items.get(id, 0)) + 1


## Silah yuvaları ([{id, tier}] ya da yalnız kimlikler; kimlikte kademe 1 sayılır).
func set_weapons(slots: Array) -> void:
	weapons.clear()
	for slot: Variant in slots:
		if slot is Dictionary:
			weapons.append({"id": StringName(slot.get("id", &"")), "tier": int(slot.get("tier", 1))})
		else:
			weapons.append({"id": StringName(slot), "tier": 1})


func finish(did_win: bool) -> void:
	won = did_win
	finished = true


## SaveGame ve özet ekranı için sade sözlük (RunRecord.apply_run bunu okur).
func summary() -> Dictionary:
	return {
		"won": won, "time": time, "kills": kills, "kills_by_kind": kills_by_kind.duplicate(),
		"crystals": crystals, "bag_xp": bag_xp, "damage_taken": damage_taken, "damage_dealt": damage_dealt,
		"dashes": dashes, "shots": shots, "level": level, "wave": wave,
		"cards": cards.duplicate(true), "items": items.duplicate(), "weapons": weapons.duplicate(true),
	}
