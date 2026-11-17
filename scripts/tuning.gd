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

# --- Arena ---
const ARENA_SIZE: float = 60.0
const ARENA_WALL_HEIGHT: float = 1.2
const ARENA_WALL_THICKNESS: float = 1.0
const ARENA_GROUND_MARGIN: float = 30.0

# --- Asker ---
const PLAYER_SPEED: float = 6.0
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
## Animasyonlar arası geçiş süresi (sn).
const PLAYER_ANIM_BLEND: float = 0.15
## Vurulma klibinin girip çıkma süresi (sn).
const PLAYER_ANIM_HIT_FADE: float = 0.06
## Asker ölünce "öldün" ekranından önce ölüm animasyonuna tanınan süre (sn); 0 = beklemeden duraklat.
const GAME_OVER_DELAY: float = 1.8
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
const DEBUG_WEAPONS: Array[StringName] = [&"pistol", &"shotgun"]
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
const BENCH_STEP_ENEMIES: int = 50
const BENCH_STEP_TIME: float = 3.0
const BENCH_MEASURE_TIME: float = 2.0
const BENCH_TARGET_FPS: float = 60.0
const BENCH_MAX_ENEMIES: int = 2000
const BENCH_FAIL_STEPS: int = 2
const BENCH_TURN_RATE: float = 0.6
