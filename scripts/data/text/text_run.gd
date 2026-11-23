class_name TextRun
extends RefCounted
## Kart (perk) ve mağaza ekranı metinleri.

const TABLE: Dictionary = {
	# Sayı / birim biçimi (StatReadout): ondalık ayracı, yüzde işareti başta mı, saniye eki.
	&"run.fmt.decimal": {"tr": ",", "en": "."},
	&"run.fmt.percent_prefix": {"tr": "1", "en": "0"},
	&"run.fmt.per_second": {"tr": "/sn", "en": "/s"},
	&"run.fmt.seconds": {"tr": " sn", "en": "s"},
	# Kart ekranı
	&"run.perk.title_a": {"tr": "BİR KART", "en": "CHOOSE"},
	&"run.perk.title_b": {"tr": "SEÇ", "en": "A CARD"},
	&"run.perk.left": {"tr": "KALAN SEÇİM  %d", "en": "PICKS LEFT  %d"},
	&"run.perk.none": {"tr": "Henüz artış yok", "en": "No bonuses yet"},
	# Mağaza
	&"run.shop.title": {"tr": "MAĞAZA", "en": "SHOP"},
	&"run.shop.wave": {"tr": "DALGA %d/%d", "en": "WAVE %d/%d"},
	&"run.shop.reroll": {"tr": "YENİLE  -%d  [%s]", "en": "REROLL  -%d  [%s]"},
	&"run.shop.next": {"tr": "SONRAKİ DALGA", "en": "NEXT WAVE"},
	&"run.shop.slots": {"tr": "SİLAHLAR", "en": "WEAPONS"},
	&"run.shop.slots_hint": {"tr": "tıkla: sat", "en": "click to sell"},
	&"run.shop.sell": {"tr": "SAT +%d?", "en": "SELL +%d?"},
	&"run.shop.last_weapon": {"tr": "Son silah satılamaz", "en": "Last weapon can't be sold"},
	&"run.shop.stats": {"tr": "İSTATİSTİKLER", "en": "STATS"},
	&"run.shop.owned": {"tr": "EŞYALAR", "en": "ITEMS"},
	&"run.shop.owned_none": {"tr": "Henüz eşya yok", "en": "No items yet"},
	&"run.shop.lock": {"tr": "KİLİTLE", "en": "LOCK"},
	&"run.shop.locked": {"tr": "KİLİTLİ", "en": "LOCKED"},
	&"run.shop.state_poor": {"tr": "YETMEZ", "en": "TOO POOR"},
	&"run.shop.state_full": {"tr": "YUVALAR DOLU", "en": "SLOTS FULL"},
	&"run.shop.state_sold": {"tr": "SATILDI", "en": "SOLD"},
	&"run.shop.merge": {"tr": "BİRLEŞİR  >  K%d", "en": "MERGES  >  T%d"},
	&"run.shop.owned_count": {"tr": "Sende  x%d", "en": "Owned  x%d"},
	&"run.shop.damage": {"tr": "Hasar %d", "en": "Damage %d"},
	&"run.shop.damage_pellets": {"tr": "Hasar %d x %d", "en": "Damage %d x %d"},
	&"run.shop.rate": {"tr": "%s atış/sn", "en": "%s shots/s"},
	&"run.shop.range": {"tr": "Menzil %d m", "en": "Range %d m"},
	&"run.shop.merge_damage": {"tr": "Hasar %d → %d", "en": "Damage %d → %d"},
	&"run.shop.merge_damage_pellets": {"tr": "Hasar %d → %d  x%d", "en": "Damage %d → %d  x%d"},
	&"run.shop.merge_rate": {"tr": "Atış hızı +%s", "en": "Fire rate +%s"},
	&"run.shop.merge_range": {"tr": "Menzil %d → %d m", "en": "Range %d → %d m"},
	&"run.tip.arc": {"tr": "Yay %d°", "en": "Arc %d°"},
	&"run.tip.burn": {"tr": "Yanma %s/sn, %s sn", "en": "Burn %s/s for %ss"},
	&"run.tip.explode": {"tr": "Patlama %s m", "en": "Blast %s m"},
	&"run.tip.pierce": {"tr": "Deler: +%d zombi", "en": "Pierces +%d"},
}
