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

Aşama 2.2'de yazılır: kemik adları, ölçek, yön, dinlenme pozu, Godot içe aktarım (kemik eşleme) ayarı.

## Model hattı

Script (`tools/blender/`) → pozu sıfırla → kaydet → `.glb` dışa aktar → `godot --headless --import`. Ham Tripo dosyası ve ham kütüphane indirmeleri git'e girmez. Ayrıntı Aşama 2.3–2.4'te yazılır.

## Ölçümler

Sürü ölçümleri `PROGRESS.md` ölçüm tablosunda.
