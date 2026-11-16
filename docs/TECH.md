# Deadzone Last Stand — Teknik Yapı

Teknoloji, kod yapısı, iskelet standardı, model bütçeleri ve model hattı. Mimari kuralların özü `CLAUDE.md` bölüm 3–4'te; burası ayrıntı ve Aşama 2'den itibaren büyüyen teknik kayıt.

**Araçlar:** Godot 4.7.2 Standard + GDScript (statik tipli), Forward+; GUT 9.7.x; Blender 5.3 + blender-mcp (her model işi `tools/blender/` altında yeniden çalıştırılabilir script); Tripo (Taha); CC0 animasyon kütüphanesi; sesler kodla sentez (`tools/sfx/`).

**Değişmeyen mimari kurallar** (`CLAUDE.md` bölüm 3): XZ düzlemi, fizik/görüntü ayrımı ve sinyaller, `Tuning` + veri tabloları, kalite profilleri, havuzlama, saf kurallar + GUT, `GameFlow` tek duraklatma noktası, her özellik tek sabitle kapanır.

**Yeni teknik kararlar:**

- **Tek ortak insansı iskelet.** Asker ve tüm insansı zombiler Godot'nun insansı kemik profiline (`SkeletonProfileHumanoid`) eşlenir; kütüphane animasyonları içe aktarımda bu profile aktarılır ve paylaşılan `AnimationLibrary` kaynakları olarak saklanır. Bir animasyon bir kez hazırlanır, her karakterde çalışır.
- **Asker:** `AnimationTree` (bekleme/koşu harmanı, dash, vurulma katmanı, ölüm). Koşu animasyonunun hızı gerçek hıza bağlanır (ayak kayması olmaz).
- **Zombiler:** zombi başına hafif `AnimationPlayer` (ağaç değil), paylaşılan kütüphane, faz ve hız çeşitlemesi; uzaktaki ve ekran dışındaki zombilerde animasyon güncelleme seyreltmesi kalite profilinden.
- **Zamanlama veride, animasyonda değil.** Saldırı hazırlık süresi, sendeleme süresi gibi oynanış süreleri veri tablosunda durur; animasyon bunlara uyar. Böylece kurallar sahnesiz test edilir.
- **Model bütçeleri (başlangıç hedefi, Aşama 2 ölçümüyle kesinleşir):** zombi ~1.5–2.5 bin üçgen, asker ~3–5 bin, boss ~6–8 bin; en çok ~25–30 kemik; karakter başına tek malzeme + palet dokusu.

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

**Eksikler:** ikinci ve üçüncü zombi yürüyüşü, yönlü ölümler (2–3 çeşit), zombi koşusu. Standard sürümde 8 yönlü hareket yok; asker hareket yönüne baktığı için gerekmiyor. Eksikler Aşama 4.2'de mevcut kliplerden türetilerek Blender'da üretilir (ya da karar verilirse ücretli Pro sürümden alınır).

## Model hattı

Ham Tripo dosyası ve ham kütüphane indirmeleri `assets/models/source/` altında durur; bu klasör git'e girmez ve içindeki `.gdignore` sayesinde Godot da taramaz. Blender **penceresiz** çalışır; Blender'ı elle açmak ya da bağlamak gerekmez.

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

## Ölçümler

Sürü ölçümleri `PROGRESS.md` ölçüm tablosunda.
