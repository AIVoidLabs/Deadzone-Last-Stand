# Deadzone Last Stand — Teknik Yapı

Teknoloji, kod yapısı, iskelet standardı, model bütçeleri ve model hattı. Mimari kuralların özü `CLAUDE.md` bölüm 3–4'te; burası ayrıntı ve Aşama 2'den itibaren büyüyen teknik kayıt.

**Araçlar:** Godot 4.7.2 Standard + GDScript (statik tipli), Forward+; GUT 9.7.x; Blender 5.3 + aktif blender-mcp iş akışı (canlı modelleme, görünüş inceleme ve cila) + `tools/blender/` altında yeniden çalıştırılabilir üretim scriptleri; `.claude/skills/` içindeki işe uygun Blender skill'leri; Tripo (yalnız asker); CC0 animasyon kütüphanesi; sesler kodla sentez (`tools/sfx/`).

### Blender üretim döngüsü

Blender, Deadzone'un görsel üretiminde etkin çalışma aracıdır; Blender MCP yalnızca sonradan bakılan bir önizleme değildir. Blender işine başlarken MCP bağlantısını kontrol et. Bağlantı yoksa Taha'dan Blender'da BlenderMCP eklentisini açıp bağlanmasını iste; bağlantı kurulana dek Blender gerektiren üretimi sürdürme. İlgili `.claude/skills/` yönergelerini kalite, modelleme, malzeme, ışık, export ve QA için uygula.

Görsel keşfi ve yinelemeyi Blender MCP ile yap; viewport görüntülerini al, gerçek görünüşü değerlendir ve geri bildirime göre düzelt. Onaylanan görünüşün tamamını `tools/blender/<asset>.py` içinde tekrar çalıştırılabilir biçimde kodla. Son scripti Blender MCP üzerinden çalıştırıp sahneyi yeniden oluştur; böylece elle yapılan düzeltme script dışında kaybolmaz. Ardından GLB'yi Godot'a aktar, iskelet/animasyon ve oyun içi görünüşü doğrula. Kabul ölçütleri hem teknik sınırları hem okunaklı, tutarlı ve cilalı oyun görünüşünü kapsar.

**Değişmeyen mimari kurallar** (`CLAUDE.md` bölüm 3): XZ düzlemi, fizik/görüntü ayrımı ve sinyaller, `Tuning` + veri tabloları, kalite profilleri, havuzlama, saf kurallar + GUT, `GameFlow` tek duraklatma noktası, her özellik tek sabitle kapanır.

**Yeni teknik kararlar:**

- **Tek ortak insansı iskelet.** Asker ve tüm insansı zombiler Godot'nun insansı kemik profiline (`SkeletonProfileHumanoid`) eşlenir; kütüphane animasyonları içe aktarımda bu profile aktarılır ve paylaşılan `AnimationLibrary` kaynakları olarak saklanır. Bir animasyon bir kez hazırlanır, her karakterde çalışır.
- **Asker:** `AnimationTree` (bekleme/koşu harmanı, dash, vurulma katmanı, ölüm). Koşu animasyonunun hızı gerçek hıza bağlanır (ayak kayması olmaz).
- **Zombiler:** zombi başına hafif `AnimationPlayer` (ağaç değil), paylaşılan kütüphane, faz ve hız çeşitlemesi; uzaktaki ve ekran dışındaki zombilerde animasyon güncelleme seyreltmesi kalite profilinden.
- **Zamanlama veride, animasyonda değil.** Saldırı hazırlık süresi, sendeleme süresi gibi oynanış süreleri veri tablosunda durur; animasyon bunlara uyar. Böylece kurallar sahnesiz test edilir.
- **Model bütçeleri (2026-11-19 kararı, sürü ölçüm aracıyla yeniden ölçülüp kesinleşir):** sıradan zombi 3–5 bin üçgen, özel zombi 8–15 bin, asker ~6 bin, boss ~20 bin; uzaklık için LOD; en çok ~25–30 kemik (dil zinciri gibi imza kemikler ayrı sayılır, ölçümle belirlenir); dokulu malzeme (stilize-gerçekçi). Eski "karakter başına tek malzeme + palet dokusu" kuralı kalktı.

**Yeniden kullanılacak mevcut kod:**

| Dosya | Nasıl büyür |
|---|---|
| `scripts/enemies/enemy_manager.gd` | Paralel dizilere `_vel` (itme), `_state`, `_state_time`, `_kind` eklenir; durum makinesi (doğma, kovalama, saldırı, sendeleme, ölme) aynı tek döngüde |
| `scripts/enemies/zombie.gd`, `zombie_visual.gd` | Sinyal sözleşmesi aynı kalır; `ZombieVisual` kutu yerine iskeletli modeli ve animasyonu sürer |
| `scripts/player/player.gd`, `player_visual.gd` | `State`'e `DASH`, `HURT` eklenir; `PlayerVisual` modeli ve `AnimationTree`'yi sürer |
| `scripts/game/spatial_grid.gd` | Patlama için daire sorgusu eklenir |
| `scripts/game/combat_math.gd`, `health.gd`, `steering.gd` | İtme, alan hasarı, engel kaçınma kuralları için genişler |
| `scripts/game/spawn_rules.gd` | Dalga tablosundan okuyan `WaveRules` ile değişir |
| `scripts/weapons/weapon.gd`, `projectile_pool.gd` | Silah, askerin çocuğu yerine süzülen bir yuvaya bağlanır; davranışlar veri satırından |
| `scripts/autoload/game_flow.gd` | Durumlar: oynanış, kart seçimi, mağaza, duraklatma, yenilgi, zafer; hit-stop da buradan |
| `scripts/autoload/quality.gd`, `scripts/data/quality_profiles.gd` | Animasyon seyreltme, parçacık ve leke sınırları eklenir |
| `scripts/debug/benchmark.gd`, `capture.gd` | Ölçüm animasyonlu zombilerle yinelenir; ekran görüntüsü doğrulaması sürer |

**Yeni parçalar:** `scripts/fx/fx_manager.gd` (havuzlu parçacık, leke, hasar sayısı), `scripts/fx/camera_shake.gd`, `scripts/autoload/audio.gd` (ses havuzu), `scripts/weapons/weapon_mount.gd` (süzülen yuva), saf kurallar `scripts/game/` altında: `knockback.gd`, `run_stats.gd`, `wave_rules.gd`, `drop_rules.gd`, `card_rules.gd`, `shop_rules.gd`, `merge_rules.gd`.


## İskelet standardı

Kaynak: Quaternius Universal Animation Library iskeleti (65 kemik, Unreal mankeni adlandırması). Aşama 2.2'de (2026-11-16) kuruldu ve doğrulandı.

- **Ölçü ve yön:** 1 birim = 1 metre; manken 1.83 m (asker kapsülü 1.8 m ile uyumlu); Y yukarı, karakter +Z'ye bakar; dinlenme pozu A-poz.
- **Godot tarafı:** içe aktarımda kemikler Godot insansı profiline yeniden adlandırılır ve iskelet düğümü sahne içinde benzersiz `%GeneralSkeleton` olur. Animasyon izleri `%GeneralSkeleton:<kemik>` yolunu kullandığı için aynı klip, bu kurala uyan her karakterde çalışır.
- **Eşleme** (`assets/models/humanoid_bone_map.tres`, üreten: `tools/godot/make_bone_map.gd`):

| Blender (UAL) | Godot | Blender (UAL) | Godot |
|---|---|---|---|
| `root` | `Root` | `clavicle_l/r` | `Left/RightShoulder` |
| `pelvis` | `Hips` | `upperarm_l/r` | `Left/RightUpperArm` |
| `spine_01` | `Spine` | `lowerarm_l/r` | `Left/RightLowerArm` |
| `spine_02` | `Chest` | `hand_l/r` | `Left/RightHand` |
| `spine_03` | `UpperChest` | `thigh_l/r` | `Left/RightUpperLeg` |
| `neck_01` | `Neck` | `calf_l/r` | `Left/RightLowerLeg` |
| `Head` | `Head` | `foot_l/r` | `Left/RightFoot` |
| `ball_leaf_l/r` | (eşlenmez, adı kalır) | `ball_l/r` | `Left/RightToes` |

- **Yeni karakter kuralı:** Blender'da bu 25 kemiğe, aynı adlarla ve A-pozda bağlanır; `.glb.import` dosyasında `_subresources` altına aynı kemik eşlemesi yazılır (örnek: `assets/models/characters/mannequin.glb.import`).
- **Klip adları:** Godot içe aktarımda `_Loop` ekini atar ve klibi döngü olarak işaretler (`Idle_Loop` → `Idle`). Kodda kütüphane adıyla çağrılır: `ual1/Idle`, `ual2/Zombie_Walk_Fwd`.

- **Oyun iskeleti (25 kemik):** `root, pelvis, spine_01, spine_02, spine_03, neck_01, Head` + her kol için `clavicle, upperarm, lowerarm, hand` + her bacak için `thigh, calf, foot, ball, ball_leaf` (`_l` / `_r`).
- **Atılanlar:** 40 parmak kemiği (el başına 20). Parmak ağırlıkları `hand` kemiğine aktarılır.

## Asker animasyon ağacı (Aşama 3.3)

`scripts/player/player_animator.gd` ağacı kodla kurar: bekleme↔koşu harmanı → koşu hızı → vurulma (yalnız üst gövde kemikleri; bacaklar koşmayı sürdürür) → takla → hayatta/ölü geçişi. `PlayerVisual` yalnız dört çağrı yapar: `set_locomotion`, `play_hit`, `play_roll`, `set_dead`.

Öğrenilenler:
- `AnimationTree` kütüphaneyi kendisi taşır (`add_animation_library`); ayrı `AnimationPlayer` bağlamak kodla kurulumda kütüphaneyi boş bıraktı.
- `AnimationNodeTransition` kendiliğinden bir girişle başlamaz; ilk durum açıkça istenmezse ağaç poz üretmez ve model T-pozda kalır.
- Koşu klibinin hızı gerçek hıza oranlanır (`Tuning.PLAYER_RUN_ANIM_SPEED`); ayak kayarsa bu sayı ayarlanır.

## Animasyon kütüphanesi (Aşama 2.1, 2026-11-16)

Ücretsiz Standard sürümlerde toplam 86 klip (her pakette 43). Dosyalar `_RM` (kök hareketli) ve kök hareketsiz olarak gelir; oyun hareketi kodla yürüttüğü için **kök hareketsiz** olan kullanılır.

| İhtiyaç | Klip | Paket |
|---|---|---|
| Asker bekleme / yürüme / koşu / sprint | `Idle_Loop`, `Walk_Loop`, `Jog_Fwd_Loop`, `Sprint_Loop` | 1 |
| Asker dash adayları | `Roll`, `Slide_Start/Loop/Exit`, `Shield_Dash` | 1, 2 |
| Vurulma | `Hit_Chest`, `Hit_Head`, `Hit_Knockback` | 1, 2 |
| Ölüm | `Death01` (tek çeşit) | 1 |
| Zombi bekleme / yürüyüş | `Zombie_Idle_Loop`, `Zombie_Walk_Fwd_Loop` (tek çeşit) | 2 |
| Zombi saldırısı | `Zombie_Scratch`, `Melee_Hook`, `Punch_Cross`, `Punch_Jab` | 1, 2 |
| Yerden doğma | `LayToIdle` | 2 |
| Sürünen / koşan zombi adayı | `Crouch_Fwd_Loop`, `Sprint_Loop` | 1 |
| Tüküren / fırlatan adayı | `OverhandThrow` | 2 |

**Eksikler:** ikinci ve üçüncü zombi yürüyüşü, yönlü ölümler (2–3 çeşit), zombi koşusu, sürünme. Standard sürümde 8 yönlü hareket yok; asker hareket yönüne baktığı için gerekmiyor.

**Zombi durumları (4.3–4.5):** geçiş kuralları saf sınıfta (`scripts/game/zombie_rules.gd`), süreler ve menziller `EnemyData` satırında; `EnemyManager` durumu ve kalan süreyi paralel dizilerde tutar, `Zombie.enter_state(durum, süre)` ile görüntüye haber verir. Görüntü klibi süreye uydurur (`_play_timed`: saldırı klibindeki vuruş anı hazırlığın sonuna denk gelir). Ölen zombi oyun dizilerinden hemen çıkar; düğümü `CorpseList` ölüm animasyonu ve solma bitene kadar tutar, sonra havuza verir. Solma saydamlıkla değil, shader'da noktalı elemeyle yapılır (malzeme opak kalır, sıralama derdi olmaz).

**Süzülen silahlar (5.1):** `WeaponRig` (dünya uzayında, askerin çocuğu değil) silahları `WeaponSlots.offset` ile çembere dizer ve askere sabit tutar (gecikmeli izleme denendi, koşu yönüne göre silah geride kalıyor ya da gövdeye giriyordu); enerji çemberi `EnergyRing` (tek düzlem + `energy_ring.gdshader`, toplamalı karışım); sonra her silahın `tick`'ini çağırır (fizik sırası: düşmanlar -10, asker 0, silahlar 5, mermiler 10). `Weapon` mantığı kendi konumuna en yakın zombiyi seçer, `aim` yönünü tutar, namlu ağzından (`muzzle_offset`) ateş eder; `WeaponVisual` yalnız `aim`'i okur ve `fired` sinyalini dinler. Modeller `tools/blender/build_weapons.py` → `assets/models/weapons/weapons.glb` (gerçek boyut, namlu Godot'da +Z, köken ortada); oyundaki boyut veri satırındaki `model_scale`.

**Türetme (4.2):** eksik klipler Blender'da değil, oyun açılırken koddan türetilir. `scripts/data/zombie_clip_data.gd` tablosundaki her satır bir kaynak klip + isteğe bağlı `mirror` (sağ-sol ayna), `offsets` (kemik başına model uzayında ek dönüş, derece) ve `reverse` (ters oynatma) içerir; `ZombieClips.library()` bunlardan paylaşılan "zombie" kütüphanesini bir kez üretir. Hesaplar saf sınıfta (`scripts/game/anim_derive.gd`, testli). Yeni yürüyüş ya da ölüm çeşidi = tabloya bir satır. Klip setini görmek için: `godot --path . res://scenes/debug/zombie_gallery.tscn -- --clips`. Kütüphanede ayrıca koşu (`Sprint`), zıplama (`Jump_*`, `NinjaJump_*`) ve fırlatma (`OverhandThrow`) klipleri var; Aşama 7 türleri bunlardan türetilecek.

## Model hattı

Ham Tripo dosyası ve ham kütüphane indirmeleri `assets/models/source/` altında durur; bu klasör git'e girmez ve içindeki `.gdignore` sayesinde Godot da taramaz. Blender + MCP etkileşimli hattın parçasıdır (2026-11-19): her Blender işinde önce `blender` MCP bağlantısı kontrol edilir; bağlı değilse Taha'dan Blender'ı açıp N → BlenderMCP → Connect to Claude yapması istenir. MCP görsel keşif ve cila içindir; son görünüm `tools/blender/` altında yeniden çalıştırılabilir script olarak saklanır ve doğrulama o scriptle yapılır. Aşağıdaki penceresiz komutlar (`blender --background`) yeniden üretim ve eski modeller için hâlâ geçerlidir.

Baştan üretim (repo kökünden, PowerShell):

```
blender --background --python tools/blender/build_anim_library.py
godot --headless --path . --import
godot --headless --path . -s res://tools/godot/check_anim_import.gd
godot --path . res://scenes/debug/anim_preview.tscn
```

| Adım | Ne yapar |
|---|---|
| `build_anim_library.py` | Ham paketleri açar, parmak kemiklerini atıp ağırlıklarını ele aktarır, mankeni ~2.5 bin üçgene indirir, seçilen klipleri yazar → `assets/models/anim/ual1.glb`, `ual2.glb`, `assets/models/characters/mannequin.glb`. Klip listesi scriptin başındaki `PACKS` tablosunda; yeni klip = listeye bir ad |
| `--import` | `.glb` dosyalarını içe aktarır (`anim/` altındakiler animasyon kütüphanesi, `characters/` altındakiler sahne olarak) |
| `check_anim_import.gd` | Kemik adları ve iz yolları standarda uyuyor mu denetler; `SONUC: tamam` ve çıkış kodu 0 beklenir |
| `anim_preview.tscn` | Her klibi bir mankende yan yana oynatır (Esc ile çıkış); `-- --capture=build/shots/anim.png` ile ekran görüntüsü alır |

`make_bone_map.gd` yalnız eşleme değişirse yeniden çalıştırılır.

### Asker (Aşama 3.1)

```
blender --background --python tools/blender/build_soldier.py
godot --headless --path . --import
godot --path . res://scenes/debug/anim_preview.tscn -- --model=soldier
```

`build_soldier.py` ham Tripo modelini (355 bin üçgen, 2048 doku) alır: 1.83 m'ye ölçekler, ~6 bin üçgene indirir, yalnız renk dokusunu bırakır, iskeleti scriptin başındaki eklem tablosuna (`CENTER_JOINTS`, `SIDE_JOINTS`) göre oturtur, otomatik ağırlık verir ve modeli kütüphanenin dinlenme pozuna (T-poz) getirir. Kontrol görüntüleri: `build/shots/soldier_fit_joints_*.png` (eklemler), `soldier_fit_rest_*.png` (son poz). Blender'da bakmak için: `build/blender/soldier.blend`.

Öğrenilenler:
- **Dinlenme pozu T-poz.** Kütüphanenin iskeleti T-pozda durur; yeni karakter hangi pozda gelirse gelsin script kolları ve bacakları kütüphanenin yönlerine çevirip bunu yeni dinlenme pozu yapar. Bu yapılmazsa animasyonlarda uzuvlar kayık durur.
- **Dokuya Blender'da dokunma.** Görüntüyü Blender'da ölçekleyince Godot'nun çözemediği bir JPEG çıktı (doku boş, model beyaz; hata yalnız `--import` çıktısında görünür), PNG'ye çevirince de renkler soldu. Çözüm: ham doku olduğu gibi geçer, boyutu Godot sınırlar (`soldier_albedo.jpg.import` içinde `process/size_limit=1024`).
- **Herhangi bir modeli ölçmek ve görmek için:** `blender --background --python tools/blender/inspect_model.py -- <model> build/shots/<ad>` (önden, yandan, arkadan görüntü + ölçüler).
- **Zombi (4.1):** **`build_zombie.py` eski (legacy) hattır; yeni hat zombileri tamamen Blender'da Claude'un scriptleriyle üretir: ortak yardımcılar `tools/blender/zombie_kit.py`, her tür için ayrı `build_<tür>.py` (ilki `build_dilci.py`), Blender MCP ile çalıştırılır; animasyonlar elle anahtarlanmış scriptlerdir; Tripo yalnız askerde (DECISIONS 2026-11-19, K2 zombiler için değişti, K3); yenisi gelene kadar repoda kalır.** `blender --background --python tools/blender/build_zombie.py` → `assets/models/characters/zombie_walker.glb` (`-- runner`, `-- tank`, `-- all` ile koşucu, tank; takım başına kendi palet ve şemaları `SETS`'te; yeni takım `.glb` ilk içe aktarımda `.import`'a kemik eşlemesi eklenir, yoksa animasyonlar T-pose kalır). Model elle çizilmez: gövde, kemik hizalarına dizilen halkalardan (loft) kurulur, ağırlık halka başına verilir. Yüzler renk değil rol taşır (ten, üst, alt, ayakkabı, saç, göz, kan …); palet dokusunda sütun = rol, satır = renk şeması. Oyunda tek malzeme paylaşılır, şema örnek başına `palette_offset` ile seçilir (`ZombieLook`); UV yüz içinde sabit olduğu için mipmap renk karıştırmaz, hücreler 4 piksel olduğu için doku sıkıştırması da bozmaz. Gövde çeşitleri (`VARIANTS`) aynı dosyada ayrı ağlardır; `ModelVariants.keep` birini bırakır. Yeni gövde ya da renk = tabloya bir satır. Yeni `.glb` ilk içe aktarımdan sonra `.import` dosyasına kemik eşlemesi (`_subresources`) eklenip yeniden içe aktarılır. Özel saldırılar (`attack_kind`: lunge, jump, tongue) `EnemyData` satırından seçilir ve `SpecialAttacks`'te işlenir; kurallar saf: `LungeRules`, `JumpRules`. Görüntüye yalnız zombi düğümünün `event` sinyaliyle haber verilir (`marker`, `tongue`). Yeni zombi türü `jumper`/`tongue` modelleri `-- jumper|tongue|all`. Galeri: `godot --path . res://scenes/debug/zombie_gallery.tscn [-- --kind=runner|tank|jumper|tongue] [--lineup] [--clips] [--capture=build/shots/zombies.png]` (`--lineup`: üç tür gerçek boylarıyla yan yana). Tür başına ayrı havuz (`EnemyManager._pools`): `Zombie.kind` modeli sabitler; yeni tür = `EnemyData` satırı + `ZombieVisual.MODELS` satırı.

## Ölçümler

Sürü ölçümleri `PROGRESS.md` ölçüm tablosunda.
