class_name StaticCaches
extends RefCounted
## Kaynak tutan static önbellekleri toplu boşaltır. Yalnız oyun kapanırken çağrılır (GameFlow);
## "ObjectDB instances leaked at exit" uyarısını önler. Önbellekler lazy: sonradan yeniden dolar.


static func clear_all() -> void:
	SoundData.clear_cache()
	ZombieClips.clear_cache()
	ZombieHeldProp.clear_cache()
	ZombieLook.clear_cache()
	ZombieMaterials.clear_cache()
	CityFxAssets.clear_cache()
	Loc.clear_cache()
	Emblems.clear_cache()
	UiAssets.clear_cache()
	UiFonts.clear_cache()
	UiTheme.clear_cache()
