extends GutTest

const MIN_ITEMS: int = 30
const MIN_PER_DIRECTION: int = 5
const DIRECTIONS: Dictionary = {
	&"ranged": [&"damage", &"fire_rate", &"range"],
	&"speed": [&"move_speed", &"dash_cooldown", &"dash_distance", &"damage"],
	&"tank": [&"armor", &"max_hp", &"hp_regen"],
	&"economy": [&"luck", &"pickup_range"],
}


func test_item_count_reached() -> void:
	assert_gte(ItemData.ids().size(), MIN_ITEMS)


func test_every_item_row_is_valid() -> void:
	for id: StringName in ItemData.ids():
		var row: Dictionary = ItemData.get_row(id)
		assert_gt(int(row["price"]), 0, "fiyat: %s" % id)
		assert_false(String(row["name"]).is_empty(), "ad: %s" % id)
		assert_false((row["effects"] as Array).is_empty(), "etki: %s" % id)
		for effect: Dictionary in row["effects"]:
			assert_true(StatData.TABLE.has(effect["stat"]), "%s: bilinmeyen stat" % id)


func test_every_item_has_both_languages() -> void:
	for id: StringName in ItemData.ids():
		var entry: Dictionary = TextContent.TABLE.get(StringName("item." + id), {})
		assert_false(String(entry.get("tr", "")).is_empty(), "TR: %s" % id)
		assert_false(String(entry.get("en", "")).is_empty(), "EN: %s" % id)


func test_each_direction_has_enough_items() -> void:
	for direction: StringName in DIRECTIONS:
		var count: int = 0
		for id: StringName in ItemData.ids():
			for effect: Dictionary in ItemData.get_row(id)["effects"]:
				if float(effect["value"]) > 0.0 and (DIRECTIONS[direction] as Array).has(effect["stat"]):
					count += 1
					break
		assert_gte(count, MIN_PER_DIRECTION, "yön: %s" % direction)
