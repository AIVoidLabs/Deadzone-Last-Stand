class_name TextHud
extends RefCounted
## HUD, afiş ve son ekran özeti metinleri.

const TABLE: Dictionary = {
	# --- HUD ve afişler ---
	&"hud.wave_fmt": {"tr": "DALGA %d/%d", "en": "WAVE %d/%d"},
	&"hud.final_wave": {"tr": "SON DALGA", "en": "FINAL WAVE"},
	&"hud.wave_n": {"tr": "DALGA %d", "en": "WAVE %d"},
	&"hud.cleared": {"tr": "DALGA TEMİZLENDİ", "en": "WAVE CLEARED"},
	&"hud.cleared_short": {"tr": "TEMİZLENDİ", "en": "CLEARED"},
	&"hud.level_n": {"tr": "SEVİYE %d", "en": "LEVEL %d"},
	&"hud.level_short": {"tr": "SV", "en": "LV"},
	&"hud.boss_incoming": {"tr": "%s GELİYOR", "en": "%s IS COMING"},
	# --- Tur sonu ---
	&"end.win_a": {"tr": "HAYATTA", "en": "YOU"},
	&"end.win_b": {"tr": "KALDIN", "en": "SURVIVED"},
	&"end.lose_a": {"tr": "SON", "en": "LAST"},
	&"end.lose_b": {"tr": "NEFES", "en": "BREATH"},
	&"end.card_cat_win": {"tr": "ZAFER", "en": "VICTORY"},
	&"end.card_cat_lose": {"tr": "YENİLGİ", "en": "DEFEAT"},
	&"end.card_win_line": {"tr": "Şehir seni durduramadı.", "en": "The city could not stop you."},
	&"end.card_lose_line": {"tr": "Sürü seni yuttu.", "en": "The horde swallowed you."},
	&"end.stat.wave": {"tr": "DALGA", "en": "WAVE"},
	&"end.stat.time": {"tr": "SÜRE", "en": "TIME"},
	&"end.stat.kills": {"tr": "ÖLDÜRME", "en": "KILLS"},
	&"end.stat.crystals": {"tr": "KRİSTAL", "en": "CRYSTALS"},
	&"end.stat.level": {"tr": "SEVİYE", "en": "LEVEL"},
	&"end.stat.dealt": {"tr": "VERİLEN HASAR", "en": "DAMAGE DEALT"},
	&"end.stat.taken": {"tr": "ALINAN HASAR", "en": "DAMAGE TAKEN"},
	&"end.stat.dashes": {"tr": "TAKLA", "en": "DASHES"},
	&"end.record": {"tr": "REKOR", "en": "RECORD"},
	&"end.top_kills": {"tr": "EN ÇOK ÖLDÜRÜLEN", "en": "MOST KILLED"},
	&"end.weapons": {"tr": "SİLAHLAR", "en": "WEAPONS"},
	&"end.cards": {"tr": "KARTLAR", "en": "CARDS"},
	&"end.retry": {"tr": "TEKRAR DENE (%s)", "en": "TRY AGAIN (%s)"},
	&"end.menu": {"tr": "ANA MENÜ", "en": "MAIN MENU"},
	&"end.none": {"tr": "—", "en": "—"},
}
