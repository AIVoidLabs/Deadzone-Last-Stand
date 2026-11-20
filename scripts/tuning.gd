class_name Tuning
extends RefCounted
## Tüm genel oynanış sayıları burada. İçerik satırları (zombi, silah) scripts/data/ tablolarında.

# --- Özellik anahtarları (her özellik tek sabitle kapanır) ---
const FEATURE_SEPARATION: bool = true
const FEATURE_CAMERA_SMOOTHING: bool = true
const FEATURE_CAMERA_LOOK_AHEAD: bool = true
const FEATURE_CAMERA_SHAKE: bool = true
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
const FEATURE_ARMORED_MODEL: bool = false
const FEATURE_SCREAMER_MODEL: bool = false
const FEATURE_SPITTER_MODEL: bool = false
const FEATURE_THROWER_MODEL: bool = false
const FEATURE_BLOATER_MODEL: bool = false
## Yay atışı (asit topu, kaya): bırakış yüksekliği (m), görsel havuz boyu, kayanın yerde kalma ve solma süresi (sn),
## iniş sarsıntısı. Asit havuzu: en çok aynı anda, son söne süresi (sn). Asit hasarında ekran kızarması payı.
const LOB_RELEASE_HEIGHT: float = 1.3
const LOB_POOL_SIZE: int = 24
const LOB_TRAIL_STEP: float = 0.035
const ROCK_REST_TIME: float = 2.0
const ROCK_FADE_TIME: float = 0.4
const CAMERA_SHAKE_ON_ROCK: float = 0.15
const ACID_POOL_MAX: int = 12
const ACID_FADE_TIME: float = 1.0
const ACID_VIGNETTE_FLASH: float = 0.3
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
const SHOP_PRICE_WAVE_GROWTH: float = 0.15
## Yenileme: ilk bedel ve her yenilemede artış (kristal); dalga başında sıfırlanır.
const SHOP_REROLL_BASE: int = 5
const SHOP_REROLL_STEP: int = 2
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
const FEATURE_DAMAGE_NUMBERS: bool = true
const FEATURE_HIT_STOP: bool = false
const FEATURE_KILL_SHAKE: bool = true
## Asker vurulunca (5.4): ekran kenarı kızarması (can azken nabız) ve vuruştan uzağa kısa itilme.
const FEATURE_HURT_VIGNETTE: bool = true
const FEATURE_PLAYER_KNOCKBACK: bool = false
## Asker gövdesinin hıza ve dönüşe göre yatması.
const FEATURE_PLAYER_LEAN: bool = true
## Ses efektleri (5.5): ana anahtar + her ses için ayrı anahtar. Ses satırları scripts/data/sound_data.gd'de.
const FEATURE_SFX: bool = true
const FEATURE_SFX_SHOT: bool = true
## Zombiye isabet sesi: Taha'nın isteğiyle kapalı (her vuruşta rahatsız ediciydi); yerine sürü homurtusu.
const FEATURE_SFX_HIT: bool = false
## Askerin yakınındaki zombi sayısı arttıkça sıklaşan ve yükselen homurtu.
const FEATURE_SFX_HORDE_GROAN: bool = true
## Zombi ölüm sesi: Taha'nın isteğiyle kapalı.
const FEATURE_SFX_ZOMBIE_DEATH: bool = false
const FEATURE_SFX_FOOTSTEP: bool = true
const FEATURE_SFX_DASH: bool = true
const FEATURE_SFX_PLAYER_HURT: bool = true
const FEATURE_SFX_PICKUP: bool = true

# --- Arena ---
## Işık ve zemin ön ayarı (LightingData tablosundan).
const LIGHTING_PRESET: StringName = &"dusk"
const ARENA_SIZE: float = 60.0
const ARENA_WALL_HEIGHT: float = 1.2
const ARENA_WALL_THICKNESS: float = 1.0
const ARENA_GROUND_MARGIN: float = 30.0

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
const PLAYER_RADIUS: float = 0.4
const PLAYER_HEIGHT: float = 1.8
const PLAYER_HIT_IFRAMES: float = 0.5
const PLAYER_TURN_SHARPNESS: float = 14.0

# --- Dash ---
const DASH_SPEED: float = 15.0
const DASH_DURATION: float = 0.35
const DASH_COOLDOWN: float = 1.4
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
## Seviye için gereken XP: (seviye + bu)². 1→2: 16 kristal.
const XP_LEVEL_OFFSET: int = 3

# --- İstatistikler ve kartlar (satırlar StatData / CardData'da) ---
const CARD_OFFER_COUNT: int = 3
## Bir can yenileme puanı saniyede bu kadar can.
const HP_REGEN_PER_POINT: float = 0.25
## Dash bekleme süresi en çok bu yüzde kadar kısalır.
const DASH_COOLDOWN_CUT_CAP: float = 60.0
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
const CAMERA_PITCH_DEG: float = 55.0
const CAMERA_DISTANCE: float = 17.0
const CAMERA_FOV: float = 45.0
const CAMERA_FOLLOW_SHARPNESS: float = 8.0
## İleri bakış: kamera, askerin bu kadar saniye sonra olacağı yere doğru kayar.
const CAMERA_LOOK_AHEAD_TIME: float = 0.25
const CAMERA_LOOK_AHEAD_SHARPNESS: float = 3.0
## Sarsıntı: en çok kayma (m), gürültü hızı, sönme hızı (1/sn) ve asker vurulunca eklenen pay.
const CAMERA_SHAKE_MAX_OFFSET: float = 0.6
const CAMERA_SHAKE_FREQUENCY: float = 6.0
const CAMERA_SHAKE_DECAY: float = 2.2
const CAMERA_SHAKE_ON_PLAYER_HIT: float = 0.45

# --- Ses ---
## Aynı anda çalabilecek en çok ses (havuzdaki oynatıcı sayısı).
const SFX_POOL_SIZE: int = 32
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

# --- Uzay ızgarası ---
const GRID_CELL_SIZE: float = 1.5

# --- Geri bildirim ---
const HIT_FLASH_TIME: float = 0.08
const PLAYER_BLINK_RATE: float = 20.0

# --- Debug ---
const DEBUG_SPAWN_BATCH: int = 50
const DEBUG_PANEL_REFRESH: float = 0.25
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
