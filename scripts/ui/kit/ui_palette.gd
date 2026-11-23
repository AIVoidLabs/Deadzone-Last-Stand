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
	&"combat": {"hot": Color("C52018"), "deep": Color("4A0608"), "band": Color("A5251C")},
	&"survival": {"hot": Color("E0701A"), "deep": Color("661A06"), "band": Color("A8501A")},
	&"motion": {"hot": Color("4A7FB5"), "deep": Color("0F2848"), "band": Color("2B5A94")},
	&"loot": {"hot": Color("B8832A"), "deep": Color("3A2308"), "band": Color("7D6420")},
	&"weapon": {"hot": Color("8A3430"), "deep": Color("241210"), "band": Color("6E2A2A")},
	&"menu": {"hot": Color("FF4A1C"), "deep": Color("4A1206"), "band": Color("B8340F")},
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
