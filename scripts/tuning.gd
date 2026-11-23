class_name Tuning
extends RefCounted
## Tüm genel oynanış sayıları burada. İçerik satırları (zombi, silah) scripts/data/ tablolarında.

# --- Özellik anahtarları (her özellik tek sabitle kapanır) ---
# Aşama 9 (arayüz ve akış). Kapalıyken eski yol: doğrudan oyun, eski kart/mağaza/HUD.
const FEATURE_MAIN_MENU: bool = true
const FEATURE_PAUSE_MENU: bool = true
const FEATURE_SETTINGS: bool = true
## Kapalıyken yalnız Türkçe.
const FEATURE_LANGUAGE: bool = true
const FEATURE_SAVE: bool = true
const FEATURE_NEW_CARDS: bool = true
const FEATURE_NEW_SHOP: bool = true
const FEATURE_NEW_HUD: bool = true
## Mağaza kartında birleşme önizlemesi ("Hasar 10 → 15"); kapalıyken kart yeni kademenin tam sayılarını gösterir.
const FEATURE_SHOP_MERGE_PREVIEW: bool = true
## Silah yuvasına (mağaza + savaş HUD'ı) gelince istatistik ipucu paneli; kapalıyken yalnız ad ipucu.
const FEATURE_WEAPON_TOOLTIP: bool = true
const FEATURE_END_SUMMARY: bool = true
const FEATURE_KEY_REBIND: bool = true
const FEATURE_UI_MOTION: bool = true
const FEATURE_SCENE_FADE: bool = true
const FEATURE_SEPARATION: bool = true
const FEATURE_CAMERA_SMOOTHING: bool = true
const FEATURE_CAMERA_LOOK_AHEAD: bool = true
const FEATURE_CAMERA_SHAKE: bool = true
const FEATURE_CAMERA_DYNAMIC_ANGLE: bool = true
const FEATURE_HIT_FLASH: bool = true
const FEATURE_PLAYER_IFRAMES: bool = true
const FEATURE_SPAWN_RAMP: bool = true
## Tur dalgalardan oluşur (WaveData); kapalıyken Aşama 1'deki sonsuz, giderek hızlanan doğma.
const FEATURE_WAVES: bool = true
## Zombiler ekranın hemen dışında doğar; kapalıyken arena kenarında.
const FEATURE_SPAWN_OFFSCREEN: bool = true
## Ölen zombi kristal bırakır (hem XP hem para); kapalıyken hiçbir şey düşmez.
const FEATURE_PICKUPS: bool = true
## Seviye atlayınca kart seçimi (dalga arasında); kapalıyken seviye yalnız sayılır.
const FEATURE_LEVEL_CARDS: bool = true
const FEATURE_START_FULLSCREEN: bool = true
const FEATURE_DASH: bool = true
## Dash sırasında asker zombilerin içinden geçer (kapalıysa onları iter).
const FEATURE_DASH_PASS_THROUGH: bool = true
## Takla dokunulmazlığı yalnız ilk DASH_IFRAMES sn; sonrası ve çıkış hasar alır (kapalıyken: tüm takla + çıkış payı).
const FEATURE_DASH_EARLY_IFRAMES: bool = true
const FEATURE_DASH_DUST: bool = true
## Kapalıyken asker Aşama 1'deki kapsülle çizilir.
const FEATURE_PLAYER_MODEL: bool = true
## Kapalıyken zombiler Aşama 1'deki kutularla çizilir.
const FEATURE_ZOMBIE_MODEL: bool = true
## Zombi saldırısı: açıkken kısa hazırlıktan sonra vurur (kaçılabilir); kapalıyken eski "değince hasar".
const FEATURE_ZOMBIE_WINDUP_ATTACK: bool = true
## Dalgalarda koşucu ve tank da çıkar; kapalıyken yalnız yürüyen zombi (7.2).
const FEATURE_ZOMBIE_VARIETY: bool = true
## Dilci askeri bağlayabilir (hareket ve dash kilidi); kapalıyken dil yalnız görsel.
const FEATURE_ROOT: bool = true
## Zıplayan sıçrayıp işaretli yere iner; kapalıyken yürüyen gibi yaklaşıp vurur (7.3).
const FEATURE_ZOMBIE_JUMP: bool = true
## Dilci dilini atıp askeri bağlar; kapalıyken yürüyen gibi yaklaşıp vurur (7.3).
const FEATURE_ZOMBIE_TONGUE: bool = true
## 7.3 beş özel tür (docs: build/briefs/s73_design.md). Davranış bayrakları: kapalıyken tür yürüyen gibi davranır
## (zırhlı, çığlıkçı, patlayıcı) ya da dalga karışımından düşer; tükürücü ve taş fırlatan kapalıyken hiç doğmaz.
const FEATURE_ZOMBIE_ARMOR: bool = true
const FEATURE_ZOMBIE_SCREAM: bool = true
const FEATURE_ZOMBIE_SPIT: bool = true
const FEATURE_ZOMBIE_THROW: bool = true
const FEATURE_ZOMBIE_BLOAT: bool = true
## Taş fırlatan temas + throw_melee_range içindeyken atış yerine dev kolla yakın vuruş (swat) yapar.
const FEATURE_THROW_MELEE: bool = true
## Model bayrakları: Blender GLB'leri hazır olunca açılır (kapalıyken satır yürüyenin modeli + tint ile çizilir).
const FEATURE_ARMORED_MODEL: bool = true
const FEATURE_SCREAMER_MODEL: bool = true
const FEATURE_SPITTER_MODEL: bool = true
const FEATURE_THROWER_MODEL: bool = true
const FEATURE_BLOATER_MODEL: bool = true
## Yay atışı (asit topu, kaya): bırakış yüksekliği (m), görsel havuz boyu, kayanın yerde kalma ve solma süresi (sn),
## iniş sarsıntısı. Asit havuzu: en çok aynı anda, son söne süresi (sn). Asit hasarında ekran kızarması payı.
const LOB_RELEASE_HEIGHT: float = 1.3
const LOB_POOL_SIZE: int = 24
const LOB_TRAIL_STEP: float = 0.035
const ROCK_REST_TIME: float = 2.0
const ROCK_FADE_TIME: float = 0.4
const CAMERA_SHAKE_ON_ROCK: float = 0.15
const ACID_POOL_MAX: int = 12
## Patlayıcı: alandaki zombilere itme hızı, patlama sarsıntısı; şişerken parlama (yanıp sönme Hz: başta, sonda).
const BLOAT_ZOMBIE_KNOCKBACK: float = 9.0
## Çığlıkçı ses dalgası: halkanın büyüme süresi (sn), çağrı yarıçapına göre son yarıçap oranı, havuz boyu, sarsıntı.
const SCREAM_WAVE_TIME: float = 0.7
const SCREAM_WAVE_SCALE: float = 2.2
const SCREAM_WAVE_POOL: int = 4
const CAMERA_SHAKE_ON_SCREAM: float = 0.12
const CAMERA_SHAKE_ON_BLOAT: float = 0.3
const BLOAT_BLINK_START_HZ: float = 3.0
const BLOAT_BLINK_END_HZ: float = 14.0
const ACID_FADE_TIME: float = 1.0
## 11.5C asit havuzu: havuzdayken hareket yavaşlar (yüzde), havuzdan çıkınca ACID_BURN_LINGER sn yanma sürer
## (saniyede ACID_BURN_DPS, ACID_BURN_TICK'te bir parça; zırh uygulanır) ve yavaşlama da o süre sürer. Kapalıyken yalnız havuz tiki.
const FEATURE_ACID_POOL_SLOW_BURN: bool = true
const ACID_SLOW_PERCENT: float = 0.4
const ACID_BURN_DPS: float = 6.0
const ACID_BURN_LINGER: float = 0.5
const ACID_BURN_TICK: float = 0.25
const ACID_VIGNETTE_FLASH: float = 0.3
## 7.4 boss "Yığın" (build/briefs/s74_boss.md; sayılar EnemyDataBoss satırında). Kapalıyken 5. dalga eskisi gibi, boss doğmaz.
## 11.2: dalgaya göre zombi can/hasar çarpanı (WaveData enemy_hp_mult / enemy_damage_mult). Kapalıyken çarpan 1.0.
const FEATURE_WAVE_ENEMY_SCALING: bool = true
const FEATURE_BOSS: bool = true
## Boss Blender modeli (assets/models/characters/boss_heap.glb) ZombieModelData'ya eklenince açılır; kapalıyken büyütülmüş tank modeli + kızıl tint.
const FEATURE_BOSS_MODEL: bool = true
## Boss ölümünde kısa vuruş duraksaması (FEATURE_HIT_STOP kapalı olsa da yalnız burada).
const FEATURE_BOSS_HITSTOP: bool = true
const BOSS_HITSTOP_TIME: float = 0.18
## Boss uyarısı (yazı + kırmızı kenar nabzı) süresi (sn); boss uyarının bitiminde doğar.
const BOSS_WARNING_TIME: float = 2.0
## Boss canlıyken sürü doğma hızı çarpanı; boss ölünce dalga temizliği (sn; ölüm klibi oynasın, kristaller düşsün).
const BOSS_HORDE_FACTOR: float = 0.5
const BOSS_DEATH_CLEAR_TIME: float = 3.0
## Boss walk klibinin anahtarlandığı hız (m/sn; satırdaki hız x GAME_PACE ile aynı).
const BOSS_WALK_REF_SPEED: float = 1.28
## Boss ölümünde kristal yağmuru: drop_value bu kadar parçaya bölünür.
const BOSS_CRYSTAL_PIECES: int = 15
## Kristal yağmurunun saçılma çarpanı (PICKUP_HOP_DISTANCE katı).
const BOSS_RAIN_SPREAD: float = 4.0
## Hücumun askere ve zombilere verdiği itme hızı (m/sn; asker itilmesi FEATURE_PLAYER_KNOCKBACK ile kapalıysa yalnız hasar).
const BOSS_CHARGE_PLAYER_KNOCK: float = 10.0
const BOSS_CHARGE_ZOMBIE_KNOCK: float = 12.0
## Boss kamera sarsıntıları: yer dövme, hücum başlangıcı, duvara çarpma, kükreme, ölüm.
const CAMERA_SHAKE_ON_BOSS_SLAM: float = 0.55
const CAMERA_SHAKE_ON_BOSS_CHARGE: float = 0.25
const CAMERA_SHAKE_ON_BOSS_STUN: float = 0.45
const CAMERA_SHAKE_ON_BOSS_ROAR: float = 0.7
const CAMERA_SHAKE_ON_BOSS_DEATH: float = 0.8
## Şok halkası havuzu (en çok aynı anda), halkanın izinin (çatlak) kalma süresi (sn); hücum şeridi havuzu.
const BOSS_RING_POOL: int = 6
const BOSS_RING_SCAR_TIME: float = 1.6
const BOSS_STRIP_POOL: int = 2
## Hücumda toz izi aralığı (sn).
const BOSS_CHARGE_DUST_STEP: float = 0.12
## Zıplayanın iniş işareti yaklaşan cismin gölgesi gibi çizilir; kapalıyken eski kırmızı halka.
const FEATURE_JUMP_SHADOW_MARKER: bool = true
## Gölge: en koyu opaklık, yumuşaklık (yarıçap oranı; hazırlık başı / iniş anı), kenar çizgisi kalınlığı ve gücü,
## kilit nabzının süresi (sn).
const JUMP_SHADOW_DARKNESS: float = 0.7
const JUMP_SHADOW_SOFT_START: float = 0.6
const JUMP_SHADOW_SOFT_END: float = 0.12
const JUMP_SHADOW_EDGE_WIDTH: float = 0.035
const JUMP_SHADOW_EDGE_STRENGTH: float = 0.28
const JUMP_SHADOW_LOCK_PULSE_TIME: float = 0.25
## 11.5C zıplayan seri zıplar (çekirge): toplam JUMPER_CHAIN_MIN..MAX zıplama, aralarında satırdaki chain_pause sn
## iniş-bekleme (her inişin işareti yine önceden görünür); sonra normal toparlanma. Kapalıyken tek zıplama.
const FEATURE_JUMPER_CHAIN: bool = true
const JUMPER_CHAIN_MIN: int = 2
const JUMPER_CHAIN_MAX: int = 3
## Dil ıskalayınca ekranda kalma süresi (sn) ve bağlıyken dilin askerde bittiği yükseklik (m).
const TONGUE_MISS_SHOW_TIME: float = 0.25
## Dilci Blender'da üretilen yeni modeliyle (köşe renkli, kendi klipleri, yordamsal dil) çizilir;
## kapalıyken eski düz low-poly model ve kutu dil (V.4).
const FEATURE_DILCI_MODEL: bool = true
## Yürüyen Blender'da üretilen yeni modelleriyle (4 çeşit, köşe renkli, kendi klipleri) çizilir;
## kapalıyken eski zombie_walker.glb ve paylaşılan klip kütüphanesi (V.5).
const FEATURE_WALKER_MODEL: bool = true
## Koşucu Blender'da üretilen yeni modelleriyle (4 çeşit, köşe renkli, kendi klipleri) çizilir; yalnız
## FEATURE_RUNNER_SPRINT açıkken (yeni modelde atılış klibi yok). Kapalıyken eski zombie_runner.glb (V.5).
const FEATURE_RUNNER_MODEL: bool = true
## Zıplayan Blender'da üretilen yeni modelleriyle (3 çeşit, köşe renkli, kendi klipleri) çizilir (boy 1.38 m);
## kapalıyken eski zombie_jumper.glb ve paylaşılan klip kütüphanesi (V.5).
const FEATURE_JUMPER_MODEL: bool = true
## Tank Blender'da üretilen yeni modelleriyle (4 çeşit, köşe renkli, kendi klipleri) çizilir (boy 1.85 m);
## kapalıyken eski zombie_tank.glb ve paylaşılan klip kütüphanesi (V.5).
const FEATURE_TANK_MODEL: bool = true
## Yeni dil mekaniği (V.4): dil görünür hızla uçar (kaçılabilir), yakalarsa askeri dilciye doğru yavaşça
## çeker; kapalıyken eski anlık ışın + tam 1 sn bağ (7.3).
const FEATURE_TONGUE_PULL: bool = true
## Dilci askere temas + tongue_melee_range içindeyken dil yerine kısa yakın vuruş yapar.
const FEATURE_TONGUE_MELEE: bool = true
const TONGUE_PLAYER_HEIGHT: float = 1.1
## Dil ağı hızlı yol: indeks/UV bir kez, köşe tamponu yerinde güncellenir, az köşe, sarkarken seyrek kurma,
## ekran dışında kurma yok, sıkı AABB. Kapalıyken eski her-kare-yeniden-kurma yolu (V.4).
const FEATURE_TONGUE_MESH_FAST: bool = true
## Hızlı yolda halka sayısı (uzunluk boyunca), halka başına köşe aralığı (çevre) ve uç kapağı halkası.
const TONGUE_MESH_SAMPLES: int = 24
const TONGUE_MESH_RADIAL: int = 7
const TONGUE_MESH_CAP_RINGS: int = 3
## Sarkan dilde ağ her N karede bir kurulur (fırlatma, bağ ve geri çekilmede her karede).
const TONGUE_MESH_DANGLE_EVERY: int = 2
## Asker dilde sürüklenme ve kurtulma: Blender'da elle anahtarlanmış klipler (tools/blender/player_anims.py);
## kapalıyken eski türetilmiş çırpınma + kodla titreme (V.4).
const FEATURE_PLAYER_DRAG_CLIPS: bool = true
## Bağlıyken asker titremesi (yalnız FEATURE_PLAYER_DRAG_CLIPS kapalıyken): genlik (m) ve hız (rad/sn).
const PLAYER_STRUGGLE_SHAKE: float = 0.05
const PLAYER_STRUGGLE_RATE: float = 60.0
## Zıplayanın inişinde kamera sarsıntısı.
const CAMERA_SHAKE_ON_LAND: float = 0.25
## Koşucu hazırlanıp atılır; kapalıyken koşucu yürüyen gibi yaklaşıp vurur.
const FEATURE_ZOMBIE_LUNGE: bool = true
## Koşucu tetiklenince bir kez çığlık atar, sonra ölene dek durmadan koşar ve koşarken pençeler (SPRINT/STRIKE);
## kapalıyken eski çömel-atıl-toparlan döngüsü (lunge). Ayarlar EnemyData runner satırının sprint_v alanında.
const FEATURE_RUNNER_SPRINT: bool = true
## Zombiler yerden doğrularak doğar; kapalıyken doğrudan yürümeye başlar.
const FEATURE_ZOMBIE_SPAWN_RISE: bool = true
## Vurulan zombi geriye itilir.
const FEATURE_KNOCKBACK: bool = true
## Vurulan zombi kısa süre sendeler (saldırı hazırlığı bozulur).
const FEATURE_STAGGER: bool = true
## Ölen zombi ölüm animasyonu oynar ve solarak silinir; kapalıyken anında kaybolur.
const FEATURE_ZOMBIE_DEATH_ANIM: bool = true
## Silahlar askerin çevresinde süzülür, görünür ve kendi konumundan ateş eder; kapalıyken görünmez,
## askerin ortasından ateş eder.
const FEATURE_FLOATING_WEAPONS: bool = true
## Silahların durduğu, zırhın yansıttığı enerji çemberi (yalnız görüntü).
const FEATURE_ENERGY_RING: bool = true
## Aynı silah + aynı kademe yuvaya gelince birleşip üst kademe olur (6.4); kapalıysa kademe hep 1.
const FEATURE_WEAPON_MERGE: bool = true
## Dalga arası mağaza (6.5): kart seçiminden sonra açılır; kapalıyken eski 3 sn ara.
const FEATURE_SHOP: bool = true
## Raftaki ürün sayısı ve dolan yerin silah olma olasılığı.
const SHOP_OFFER_COUNT: int = 4
const SHOP_WEAPON_CHANCE: float = 0.4
## Fiyat artışı: her dalgada temel fiyatın bu kesri kadar.
const SHOP_PRICE_WAVE_GROWTH: float = 0.15  # 11.5B: 0.11 → 0.15 (Taha: mağaza ucuz)
## Tüm mağaza fiyatlarının genel çarpanı (11.5B: Taha'ya göre ucuz; tablolar değişmeden ~%30).
const SHOP_PRICE_MULT: float = 1.3
## Yenileme: ilk bedel ve her yenilemede artış (kristal); dalga başında sıfırlanır.
const SHOP_REROLL_BASE: int = 5
const SHOP_REROLL_STEP: int = 2
## Üstel yenileme (FEATURE_SHOP_REROLL_EXP): bedel = BASE x FACTOR^yapılan → 5, 25, 125, 625; dalga başında BASE'e döner.
const FEATURE_SHOP_REROLL_EXP: bool = true
const SHOP_REROLL_FACTOR: int = 5
## Üstel bedelin üst sınırı (taşmayı önler).
const SHOP_REROLL_MAX_COST: int = 100000
## Silah satışında geri ödenen kesir.
const SHOP_SELL_FRACTION: float = 0.5
## Yakın dövüş silahları (7.1): savurma/dürtme görseli (kesik izi) ve yanma etkisi (zombide turuncu parlama).
const FEATURE_MELEE_SLASH_FX: bool = true
const FEATURE_BURN: bool = true
## Bomba patlaması: görüntü (halka, parlama, kıvılcım) ve kamera sarsıntısı payı.
const FEATURE_EXPLOSION_FX: bool = true
const CAMERA_SHAKE_ON_EXPLOSION: float = 0.18
## Yanan zombiye iki yanma vuruşu arası (sn); hasar saniye başına verilir, vuruşa bölünür.
const BURN_TICK_INTERVAL: float = 0.5
## Birleşme animasyonu: silah büyüyüp oturur + parlar, halka ve kıvılcım patlar.
const FEATURE_MERGE_FX: bool = true
## Birleşme animasyonunun süresi (sn).
const MERGE_FX_TIME: float = 0.7
## Ağır silahlar (silah satırında fire_shake) atışta kamerayı hafifçe sarsar.
const FEATURE_FIRE_SHAKE: bool = true
## Mermi parlak, kuyruğu sönen bir iz olarak çizilir; kapalıyken eski sarı kutu.
const FEATURE_TRACERS: bool = true
const FEATURE_MUZZLE_FLASH: bool = true
const FEATURE_IMPACT_SPARKS: bool = true
## Vuruş geri bildirimi (5.3): kan sıçraması, yerde lekeler, hasar sayıları, öldürmede duraksama ve sarsıntı.
const FEATURE_BLOOD: bool = true
const FEATURE_BLOOD_DECALS: bool = true
const FEATURE_DAMAGE_NUMBERS: bool = false
const FEATURE_HIT_STOP: bool = false
const FEATURE_KILL_SHAKE: bool = true
## Asker vurulunca (5.4): ekran kenarı kızarması (can azken nabız) ve vuruştan uzağa kısa itilme.
const FEATURE_HURT_VIGNETTE: bool = true
const FEATURE_PLAYER_KNOCKBACK: bool = false
## Asker gövdesinin hıza ve dönüşe göre yatması.
const FEATURE_PLAYER_LEAN: bool = true
## Ses efektleri (5.5): ana anahtar + her ses için ayrı anahtar. Ses satırları scripts/data/sound_data.gd'de.
const FEATURE_SFX: bool = true
## Arayüz / akış sesleri (UI yolu): tıklama, mağaza, kart, dalga, seviye, ölüm, son ekranlar. Satırlar scripts/data/ui_sound_data.gd'de.
const FEATURE_SFX_UI: bool = true
## Düşük can kalp atışı (FEATURE_SFX_UI'dan ayrı anahtar).
const FEATURE_SFX_LOW_HEALTH: bool = true
## Can oranı bu değere ya da altına inince (ölü değilse) kalp atışı çalar.
const LOW_HEALTH_THRESHOLD: float = 0.3
## Kalp atışları arası süre (sn).
const LOW_HEALTH_BEAT_INTERVAL: float = 1.1
const FEATURE_SFX_SHOT: bool = true
## Silah sesleri v2 (8.4c): koyu/kapalı, gerçek .22 kaydı + sentez (w_*.wav). Kapalıysa eski silah sesleri.
## Zombiye isabet sesi: Taha'nın isteğiyle kapalı (her vuruşta rahatsız ediciydi); yerine sürü homurtusu.
const FEATURE_SFX_HIT: bool = false
## Askerin yakınındaki zombi sayısı arttıkça sıklaşan ve yükselen homurtu.
const FEATURE_SFX_HORDE_GROAN: bool = true
## Kalabalıkta zombi inlemesi katmanı (yalnız FEATURE_SFX_ZOMBIES ile birlikte): sürüden tek zombinin konumunda çalar.
const FEATURE_SFX_HORDE_MOANS: bool = true
## Zombi ölüm sesi: Taha'nın isteğiyle kapalı.
const FEATURE_SFX_ZOMBIE_DEATH: bool = false
const FEATURE_SFX_FOOTSTEP: bool = true
const FEATURE_SFX_DASH: bool = true
const FEATURE_SFX_DASH_ARMORED: bool = true  # zırhlı takla sesi (kapalıysa eski dash)
const FEATURE_SFX_PLAYER_HURT: bool = true
const FEATURE_SFX_PICKUP: bool = true
const FEATURE_SFX_PICKUP_DARK: bool = true  # koyu/kapalı kristal sesi (kapalıysa eski pickup)
## Zombi sesleri (8.4b): özel saldırı / yay / patlama / boss / zırh sesleri + yeni homurtu dosyaları. Kapalıyken eski sesler.
const FEATURE_SFX_ZOMBIES: bool = true
## Zombi düşme sesi (yalnız FEATURE_SFX_ZOMBIES ile birlikte işe yarar).
const FEATURE_SFX_ZOMBIE_BODYFALL: bool = true
## Ortam sesleri (8.4a): ana anahtar. Hepsi kapalıyken oyun eskisi gibi; alt anahtarlar tek tek kapatır.
const FEATURE_SFX_AMBIENCE: bool = true
## Ateş / neon / tel konumlarında 3B döngü sesleri (alıcı askerin üstünde).
const FEATURE_SFX_AMBIENCE_EMITTERS: bool = true
## Her zaman açık rüzgar ve uzak şehir uğultusu.
const FEATURE_SFX_AMBIENCE_BEDS: bool = true
## Ara sıra uzaktan siren / köpek / cam kırılması.
const FEATURE_SFX_AMBIENCE_DISTANT: bool = true

# --- Arena ---
## Işık ve zemin ön ayarı (LightingData tablosundan).
const LIGHTING_PRESET: StringName = &"dusk"
const ARENA_SIZE: float = 60.0
const ARENA_WALL_HEIGHT: float = 1.2
const ARENA_WALL_THICKNESS: float = 1.0
const ARENA_GROUND_MARGIN: float = 30.0

# --- Şehir greybox (8.1a; kavşak oyun alanının içinde, köşelerde çarpışmalı bloklar) ---
const FEATURE_CITY_GREYBOX: bool = true
## 8.1c: iç köşe blokları building_a.glb modeliyle görünür (kapalıyken düz kutu); çarpışma kutusu aynı kalır.
const FEATURE_CITY_BUILDINGS: bool = true
const CITY_BUILDING_SCENE: String = "res://assets/models/world/building_a.glb"
## 8.1f: yıkık araçlar, konteynerler, trafik lambaları, barikat parçaları ve kâğıt enkazı (scripts/data/city_props.gd tablosu).
## Kapalıyken eski kutu arabalar, kutu çöp kutuları ve kutu barikatlar çizilir.
const FEATURE_CITY_PROPS: bool = true
## Barikat hattı parça aralığı (m), parça ölçeği ve yaw sapması (derece); kâğıt enkazı sayısı.
const CITY_BARRICADE_STEP: float = 1.5
const CITY_BARRICADE_PIECE_SCALE: float = 1.2
const CITY_BARRICADE_YAW_JITTER: float = 10.0
const CITY_PAPER_COUNT: int = 24
## 8.1g: köşe rengini albedo'ya çarpan malzeme düzeltmesi, çöp/moloz yığınları, 8.2 engel adaları (her biri tek sabitle kapanır).
const FEATURE_CITY_PROP_COLORS: bool = true
const FEATURE_CITY_PILES: bool = true
const FEATURE_CITY_ISLANDS: bool = true
const CITY_PROP_SPECULAR: float = 0.1
## Adalar: merkezde bu yarıçapta boş alan, adalar arası en az bu geçit (m).
const CITY_ISLAND_CLEAR_RADIUS: float = 8.0
const CITY_ISLAND_MIN_GAP: float = 6.0
## Sokak genişliği (m): köşe blokları (ARENA_SIZE / 2 - bu / 2) kareler olur. Kol uzunluğu (alan dışı, görsel).
const CITY_STREET_WIDTH: float = 22.0
const CITY_STREET_LENGTH: float = 60.0
const CITY_SIDEWALK_WIDTH: float = 2.5
## Doğma noktası bloktan bu kadar (m) uzağa kaydırılır.
const CITY_SPAWN_STREET_MARGIN: float = 0.6
## 8.2: zombiler engelin (bina, prop) etrafından dolaşır; hızlı hareketler (atılış, hücum, iniş) ve tükürük/taş engele çarpar.
## Kapalıyken eski davranış: zombi düz yürür, engele sürtünerek kayar.
const FEATURE_OBSTACLE_STEER: bool = true
## Yönelimde ileriye bakış (m) ve teğete karışım dikliği (1 = yalnız en yakında tam teğet).
const OBSTACLE_STEER_LOOK: float = 2.5
const OBSTACLE_STEER_BLEND: float = 0.6
## 8.2c: yüksek köşe binaları görüş hattını keser: silahlar binanın ardındaki zombiyi hedeflemez, mermiler binaya çarpıp yok olur.
## Alçak engeller (prop, ada) kesmez. Kapalıyken eski davranış.
const FEATURE_BUILDING_LOS: bool = true
## Bu adımdan (m/kare) büyük hareketlerde engelden baştan başa geçme denetlenir.
const OBSTACLE_ANTI_TUNNEL_STEP: float = 0.15
## Tükürük / taş engele çarpınca durma payı (m) ve çarpışma yarıçapı (m); doğma / iniş kaydırma tur sayısı.
const OBSTACLE_SHOT_MARGIN: float = 0.15
const OBSTACLE_SHOT_RADIUS: float = 0.1
const OBSTACLE_SETTLE_PASSES: int = 3
## Alan içi dört blok yüksekliği (m; sıra: -x-z, +x-z, -x+z, +x+z). Kamerayı kapatmasın diye alçak.
const CITY_INNER_BLOCK_HEIGHTS: Array[float] = [9.0, 12.0, 7.0, 10.0]
## Kol ağzındaki ve kol ucundaki barikat kalınlığı ve yüksekliği (m).
const CITY_BARRICADE_DEPTH: float = 1.4
const CITY_BARRICADE_HEIGHT: float = 2.2
## Karanlık önizleme: ortam, güneş (ay) ve arka plan.
const CITY_AMBIENT_COLOR: Color = Color(0.32, 0.29, 0.28)
const CITY_AMBIENT_ENERGY: float = 0.09
const CITY_SUN_COLOR: Color = Color(0.7, 0.58, 0.46)
const CITY_SUN_ENERGY: float = 0.06
const CITY_BACKGROUND: Color = Color(0.035, 0.022, 0.015)
## Islak asfalt zemin (koyu gri, parlak).
const CITY_GROUND_COLOR: Color = Color(0.2, 0.17, 0.15)
const CITY_GROUND_ROUGHNESS: float = 0.6
## Omni ışık menzili (m) ve enerjisi: ateş, sokak lambası, neon.
const CITY_FIRE_RANGE: float = 5.5
const CITY_FIRE_ENERGY: float = 10.0
const CITY_LAMP_RANGE: float = 26.0
const CITY_LAMP_ENERGY: float = 10.0
## Sodyum lamba rengi (~2200K, turuncu-amber).
const CITY_LAMP_COLOR: Color = Color(1.0, 0.58, 0.2)
## Zayıf (titrek denen) lambanın enerji çarpanı.
const CITY_LAMP_WEAK_FACTOR: float = 0.45
const CITY_NEON_RANGE: float = 10.0
const CITY_NEON_ENERGY: float = 5.0

# --- 8.3b/8.3e: ateş, kor, kıvılcım, duman şeritleri, pus, neon (scripts/fx/city_fx.gd) ---
const FEATURE_CITY_FIRE_FX: bool = true
const FEATURE_CITY_NEON: bool = true
const FEATURE_CITY_LAMP_CONES: bool = true
const FEATURE_CITY_ASH: bool = true
## 8.3e: zemine sızan sahte ışık (additive radyal leke; ateş ve neon), yer seviyesi pus, vitrin ateşi.
const FEATURE_CITY_FAKE_LIGHT: bool = true
const FEATURE_CITY_HAZE: bool = true
const FEATURE_CITY_STOREFRONT_FIRE: bool = true
## Parçacık adetleri, kalite seviyesine göre [düşük, orta, yüksek] (profilde city_fx = 0/1/2); 0 = kapalı. Ateş başına (araç boyu).
const CITY_FX_FLAME_AMOUNT: Array[int] = [10, 20, 32]
const CITY_FX_SMOKE_AMOUNT: Array[int] = [0, 10, 16]
const CITY_FX_SPARK_AMOUNT: Array[int] = [4, 10, 18]
const CITY_FX_ASH_AMOUNT: Array[int] = [0, 12, 22]
const CITY_FX_EMBER_AMOUNT: Array[int] = [6, 16, 28]
## Çöp ateşinin boyutu (araç ateşine göre) ve konumları (sokak boyunca, merkez çevresi dahil; çarpışmasız).
const CITY_TRASH_FIRE_SCALE: float = 0.55
const CITY_TRASH_FIRES: Array[Vector3] = [Vector3(10.4, 0.0, -12.9), Vector3(-15.6, 0.0, -10.0), Vector3(5.5, 0.0, -4.0), Vector3(-6.0, 0.0, 5.5), Vector3(13.0, 0.0, 6.5), Vector3(-3.0, 0.0, 14.0)]
## Alev çıkış yüksekliği (m): araç kaputu / kabini; çöp ateşi bunun alt sınırı kadar.
const CITY_FIRE_FLAME_HEIGHT: float = 0.9
const CITY_FIRE_TRASH_HEIGHT: float = 0.15
## Alev dili boyutu (m), ömrü, çekirdek parlaklığı (HDR); kıvılcım çubuğu ve parlaklığı.
const CITY_FLAME_WIDTH: float = 1.2
const CITY_FLAME_HEIGHT: float = 1.5
const CITY_FLAME_LIFETIME: float = 0.6
const CITY_FLAME_HDR: float = 3.0
const CITY_SPARK_WIDTH: float = 0.09
const CITY_SPARK_LENGTH: float = 0.45
const CITY_SPARK_HDR: float = 7.0
const CITY_FIRE_FLICKER: float = 0.3
const CITY_FIRE_FLICKER_SPEED: float = 3.0
const CITY_FIRE_WOBBLE: float = 0.12
## Sahte zemin ışığı: yarıçap (m, araç ateşi), enerji, titreşim; kor yayılımı (m).
const CITY_FIRE_GLOW_RADIUS: float = 5.0
const CITY_FIRE_GLOW_ENERGY: float = 0.22
const CITY_FIRE_GLOW_FLICKER: float = 0.3
const CITY_FIRE_EMBER_RADIUS: float = 2.2
## Duman şeritleri: ömür, rüzgâr. Pus: iki katmanın yüksekliği, alfa, sürüklenme.
const CITY_SMOKE_LIFETIME: float = 5.0
## 8.3g: Kenney duman dokulu ince tül (kapalıyken eski şerit duman). Seviye başına adet; alfa düşük.
const FEATURE_CITY_KENNEY_SMOKE: bool = true
const CITY_KSMOKE_AMOUNT: Array[int] = [0, 5, 9]
const CITY_KSMOKE_LIFETIME: float = 6.5
const CITY_KSMOKE_SIZE: float = 6.0
const CITY_KSMOKE_ALPHA: float = 0.6
## Kaldırımdaki köşe sokak lambası altına sahte sodyum ışık havuzu.
const FEATURE_CITY_LAMP_POOL: bool = true
const CITY_LAMP_POOL_RADIUS: float = 6.5
const CITY_LAMP_POOL_ENERGY: float = 0.32
## Lambanın sokağa uzanan kolu (m) ve alan içi kenar lekeleri kapatıcısı.
const CITY_LAMP_ARM: float = 1.3
const FEATURE_CITY_STAINS: bool = false
const CITY_SMOKE_WIND: Vector3 = Vector3(1.1, 0.0, 0.4)
const CITY_SMOKE_HAZE_HEIGHTS: Array[float] = [0.6, 2.0]
const CITY_SMOKE_HAZE_ALPHA: float = 0.022
const CITY_SMOKE_HAZE_SIZE: float = 90.0
## Vitrin ateşi: duvar (z = sabit) üstünde orta nokta, genişlik (m), duvar düzlemi; içte turuncu parlayan pencere.
const CITY_FIRE_STOREFRONT: Vector3 = Vector3(16.0, 0.0, -10.9)
const CITY_FIRE_STOREFRONT_WIDTH: float = 5.0
const CITY_FIRE_STOREFRONT_LIGHT: float = 5.0
## Neon (tüp harf / şekil): yoğunluk, tüp kalınlığı, sızıntı lekesi (enerji, yarıçap), gerçek omni (yalnız "light": true olanlar).
const CITY_NEON_EMISSION: float = 2.2
const CITY_NEON_THICKNESS: float = 0.06
const CITY_NEON_SPILL_ENERGY: float = 0.3
const CITY_NEON_SPILL_RADIUS: float = 2.0
const CITY_NEON_LIGHT_ENERGY: float = 2.2
const CITY_NEON_LIGHT_RANGE: float = 8.0
## Tabela: text (BAR, OPEN, 24H, MOTEL, PIZZA) ya da shape (arrow, cup, barber); pos = duvar noktası (yükseklik y), n = duvardan dışa, u = yazı yönü,
## size = harf yüksekliği (m), broken = bir harf ölü, biri titrek.
const CITY_NEON_SPOTS: Array[Dictionary] = [
	{"text": "BAR", "pos": Vector3(-11.0, 3.2, -17.0), "n": Vector3(1, 0, 0), "u": Vector3(0, 0, 1), "size": 1.0, "color": Color(1.0, 0.1, 0.12), "broken": false, "light": true},
	{"text": "OPEN", "pos": Vector3(-17.0, 3.0, -11.0), "n": Vector3(0, 0, 1), "u": Vector3(1, 0, 0), "size": 0.8, "color": Color(0.1, 1.0, 0.3), "broken": false, "light": false},
	{"text": "24H", "pos": Vector3(11.0, 3.2, -22.0), "n": Vector3(-1, 0, 0), "u": Vector3(0, 0, 1), "size": 0.9, "color": Color(0.1, 0.9, 1.0), "broken": false, "light": true},
	{"text": "MOTEL", "pos": Vector3(-11.0, 3.4, 19.0), "n": Vector3(1, 0, 0), "u": Vector3(0, 0, 1), "size": 0.9, "color": Color(1.0, 0.2, 0.6), "broken": true, "light": false},
	{"text": "PIZZA", "pos": Vector3(17.0, 3.0, 11.0), "n": Vector3(0, 0, -1), "u": Vector3(1, 0, 0), "size": 0.8, "color": Color(1.0, 0.85, 0.6), "broken": false, "light": false},
	{"shape": &"arrow", "pos": Vector3(11.0, 3.0, 18.0), "n": Vector3(-1, 0, 0), "u": Vector3(0, 0, 1), "size": 1.0, "color": Color(0.1, 0.9, 1.0), "broken": false, "light": false},
	{"shape": &"cup", "pos": Vector3(-19.0, 3.0, 11.0), "n": Vector3(0, 0, -1), "u": Vector3(1, 0, 0), "size": 1.0, "color": Color(1.0, 0.8, 0.5), "broken": false, "light": false},
	{"shape": &"barber", "pos": Vector3(11.0, 3.0, 25.0), "n": Vector3(-1, 0, 0), "u": Vector3(0, 0, 1), "size": 1.1, "color": Color(1.0, 0.92, 0.8), "broken": false, "light": false},
]
## Sokak lambası: ampul, aşağı koni.
const CITY_LAMP_BULB_ENERGY: float = 5.0
const CITY_LAMP_CONE_RANGE: float = 9.0
const CITY_LAMP_CONE_ANGLE: float = 40.0
const CITY_LAMP_CONE_ENERGY: float = 6.0
const CITY_ASH_BOX: Vector3 = Vector3(16.0, 5.0, 12.0)

# --- 8.3a: atmosfer, ıslak zemin, karakter okunurluğu (her biri tek sabitle kapanır) ---
## Yükseklik sisi, parıltı (glow), renk ayarı, vinyet, yüksekte SSR ve hacimsel sis (profil açar).
const FEATURE_CITY_ATMOSPHERE: bool = true
## Zeminde birikinti maskesi (düşük pürüzlülük bölgeleri).
const FEATURE_WET_GROUND: bool = true
const ATMO_FOG_DENSITY: float = 0.0007
const ATMO_FOG_COLOR: Color = Color(0.07, 0.055, 0.045)
const ATMO_FOG_HEIGHT: float = 2.5
const ATMO_FOG_HEIGHT_DENSITY: float = 0.006
const ATMO_VOLUMETRIC_DENSITY: float = 0.0015
const ATMO_VOLUMETRIC_ALBEDO: Color = Color(0.45, 0.38, 0.33)
const ATMO_VOLUMETRIC_LENGTH: float = 50.0
const ATMO_GLOW_INTENSITY: float = 0.5
const ATMO_GLOW_THRESHOLD: float = 1.3
const ATMO_GLOW_BLOOM: float = 0.03
const ATMO_VIGNETTE_STRENGTH: float = 0.45
const ATMO_VIGNETTE_INNER: float = 0.5
## Renk ayarı: gölge ve parlak ton (kanal başına eğri uçları; gölgeler koyu sıcak kahve, ışıklar amber).
const ATMO_GRADE_SHADOW: Color = Color(0.02, 0.012, 0.012)
const ATMO_GRADE_HIGHLIGHT: Color = Color(1.0, 0.93, 0.8)
const ATMO_GRADE_MID: Color = Color(0.3, 0.27, 0.245)
## Birikinti: gürültü ölçeği (1/m), eşik (büyük = az birikinti), ıslak/kuru pürüzlülük.
const WET_PUDDLE_SCALE: float = 0.06
const WET_PUDDLE_THRESHOLD: float = 0.64
const WET_ROUGHNESS: float = 0.1
## Lamba/ateş çevresinde birikinti artışı: yarıçap (m) ve güç.
const WET_HOT_RADIUS: float = 7.0
const WET_HOT_BOOST: float = 0.1
const WET_DRY_ROUGHNESS: float = 0.65

# --- Genel tempo ---
## Oyunun genel hızı (1.0 = eski oyun). Hızlar çarpılır, süreler değil: asker yürüyüşü (PLAYER_SPEED),
## zombi hızları (EnemyData.PACED_KEYS), mermi hızları (WeaponData.get_row). Dash ve zamanlayıcılar aynı kalır.
## Engine.time_scale kullanılmaz.
const GAME_PACE: float = 0.8

# --- Asker ---
## Yürüme hızı (m/sn); GAME_PACE öncesi 6.0.
const PLAYER_SPEED: float = 6.0 * GAME_PACE
const PLAYER_ACCEL: float = 55.0
const PLAYER_FRICTION: float = 50.0
const PLAYER_MAX_HP: float = 100.0
const PLAYER_ARMOR: float = 0.0
## Can tabanı: eksi can bonusları max canı bunun altına indiremez.
const PLAYER_MIN_HP: float = 20.0
const PLAYER_RADIUS: float = 0.4
const PLAYER_HEIGHT: float = 1.8
const PLAYER_HIT_IFRAMES: float = 0.5
const PLAYER_TURN_SHARPNESS: float = 14.0

# --- Dash ---
const DASH_SPEED: float = 15.0
const DASH_DURATION: float = 0.35
const DASH_COOLDOWN: float = 6.0 # 11.5A: 1.4 → 8.0
## Takla başlangıcından itibaren yalnız bu kadar sn dokunulmaz (FEATURE_DASH_EARLY_IFRAMES).
const DASH_IFRAMES: float = 0.15
## Dash bittikten sonraki kısa dokunulmazlık (sn).
const DASH_EXIT_IFRAMES: float = 0.12
## Takla klibinin oynatıldığı süre (sn); dash'ten biraz uzun, kalkış koşuya karışır.
const DASH_ROLL_ANIM_TIME: float = 0.6
const DASH_DUST_AMOUNT: int = 24
const DASH_DUST_LIFETIME: float = 0.45

# --- Asker görüntüsü ---
## Asker dokusunun çarpıldığı renk: Tripo dokusu açık tonlu, yukarıdan ışıkta beyaza kaçıyor.
## Biraz koyu ve maviye çekilince lacivert zırh ve gri plakalar okunur. Color.WHITE = doku olduğu gibi.
const PLAYER_ALBEDO_TINT: Color = Color(0.62, 0.66, 0.82)
## 8.3j: gece zeminde ayrışsın diye daha açık albedo (yalnız albedo + pürüzlülük; ışık/emission yok). Kapalıyken eski tint.
const FEATURE_PLAYER_BRIGHT_ALBEDO: bool = true
const PLAYER_BRIGHT_ALBEDO_TINT: Color = Color(1.1, 1.15, 1.5)
const PLAYER_BRIGHT_ROUGHNESS: float = 0.7
## Animasyonlar arası geçiş süresi (sn).
const PLAYER_ANIM_BLEND: float = 0.15
## Vurulma klibinin girip çıkma süresi (sn).
const PLAYER_ANIM_HIT_FADE: float = 0.06
## Asker ölünce "öldün" ekranından önce ölüm animasyonuna tanınan süre (sn); 0 = beklemeden duraklat.
const GAME_OVER_DELAY: float = 1.8
## Son dalga temizlenince "hayatta kaldın" ekranından önceki süre (sn); 0 = beklemeden duraklat.
const VICTORY_DELAY: float = 1.5
## Koşu klibinin 1.0 hızda oynadığı yer hızı (m/sn); gerçek hız buna oranlanır (ayak kaymasın).
const PLAYER_RUN_ANIM_SPEED: float = 5.0
## Bekleme<->koşu harmanının hıza yetişme keskinliği.
const PLAYER_ANIM_MOVE_SHARPNESS: float = 14.0
## Yatma: tam hızda öne, dönüşte yana (derece) ve yumuşatma keskinliği.
const PLAYER_LEAN_FORWARD_DEG: float = 7.0
const PLAYER_LEAN_TURN_DEG: float = 14.0
const PLAYER_LEAN_TURN_GAIN: float = 0.35
const PLAYER_LEAN_SHARPNESS: float = 10.0

# --- Hasar ---
const MIN_DAMAGE_AFTER_ARMOR: float = 1.0
## Zırh azalan verimli yüzde: hasar x 100 / (100 + ARMOR_PERCENT_PER_POINT x zırh).
## 3 zırh ~ %15, 10 zırh ~ %37.5, 14 zırh ~ %46 indirim.
const ARMOR_PERCENT_PER_POINT: float = 3.5 # 11.4: 6.0 → 3.5, tank kurulumu bota %75–88 kazandırıyordu (3 zırh ≈ %9.5, 10 ≈ %26, 14 ≈ %33)
## Eksi zırh: puan başına yüzde fazla hasar, en çok ARMOR_NEGATIVE_MAX_BONUS (0.5 = +%50).
const ARMOR_NEGATIVE_PER_POINT: float = 4.0
const ARMOR_NEGATIVE_MAX_BONUS: float = 0.5
## Kapalıyken eski düz çıkarma (hasar - zırh).
const FEATURE_ARMOR_PERCENT: bool = true

# --- Zombi sürüsü ---
const ENEMY_SEPARATION_STRENGTH: float = 7.0
const ENEMY_MAX_SPEED_FACTOR: float = 1.6

# --- Zombi görüntüsü ---
## Ortak iskeletli modelin dinlenme pozundaki boyu; tür boyu buna oranlanır.
const CHARACTER_MODEL_HEIGHT: float = 1.83
## Yürüme klibinin hızı gerçek yatay hıza bağlanır (satırda walk_ref_speed olan türler; ayak kaymaz).
## Kapalıyken klip rastgele hızda (ZOMBIE_ANIM_SPEED_VARIANCE) oynar.
const FEATURE_WALK_SPEED_SYNC: bool = true
## Yeni yürüyen walk klibinin anahtarlandığı ilerleme hızı (m/sn, 1.6 m boyda model için).
const WALK_REF_SPEED: float = 2.6
## Yeni koşucu klipleri (walk, sprint) anahtarlandığı ilerleme hızları (m/sn, 1.3 m boyda model için).
const RUNNER_WALK_REF_SPEED: float = 3.0
const RUNNER_SPRINT_REF_SPEED: float = 5.2
## Yeni zıplayan walk klibinin anahtarlandığı hız (m/sn, 1.38 m boyda); çömelme -> leap harman süresi (sn).
const JUMPER_WALK_REF_SPEED: float = 2.4
const JUMPER_LEAP_BLEND: float = 0.05
## Yeni tank walk klibinin anahtarlandığı hız (m/sn, 1.85 m boyda).
const TANK_WALK_REF_SPEED: float = 1.2
## Yeni zırhlı, taş fırlatan ve patlayıcı walk klibinin anahtarlandığı hız (m/sn; satırdaki hız x GAME_PACE ile aynı).
const ARMORED_WALK_REF_SPEED: float = 1.6
const SCREAMER_WALK_REF_SPEED: float = 1.76
const SPITTER_WALK_REF_SPEED: float = 1.92
const THROWER_WALK_REF_SPEED: float = 1.84
const BLOATER_WALK_REF_SPEED: float = 1.92
## Senkron klip hızı sınırları ve kare başına yumuşatma payı (0-1).
const WALK_SPEED_SCALE_MIN: float = 0.3
const WALK_SPEED_SCALE_MAX: float = 1.8
const WALK_SPEED_SMOOTH: float = 0.25
## Zombiler aynı adımda yürümesin diye animasyon hızına eklenen rastgele pay (±).
const ZOMBIE_ANIM_SPEED_VARIANCE: float = 0.15
## Zombi boyuna eklenen rastgele pay (±); yalnız görüntü, çarpışma değişmez. 0 = kapalı.
const ZOMBIE_SCALE_VARIANCE: float = 0.08
## İtilme hızının sönme katsayısı (1/sn); büyüdükçe itme kısa ve sert olur.
const KNOCKBACK_DAMPING: float = 12.0
## Öldüren vuruşun itmesi bu kadar katlanır (ceset vuruş yönünde savrulur).
const ZOMBIE_DEATH_KNOCKBACK_FACTOR: float = 1.6
## Ölüm klibinin oynatma hızı.
const ZOMBIE_DEATH_ANIM_SPEED: float = 1.5
## Cesedin solmaya başlamadan önce yerde kaldığı süre ve solma süresi (sn).
const ZOMBIE_CORPSE_TIME: float = 1.5
const ZOMBIE_FADE_TIME: float = 0.5
## Zombi klipleri arası geçiş süresi (sn).
const ZOMBIE_ANIM_BLEND: float = 0.12

# --- Doğma ---
const SPAWN_INTERVAL_START: float = 1.0
const SPAWN_INTERVAL_MIN: float = 0.12
const SPAWN_INTERVAL_RAMP: float = 0.015
const SPAWN_BATCH_START: int = 1
const SPAWN_BATCH_GROWTH_SEC: float = 15.0
const SPAWN_MIN_PLAYER_DIST: float = 18.0
const SPAWN_EDGE_INSET: float = 1.0
const SPAWN_TRIES: int = 8
## Ekran dışı doğma: görünür alanın bu kadar dışında (m; ileri bakış ve zombi boyu payı).
const SPAWN_OFFSCREEN_MARGIN: float = 3.0
## Görünür alan hesabında en alçak bakış ışınının yatayla açısı (derece); alan sonsuza gitmesin.
const SPAWN_VIEW_MIN_RAY_DEG: float = 5.0

# --- Dalgalar (satırlar WaveData'da) ---
## Dalga bitince kalan zombilerin devrilip bittiği süre (sn).
const WAVE_CLEAR_TIME: float = 0.8
## Dalgalar arası bekleme (sn); 6.5'te mağaza buraya gelir.
const WAVE_BREAK_TIME: float = 3.0

# --- Kristaller (düşenler) ---
## Yerde aynı anda en çok kristal; dolunca yeni değer var olana eklenir (o büyür).
const PICKUP_MAX: int = 300
## Asker bu yarıçapa girince kristal ona çekilir (m); ileride "toplama menzili" istatistiği.
const PICKUP_MAGNET_RADIUS: float = 3.0
## Askerin merkezine bu kadar yaklaşınca toplanır (m).
const PICKUP_COLLECT_RADIUS: float = 0.6
## Çekilme: başlangıç hızı, ivme, üst hız (m/sn).
const PICKUP_PULL_START_SPEED: float = 3.0
const PICKUP_PULL_ACCEL: float = 45.0
const PICKUP_PULL_MAX_SPEED: float = 22.0
## Dalga sonunda hepsi çekilirken başlangıç hızı.
const PICKUP_COLLECT_ALL_SPEED: float = 8.0
## Düşerken sekme: süre (sn), tepe yüksekliği ve en çok yatay uzaklık (m).
const PICKUP_HOP_TIME: float = 0.35
const PICKUP_HOP_HEIGHT: float = 0.6
const PICKUP_HOP_DISTANCE: float = 0.8
## Görüntü: yerden yükseklik, boy, değer başına büyüme ve en çok büyüme.
const PICKUP_HEIGHT: float = 0.35
const PICKUP_SIZE: float = 0.11
## Kristal kesimi: köşe sayısı, üst ve alt ucun boyu (yarıçapa oranla).
const PICKUP_CRYSTAL_SIDES: int = 6
const PICKUP_CRYSTAL_TOP: float = 2.2
const PICKUP_CRYSTAL_BOTTOM: float = 1.0
const PICKUP_VALUE_SCALE: float = 0.12
const PICKUP_MAX_SCALE: float = 2.0
## Beyazımsı, çok hafif buz mavisi.
const PICKUP_COLOR: Color = Color(0.86, 0.95, 1.0)
## Seviye için gereken XP: XP_LEVEL_SCALE x (seviye + XP_LEVEL_OFFSET)^XP_LEVEL_POWER. 11.5B: eski eğri ölçek 1.0, üs 2.0 (1→2: 16 kristal).
const XP_LEVEL_OFFSET: int = 3
const XP_LEVEL_SCALE: float = 1.5
const XP_LEVEL_POWER: float = 2.2
## Ölen zombinin kristal bırakma olasılığı (satırda drop_chance yoksa DROP_CHANCE_DEFAULT). Boss yağmuru her zaman düşer.
const FEATURE_DROP_CHANCE: bool = true
const DROP_CHANCE_WALKER: float = 0.5
const DROP_CHANCE_SPECIAL: float = 0.8
const DROP_CHANCE_DEFAULT: float = 1.0
## Dalga sonunda yerdeki kristaller otomatik toplanmaz; yeni dalga başlayınca silinir (kapalıyken eski otomatik toplama).
const FEATURE_WAVE_END_NO_AUTOCOLLECT: bool = true

# --- İstatistikler ve kartlar (satırlar StatData / CardData'da) ---
const CARD_OFFER_COUNT: int = 3
## Bir can yenileme puanı saniyede bu kadar can.
const HP_REGEN_PER_POINT: float = 0.2 # 11.4: 0.25 → 0.2 (tank kurulumu)
## Dash bekleme süresi en çok bu yüzde kadar kısalır.
const DASH_COOLDOWN_CUT_CAP: float = 60.0
## Hareket hızı bonusu en çok bu yüzde olur (11.5A).
const MOVE_SPEED_BONUS_CAP: float = 50.0
## Yüzdelik istatistik eksiye düşse bile çarpan bunun altına inmez (ileride eksi veren eşyalar).
const MIN_STAT_MULTIPLIER: float = 0.1

# --- Mermi ---
const PROJECTILE_POOL_SIZE: int = 128
const PROJECTILE_RADIUS: float = 0.12
const PROJECTILE_HEIGHT: float = 1.1

# --- Süzülen silahlar ---
const WEAPON_SLOTS: int = 6
## Silah çemberinin yarıçapı (m) ve yerden yüksekliği.
const WEAPON_ORBIT_RADIUS: float = 1.0
const WEAPON_HOVER_HEIGHT: float = 1.1
## İlk silahın açısı (derece; 0 = ekranda askerin sağı, dünya +X).
const WEAPON_START_ANGLE_DEG: float = 0.0
const WEAPON_AIM_SHARPNESS: float = 22.0
## Geri tepmenin toparlanma hızı ve namlunun kalkma açısı.
const WEAPON_RECOIL_RECOVER: float = 14.0
const WEAPON_RECOIL_PITCH_DEG: float = 14.0
const WEAPON_BOB_HEIGHT: float = 0.05
const WEAPON_BOB_SPEED: float = 2.4
## Enerji çemberinin rengi ve silahların altındaki yüksekliği (m).
const ENERGY_RING_COLOR: Color = Color(1.0, 0.55, 0.15)
const ENERGY_RING_DROP: float = 0.14
## Kan: isabette yere leke düşme olasılığı, ölümde sıçrama çarpanı, lekenin yaşam ve solma süresi (sn).
const BLOOD_DECAL_CHANCE_HIT: float = 0.3
const BLOOD_KILL_MULTIPLIER: int = 3
const BLOOD_DECAL_LIFETIME: float = 12.0
const BLOOD_DECAL_FADE_TIME: float = 3.0
## Öldürmede duraksama: süre (gerçek sn), oyun hızı ve iki duraksama arası bekleme.
const HIT_STOP_KILL_TIME: float = 0.045
const HIT_STOP_TIME_SCALE: float = 0.08
const HIT_STOP_COOLDOWN: float = 0.3
const CAMERA_SHAKE_ON_KILL: float = 0.12
## Asker vurulunca: kızarmanın gücü ve sönme süresi; can bu oranın altındayken kenar nabız atar.
const HURT_VIGNETTE_STRENGTH: float = 0.85
const HURT_VIGNETTE_FADE_TIME: float = 0.45
const LOW_HP_THRESHOLD: float = 0.35
const LOW_HP_VIGNETTE: float = 0.55
const LOW_HP_PULSE_RATE: float = 1.2
## Askerin vurulunca aldığı ilk itme hızı (m/sn) ve sönmesi; kat edilen yol = hız / sönme.
const PLAYER_HIT_KNOCKBACK: float = 6.0
const PLAYER_KNOCKBACK_DAMPING: float = 11.0
## Debug: F7 ile eklenen silahlar, sırayla (eldeki silah sayısına göre; tabancayla başlanınca ilk F7 pompalı).
const DEBUG_WEAPONS: Array[StringName] = [&"pistol", &"shotgun", &"knife", &"katana", &"lightsaber", &"flame_sword", &"smg", &"plasma_rifle", &"gravity_gun", &"grenade_launcher"]
const PROJECTILE_LENGTH: float = 0.6
const PROJECTILE_THICKNESS: float = 0.1
## Mermi izi (FEATURE_TRACERS): uzunluk ve kalınlık (m).
const TRACER_LENGTH: float = 1.1
const TRACER_THICKNESS: float = 0.05
## Namlu parlaması: süre (sn), boy (m), ışık enerjisi ve menzili.
const MUZZLE_FLASH_TIME: float = 0.06
const MUZZLE_FLASH_SIZE: float = 0.55
const MUZZLE_LIGHT_ENERGY: float = 2.5
const MUZZLE_LIGHT_RANGE: float = 3.0
const PROJECTILE_LIFETIME_MARGIN: float = 1.15

# --- Kamera ---
const CAMERA_PITCH_DEG: float = 60.0
const CAMERA_DISTANCE: float = 37.2
const CAMERA_FOV: float = 30.0
const CAMERA_FOLLOW_SHARPNESS: float = 8.0
## İleri bakış: kamera, askerin bu kadar saniye sonra olacağı yere doğru kayar.
const CAMERA_LOOK_AHEAD_TIME: float = 0.25
const CAMERA_LOOK_AHEAD_SHARPNESS: float = 3.0
## Sarsıntı: en çok kayma (m), gürültü hızı, sönme hızı (1/sn) ve asker vurulunca eklenen pay.
## Dinamik açı: koşu yönüne göre en çok yaw / pitch ofseti (derece) ve yumuşatma
const CAMERA_DYN_YAW_DEG: float = 7.0
const CAMERA_DYN_PITCH_DEG: float = 5.0
const CAMERA_DYN_SHARPNESS: float = 2.5
const CAMERA_SHAKE_MAX_OFFSET: float = 0.6
const CAMERA_SHAKE_FREQUENCY: float = 6.0
const CAMERA_SHAKE_DECAY: float = 2.2
const CAMERA_SHAKE_ON_PLAYER_HIT: float = 0.45

# --- Ses ---
## Aynı anda çalabilecek en çok ses (havuzdaki oynatıcı sayısı).
const SFX_POOL_SIZE: int = 32
## Konumlu sesler (Audio.play_at): bu yarıçapa (m) kadar tam ses, MAX'ta MIN_DB kadar kısık, ötesinde çalmaz.
const SFX_DISTANCE_FULL: float = 8.0
const SFX_DISTANCE_MAX: float = 34.0
const SFX_DISTANCE_MIN_DB: float = -18.0
## Ses yolları (bus) düzeyi, dB. Master -> SFX / Ambience / UI / Music (UI ve Music şimdilik boş).
const BUS_VOLUME_SFX_DB: float = 0.0
const BUS_VOLUME_AMBIENCE_DB: float = -4.0
const BUS_VOLUME_UI_DB: float = 0.0
const BUS_VOLUME_MUSIC_DB: float = 0.0
## Ortam: tohum (başlangıç ofsetleri, uzak ses seçimi) ve uzak sesler.
const AMBIENCE_SEED: int = 8401
## Uzak seslerin iki çalış arası süre aralığı (sn) ve ilk sesten önceki en kısa bekleme.
const AMBIENCE_DISTANT_INTERVAL_MIN: float = 25.0
const AMBIENCE_DISTANT_INTERVAL_MAX: float = 60.0
## Uzak sesin askerden uzaklığı (m); yön rastgele, düzey sabit (yalnız panlama yönü verir).
const AMBIENCE_DISTANT_DISTANCE: float = 60.0
## Uzak sesler için sabit oynatıcı sayısı.
const AMBIENCE_DISTANT_POOL_SIZE: int = 2
## Ateş/neon/tel yayıcılarının ses yüksekliği (m; yerden).
const AMBIENCE_EMITTER_HEIGHT: float = 1.2
## Adım sesi: koşu klibinin bir döngüsündeki adım sayısı (adım boyu klipten türetilir).
const FOOTSTEP_STEPS_PER_CYCLE: int = 2
## Bu hızın altında adım sesi çalmaz (m/sn).
const FOOTSTEP_MIN_SPEED: float = 1.0
## Sürü homurtusu: askerin çevresinde sayılan yarıçap (m); bu sayının altında sessiz, bu sayıda en yoğun.
const HORDE_GROAN_RADIUS: float = 10.0
const HORDE_GROAN_MIN_COUNT: int = 5
const HORDE_GROAN_FULL_COUNT: int = 40
## İki homurtu arası süre (sn): seyrek sürüde / en yoğun sürüde. Üstüne ± oransal rastgele pay.
const HORDE_GROAN_INTERVAL_SPARSE: float = 3.0
const HORDE_GROAN_INTERVAL_DENSE: float = 0.4
const HORDE_GROAN_JITTER: float = 0.4
## Seyrek sürüde homurtu bu kadar kısık (dB); en yoğunda tablo düzeyinde.
const HORDE_GROAN_SPARSE_DB: float = -10.0
## Yoğunluk kaç saniyede bir sayılır.
const HORDE_GROAN_CHECK_TIME: float = 0.25
## İnleme katmanı: bu sayının altında kapalı; iki inleme arası süre (sn) bu sayıda HORDE_MOAN_INTERVAL_SPARSE, HORDE_GROAN_FULL_COUNT'ta DENSE; ± oransal rastgele pay.
const HORDE_MOAN_MIN_COUNT: int = 12
const HORDE_MOAN_INTERVAL_SPARSE: float = 2.5
const HORDE_MOAN_INTERVAL_DENSE: float = 0.6
const HORDE_MOAN_JITTER: float = 0.3

# --- Uzay ızgarası ---
const GRID_CELL_SIZE: float = 1.5

# --- Geri bildirim ---
const HIT_FLASH_TIME: float = 0.08
const PLAYER_BLINK_RATE: float = 20.0

# --- Debug ---
const DEBUG_SPAWN_BATCH: int = 50
const DEBUG_PANEL_REFRESH: float = 0.25
## Ekran görüntüsü araçları (battle_hud / market_shot): hover çağrılmadan önce arayüzün oturmasını bekleme süresi (sn).
const UI_SHOT_SETTLE_TIME: float = 0.6
## Capture --capture-pick: kart ekranında tuşa basmadan önce bekleme (sn).
const CAPTURE_PICK_DELAY: float = 0.5
const BENCH_STEP_ENEMIES: int = 50
const BENCH_STEP_TIME: float = 3.0
const BENCH_MEASURE_TIME: float = 2.0
const BENCH_TARGET_FPS: float = 60.0
const BENCH_MAX_ENEMIES: int = 2000
const BENCH_FAIL_STEPS: int = 2
const BENCH_TURN_RATE: float = 0.6
## Sabit sayı ölçümü (--bench-kind + --bench-count): ısınma ve ölçüm süresi (sn), türün askerin çevresine dizildiği yarıçap (m).
const BENCH_FIXED_WARMUP: float = 4.0
const BENCH_FIXED_TIME: float = 10.0
const BENCH_FIXED_RING: float = 9.0

## 1v1 debug arenası (--arena[=tür] ya da scenes/debug/arena.tscn): kapatılırsa normal oyun açılır.
const FEATURE_DEBUG_ARENA: bool = true
## Zombinin askerden doğma uzaklığı (m) ve ölümden sonra yenisinin doğma gecikmesi (sn).
const DEBUG_ARENA_SPAWN_DIST: float = 6.5
const DEBUG_ARENA_RESPAWN_DELAY: float = 2.0

# --- 8.3d: sıcak ışık dili, yer dekoru, teller (scripts/world/city_ground_dressing.gd, city_wires.gd) ---
const FEATURE_CITY_GROUND_DRESSING: bool = true
const FEATURE_CITY_WIRES: bool = true
## 8.3i: sokak cesetleri = oyunun zombi modelleri, ölüm klibinin son karesinde (scripts/world/city_zombie_corpses.gd).
const FEATURE_CITY_ZOMBIE_CORPSES: bool = true
## Yer dekoru adetleri (yüksek profil; profildeki ground_dressing çarpanı uygulanır).
const DRESS_DEBRIS_COUNT: int = 560
const DRESS_BLOOD_POOLS: int = 26
const DRESS_BLOOD_TRAILS: int = 14
const DRESS_CONES: int = 14
const DRESS_SIGNS: int = 6
const DRESS_CORPSES: int = 9
const DRESS_SEED: int = 8304
## 8.3j: koniler cesetlere bu mesafeden (m) yakın durmaz; yalnız çakışan koni taşınır.
const FEATURE_CITY_CONE_CLEAR: bool = true
const DRESS_CONE_CORPSE_GAP: float = 2.2
## Dekorun yayıldığı yer: merkezde yoğun (alan içi payı) ve kol uzunluğu boyunca.
const DRESS_ARENA_SHARE: float = 0.75
const DRESS_DEBRIS_SIZE: Vector2 = Vector2(0.1, 0.6)
const DRESS_BLOOD_COLOR: Color = Color(0.4, 0.04, 0.035, 0.8)
# --- 8.3h: kan sıçraması, koyu kâğıt, zemin lekeleri, cephe ışıkları (city_decals.gd, city_facade_lights.gd) ---
## Kan: Kenney maskeli gölcük/sıçrama/sürüklenme/ayak izi (kapalıysa kan lekesi yok). Zemin: yanık, yağ, lastik izi, çatlak.
const FEATURE_CITY_BLOOD_DECALS: bool = true
const FEATURE_CITY_GROUND_DECALS: bool = true
## Kâğıt biçimleri (yırtık köşe, buruşuk kenar); kapalıysa düz dikdörtgen. Değer çarpanı aralığı (düşük = koyu).
const FEATURE_CITY_PAPER_SHAPES: bool = true
const CITY_PAPER_VALUE: Vector2 = Vector2(0.5, 0.8)
const CITY_BLOOD_FOOTPRINTS: int = 8
const CITY_BLOOD_SPLASHES: int = 30
const CITY_SCORCH_BLASTS: int = 8
const CITY_OIL_COUNT: int = 36
const CITY_SKID_COUNT: int = 8
const CITY_CRACK_COUNT: int = 26
## Bina cepheleri: yanan pencereler, duvar lambaları (sahte ışık). Cephe düzlemi bloktan dışarı payı (m).
const FEATURE_CITY_FACADE_LIGHTS: bool = true
const CITY_FACADE_OFFSET: float = 0.13
## 8.3i: pencereler bina A'nın modelindeki gerçek ızgarayla hizalı (tools/blender/build_city_building.py: WIN_U, WIN_Z, WIN_W/H, HALF).
## Satır = kat (F2, F3), harf = pencere durumu: B kırık, L yanan, O tahtalı, D karanlık, - yok. Yalnız D ve L üstüne cam çizilir.
const CITY_FACADE_HALF: float = 9.5
const CITY_FACADE_WINDOW_U: Array[float] = [-7.2, -3.6, 0.0, 3.6, 7.2]
const CITY_FACADE_WINDOW_Z: Array[float] = [6.0, 9.4]
const CITY_FACADE_WINDOW_SIZE: Vector2 = Vector2(1.6, 1.8)
const CITY_FACADE_MODEL_X: Array[String] = ["BLODB", "-ODDB"]
const CITY_FACADE_MODEL_Z: Array[String] = ["ODDLB", "DBOD-"]
## Yanan pencerelerin çizilme olasılığı; karanlıkların soluk mavi TV olma olasılığı.
const CITY_FACADE_LIT_KEEP: float = 0.6
const CITY_FACADE_TV_CHANCE: float = 0.08
const CITY_FACADE_LAMPS_PER_FACE: int = 2
const CITY_FACADE_LAMP_HEIGHT: float = 4.2
const CITY_FACADE_LAMP_COLOR: Color = Color(1.0, 0.62, 0.25)
const CITY_FACADE_LAMP_RADIUS: float = 2.3
const CITY_FACADE_LAMP_WALL_ENERGY: float = 0.4
const CITY_FACADE_LAMP_GROUND_ENERGY: float = 0.28
## 8.3j: dış blokların (OUTER_BLOCKS, eğik olmayan) sokağa bakan yüzlerine pencere ızgarası; tek MultiMesh, gölgesiz.
## Kapalı: duvarlar simsiyah olduğu için yanan pencere boşlukta asılı görünüyor.
const FEATURE_CITY_OUTER_WINDOWS: bool = false
const CITY_OUTER_WINDOW_COL_STEP: float = 3.6
const CITY_OUTER_WINDOW_FLOOR_STEP: float = 3.4
const CITY_OUTER_WINDOW_FIRST_Z: float = 3.2
const CITY_OUTER_WINDOW_TOP_MARGIN: float = 2.2
const CITY_OUTER_WINDOW_EDGE_MARGIN: float = 1.8
## Yüzün sokak kolu şeridine bitişikliği: blok kenarı bu mesafeden (m) yakınsa yüz sokağa bakar.
const CITY_OUTER_WINDOW_STREET_REACH: float = 16.0
const CITY_OUTER_WINDOW_LIT_CHANCE: float = 0.07
const CITY_OUTER_WINDOW_LIT_COLOR: Color = Color(0.5, 0.25, 0.07, 0.95)
const CITY_OUTER_WINDOW_DARK_COLOR: Color = Color(0.012, 0.012, 0.016, 0.55)
## 8.3j: bina modelindeki yanan pencere malzemesi ("warm", emisyon gücü 7) patlıyordu; çalışma zamanında sönük ambere indirilir.
const FEATURE_CITY_WINDOW_DIM: bool = true
const CITY_WINDOW_DIM_MATERIAL: String = "warm"
const CITY_WINDOW_DIM_ENERGY: float = 1.3
const CITY_WINDOW_DIM_COLOR: Color = Color(1.0, 0.5, 0.13)
## Çift sarı orta şerit: renk, çizgi eni, iki çizgi arası (m).
const CITY_LANE_COLOR: Color = Color(0.62, 0.44, 0.1)
const CITY_LANE_WIDTH: float = 0.13
const CITY_LANE_GAP: float = 0.3
## Elektrik telleri: sayı yerine çift tablosu kodda (blok köşeleri); sarkma (m) ve kalınlık (m).
const WIRE_SAG: Vector2 = Vector2(1.0, 1.7)
const WIRE_RADIUS: float = 0.03
## Elektrik direği: yükseklik (m) ve kablo sayısı / aralığı (m).
const POLE_HEIGHT: float = 8.5
const WIRE_COUNT: int = 4
const WIRE_SPACING: float = 0.7
## 8.3j: direk askeri kapatınca yarı saydam (noktalı eleme). Yarıçap (m) kamera-asker ışınının direk eksenine yakınlığı,
## hedef = elenen nokta oranı (0-1), hız = saniyedeki değişim, hedef yüksekliği askerin gövdesi (m).
const FEATURE_POLE_FADE: bool = true
const POLE_FADE_RADIUS: float = 1.1
const POLE_FADE_AMOUNT: float = 0.85
const POLE_FADE_SPEED: float = 4.0
const POLE_FADE_TARGET_HEIGHT: float = 1.0
## Merkez kavşak ışığı (trafik lambası): asker merkezde başlar.
const CITY_CENTER_LIGHT_ENERGY: float = 8.0
const CITY_CENTER_LIGHT_RANGE: float = 12.0
const CITY_CENTER_LIGHT_COLOR: Color = Color(1.0, 0.72, 0.4)
## 8.3j: batı kolu (x < -10) doğudan karanlıktı; görünür kaynaklar: sönmekte olan çöp ateşleri (küçük ateş + zemin sızıntısı), omni yok.
const FEATURE_CITY_WEST_LIGHT: bool = true
const CITY_WEST_FIRES: Array[Vector3] = [Vector3(-18.5, 0.0, 5.5), Vector3(-26.5, 0.0, -7.0)]
const CITY_WEST_FIRE_SCALE: float = 0.3
## Her kaynağın ek sıcak zemin sızıntısı: yarıçap (m), güç (glow_quad energy), titreme.
const CITY_WEST_GLOW_RADIUS: float = 8.0
const CITY_WEST_GLOW_ENERGY: float = 0.03
const CITY_WEST_GLOW_FLICKER: float = 0.35
const CITY_WEST_GLOW_COLOR: Color = Color(1.0, 0.58, 0.2)
const WIRE_COLOR: Color = Color(0.015, 0.012, 0.012)

# --- Ödül çantaları (haritada süzülen para / XP çantası) ---
## Ana bayrak: kapalıyken oyun eskisi gibi (çanta yok). Ok: ekran dışı çantayı kenarda gösterir. Model: assets/models/props/reward_bag.glb varsa yer tutucu yerine yüklenir.
const FEATURE_REWARD_BAGS: bool = true
const FEATURE_BAG_ARROW: bool = true
const FEATURE_BAG_MODEL: bool = true
const BAG_MODEL_PATH: String = "res://assets/models/props/reward_bag.glb"
## Dalga içinde ilk çanta (sn), sonrakiler arası süre (sn), dalga başına en çok çanta (aynı anda en çok 1).
const BAG_FIRST_DELAY: float = 15.0
const BAG_INTERVAL: float = 25.0
const BAG_MAX_PER_WAVE: int = 3
## Değer: BASE + PER_WAVE x dalga no (1. dalga 20). Para çantası yalnız para, XP çantası yalnız XP verir.
const BAG_VALUE_BASE: int = 15
const BAG_VALUE_PER_WAVE: int = 5
## Askere uzaklık aralığı (m), bina/engele en az boşluk (m), arena kenarından iç pay (m), konum deneme sayısı.
const BAG_MIN_DIST: float = 12.0
const BAG_MAX_DIST: float = 24.0
const BAG_CLEARANCE: float = 0.8
const BAG_ARENA_MARGIN: float = 2.0
const BAG_PLACE_TRIES: int = 24
## Ömür (sn); son BAG_BLINK_TIME sn BAG_BLINK_RATE Hz ile yanıp söner.
const BAG_LIFETIME: float = 15.0
const BAG_BLINK_TIME: float = 3.0
const BAG_BLINK_RATE: float = 4.0
## Toplama yarıçapı (m; mıknatıs yok).
const BAG_COLLECT_RADIUS: float = 1.0
## Görünüm: yerden yükseklik, süzülme genliği (m) ve hızı (rad/sn), dönme hızı (rad/sn), boy çarpanı, zemin halkası yarıçapı (m).
const BAG_HOVER_HEIGHT: float = 0.55
const BAG_BOB_AMPLITUDE: float = 0.12
const BAG_BOB_SPEED: float = 2.2
const BAG_SPIN_SPEED: float = 0.9
const BAG_SCALE: float = 2.2
## Toplama patlamasının tutucu düğümünün silinme süresi (sn; MergeBurst 0.75 sn sürer).
const BAG_BURST_HOLD_TIME: float = 1.0
## GLB kristallerinin (BagTint) tür rengindeki parlama gücü.
const BAG_CRYSTAL_GLOW: float = 2.5
const BAG_RING_RADIUS: float = 0.95
const BAG_LIGHT_ENERGY: float = 0.9
const BAG_LIGHT_RANGE: float = 4.5
const BAG_MONEY_COLOR: Color = Color(1.0, 0.68, 0.14)
const BAG_XP_COLOR: Color = Color(0.3, 0.62, 1.0)
## Ekran dışı oku: kenardan pay ve boy (px).
const BAG_ARROW_MARGIN: float = 56.0
const BAG_ARROW_SIZE: float = 16.0
## Debug --capture-bag: çanta askerin bu ofsetinde (m) hemen belirir.
const BAG_DEBUG_OFFSET: Vector2 = Vector2(3.0, -5.0)
