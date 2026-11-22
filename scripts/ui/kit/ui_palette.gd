class_name UiPalette
extends RefCounted
## Deadzone arayüz paleti ("kanlı afiş": gece, sodyum-amber, kan, siyah).

const INK: Color = Color("0B0908")
const CHAR: Color = Color("171210")
const BONE: Color = Color("E9DFCB")
const ASH: Color = Color("A79B8B")
const EMBER: Color = Color("FF4A1C")
const BLOOD: Color = Color("B3121A")
const AMBER: Color = Color("F08A24")
const STEEL: Color = Color("3B78B5")
const GOLD: Color = Color("D9A62E")
const GOOD: Color = Color("9CCB5A")
const BAD: Color = Color("FF5A48")

## Kart kategorileri: hot = parlak ateş, deep = koyu ateş, band = başlık şeridi tonu.
const CATEGORIES: Dictionary = {
	&"combat": {"hot": Color("E0241B"), "deep": Color("4A0608"), "band": Color("7C120E")},
	&"survival": {"hot": Color("FF8A1E"), "deep": Color("7A1E06"), "band": Color("7A3208")},
	&"motion": {"hot": Color("5FA8E6"), "deep": Color("12325C"), "band": Color("1E4D84")},
	&"loot": {"hot": Color("E0B43A"), "deep": Color("4A3A08"), "band": Color("5A4610")},
	&"weapon": {"hot": Color("A8402F"), "deep": Color("2C1613"), "band": Color("4A1F1A")},
	&"menu": {"hot": Color("FF4A1C"), "deep": Color("4A1206"), "band": Color("8A2A0C")},
}
const DEFAULT_CATEGORY: StringName = &"weapon"

## Nadirlik tonları (CardData.TIERS sırası: sıradan, nadir, destansı, efsanevi).
const TIER_COLORS: Array[Color] = [Color("A79B8B"), Color("5C93CF"), Color("9B6BBA"), Color("E5A02E")]


static func category(id: StringName) -> Dictionary:
	return CATEGORIES.get(id, CATEGORIES[DEFAULT_CATEGORY])


static func tier_color(tier: int) -> Color:
	if tier < 0:
		return ASH
	return TIER_COLORS[mini(tier, TIER_COLORS.size() - 1)]
