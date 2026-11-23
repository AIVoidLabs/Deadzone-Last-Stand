class_name MarketCards
extends RefCounted
## Mağaza rafı satırı (ShopFlow görünümü) -> GrungeCard verisi. Metinler Loc'tan.
## entry: {kind, id, state, price, locked, merged, tier, owned}.

const WEAPON_CATEGORY: StringName = &"weapon"


static func card_data(entry: Dictionary, index: int) -> Dictionary:
	var state: StringName = StringName(entry["state"])
	var data: Dictionary = _weapon_body(entry) if entry["kind"] == ShopRules.WEAPON else _item_body(entry)
	data["hint"] = str(index + 1)
	data["state"] = state
	data["state_text"] = "" if state == &"ok" else Loc.t(StringName("run.shop.state_" + state))
	data["price"] = -1 if state == &"sold" else int(entry["price"])
	data["price_color"] = UiPalette.GOLD if state == &"ok" else UiPalette.BAD
	data["compact"] = true
	return data


static func _item_body(entry: Dictionary) -> Dictionary:
	var id: StringName = entry["id"]
	var effects: Array = ItemData.get_row(id)["effects"]
	var category: StringName = StatData.category_of(effects[0]["stat"])
	var lines: Array = []
	for effect: Dictionary in effects:
		var good: bool = float(effect["value"]) > 0.0
		lines.append({"text": StatData.describe(effect["stat"], effect["value"]), "color": UiPalette.GOOD if good else UiPalette.BAD, "bold": lines.is_empty()})
	var owned: int = int(entry.get("owned", 0))
	if owned > 0:
		lines.append({"text": Loc.t(&"run.shop.owned_count", [owned]), "color": UiPalette.ASH})
	return {
		"category_id": category, "category": Loc.category_name(category), "title": Loc.item_name(id),
		"emblem": StringName("item_" + id), "tier": -1, "lines": lines,
	}


static func _weapon_body(entry: Dictionary) -> Dictionary:
	var id: StringName = entry["id"]
	var tier: int = int(entry.get("tier", 1))
	var stats: Dictionary = weapon_stats(WeaponData.get_row(id), WeaponData.tier_row(tier))
	var decimal: String = String(StatReadout.style()["decimal"])
	var lines: Array = []
	if entry.get("merged", false):
		lines.append({"text": Loc.t(&"run.shop.merge", [tier]), "color": UiPalette.GOLD, "bold": true})
	var damage_key: StringName = &"run.shop.damage" if stats["pellets"] == 1 else &"run.shop.damage_pellets"
	var damage_args: Array = [stats["damage"]] if stats["pellets"] == 1 else [stats["damage"], stats["pellets"]]
	lines.append({"text": Loc.t(damage_key, damage_args), "bold": lines.is_empty()})
	lines.append({"text": Loc.t(&"run.shop.rate", [StatReadout.number(stats["rate"], decimal)])})
	lines.append({"text": Loc.t(&"run.shop.range", [stats["range"]])})
	return {
		"category_id": WEAPON_CATEGORY, "category": Loc.category_name(WEAPON_CATEGORY), "title": Loc.weapon_name(id),
		"emblem": StringName("weapon_" + id), "tier": tier - 1, "tier_name": Loc.tier_name(tier - 1), "lines": lines,
	}


## Silah satırı + kademe satırı -> gösterilen sayılar (saf).
static func weapon_stats(row: Dictionary, tier_row: Dictionary) -> Dictionary:
	return {
		"damage": roundi(float(row["damage"]) * float(tier_row["damage_mult"])),
		"pellets": int(row["pellets"]),
		"rate": float(tier_row["rate_mult"]) / float(row["fire_interval"]),
		"range": roundi(float(row["max_range"])),
	}
