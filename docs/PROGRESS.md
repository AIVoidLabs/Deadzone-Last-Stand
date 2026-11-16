# İlerleme

Her alt aşama bitince ve her oturumun sonunda güncellenir. Yeni oturum buradan devam eder.
Plan: `ROADMAP.md` · Kararlar: `DECISIONS.md` · Teknik yapı: `TECH.md`

## Şu an

- **Ana aşama:** 5 — Dikey dilim: silah ve vuruş hissi (Taha 2026-11-16'da iki kez "devam" dedi; Aşama 4 kapandı)
- **Alt aşama:** 5.1 kod bitti; **Taha'nın yorumu bekleniyor**
- **Sıradaki iş:** 5.2 — atış görseli (namlu parlaması, mermi izi, isabet kıvılcımı)
- **Bekleyen (Taha'dan):** süzülen silahlara bakmak (F7 ile silah ekle, en çok 6). Acil değil: kod lisansı (MIT?), Linux deneme ortamı.
- **Not:** Blender MCP eklentisi 2026-11-16'da güncellendi (`uvx mcp-for-blender install-addon`); Blender yeniden başlatılınca etkinleşir. Scriptler zaten penceresiz çalışıyor.

## Ana aşama durumu

| # | Aşama | Durum |
|---|---|---|
| 0 | Kurulum ve iskelet | ✔ bitti |
| 1 | Kutu prototip | ✔ bitti (his onayı 5.7'ye devredildi) |
| 2 | Model ve animasyon hattı | ✔ bitti (2026-11-16) |
| 3 | Dikey dilim: asker | ✔ bitti (2026-11-16) |
| 4 | Dikey dilim: zombi | ✔ bitti (2026-11-16) |
| 5 | Dikey dilim: silah ve vuruş hissi | sürüyor (5.1) |
| 6 | Tur döngüsü | — |
| 7 | Silah ve zombi çeşitliliği | — |
| 8 | Arena, atmosfer, ses | — |
| 9 | Arayüz ve akış | — |
| 10 | Kalıcı ilerleme | — |
| 11 | İçerik ve denge | — |
| 12 | Yayın | — |

## Alt aşama kontrol listesi

Bitiş ölçütleri `ROADMAP.md`'de. Biten kutunun yanına tarih ve commit yazılır.

### 2 — Model ve animasyon hattı
- [x] 2.1 Animasyon kütüphanesi seçimi — 2026-11-16. Quaternius UAL 1 + 2 Standard (CC0), 86 klip; klip eşlemesi ve eksikler `TECH.md`'de
- [x] 2.2 Ortak iskelet standardı — 2026-11-16. 25 kemik, Godot insansı profil eşlemesi, `check_anim_import.gd` temiz
- [x] 2.3 Deneme mankeni — 2026-11-16. Quaternius mankeni 2.5 bin üçgene indirildi (sıfırdan modellemek yerine; aynı işi görüyor), akış dört komutla yineleniyor (`TECH.md`)
- [x] 2.4 Animasyon aktarımı — 2026-11-16. 25 klip önizleme sahnesinde oynuyor; Taha baktı ve beğendi (koşu Sprint, dash Roll)
- [x] 2.5 Sürü performans ölçümü — 2026-11-16. Zombiler animasyonlu mankenle çiziliyor (`Tuning.FEATURE_ZOMBIE_MODEL`); 60 FPS tavanı ~500, seyreltmeye gerek kalmadı

### 3 — Dikey dilim: asker
- [x] 3.1 Asker modeli — 2026-11-16. Tripo modeli 6 bin üçgen, 25 kemik, 1.85 m; 25 klip önizlemede ve oyunda (bekleme / Sprint / ölüm) çalışıyor (`Tuning.FEATURE_PLAYER_MODEL`)
- [x] 3.2 Hareket modeli — kod bitti 2026-11-16 (`Locomotion` + 6 test, gövde yatması); Taha oynadı, onayladı
- [x] 3.3 Asker animasyonları — kod bitti 2026-11-16 (animasyon ağacı: bekleme↔Sprint, üst gövdede vurulma, ölüm); Taha oynadı. Ölüm animasyonu oynamıyordu (oyun anında duraklıyordu) → `Tuning.GAME_OVER_DELAY` ile düzeltildi
- [x] 3.4 Dash — kod bitti 2026-11-16 (`Dash` + 5 test, takla, dokunulmazlık, zombilerin içinden geçiş, toz izi, HUD çubuğu); Taha oynadı, onayladı. Toz izi "dandik" bulundu → efekt cilasında (5.2/5.3) yeniden yapılacak
- [x] 3.5 Kamera — kod bitti 2026-11-16 (uzaklık 24 → 17, ileri bakış, sarsıntı altyapısı; asker vurulunca sarsılır); Taha oynadı, onayladı

### 4 — Dikey dilim: zombi
- [x] 4.1 Yürüyen zombi modeli — 2026-11-16. `build_zombie.py`: 10 gövde çeşidi × 16 renk şeması (yarısı koyu ton) = 160 görünüm, ~600–700 üçgen, tek malzeme (şema örnek başına), boyda ±%8 fark. Taha tarzı ve renkleri beğendi, çeşitliliğin artmasını istedi (yapıldı)
- [x] 4.2 Zombi animasyonları — 2026-11-16. `ZombieClipData`: 3 yürüyüş, bekleme, saldırı, sendeleme, 3 ölüm, yerden doğma; eksikler koddan türetildi (`AnimDerive` + 6 test). Taha baktı, "devam" dedi
- [x] 4.3 Durum makinesi ve saldırı — kod bitti 2026-11-16 (`ZombieRules` + 7 test: doğma → kovalama → hazırlık → vuruş → toparlanma; hazırlıkta yön kilitli, kaçılabilir; `FEATURE_ZOMBIE_WINDUP_ATTACK` kapatılınca eski değince hasar). Taha yorum yapmadan "devam" dedi; hazırlıklı vuruş varsayılan kaldı
- [x] 4.4 İtme ve sendeleme — kod bitti 2026-11-16 (`Knockback` + 4 test; silah satırında `knockback`, zombi satırında `weight` ve `stagger_time`; sendeleme saldırı hazırlığını bozar). Taha "devam" dedi
- [x] 4.5 Ölüm — kod bitti 2026-11-16 (`CorpseList`: vuruş yönüne düşer ve kayar, 3 ölüm klibinden biri, noktalı solma, havuza dönüş). Taha "devam" dedi

### 5 — Dikey dilim: silah ve vuruş hissi
- [ ] 5.1 Süzülen silah yuvaları — kod bitti 2026-11-16 (`WeaponRig` + `WeaponSlots` 5 test; 6 yuva çemberde, askeri geriden izler, her silah kendi en yakın hedefine döner ve kendi namlusundan ateş eder, geri tepme + salınım; `build_weapons.py`: tabanca ve pompalı modelleri). Taha'nın yorumu bekleniyor
- [ ] 5.2 Atış görseli
- [ ] 5.3 Vuruş geri bildirimi
- [ ] 5.4 Asker vurulunca
- [ ] 5.5 İlk sesler
- [ ] 5.6 İkinci silah: pompalı
- [ ] 5.7 Dilim cilası ve **dikey dilim onayı**

### 6 — Tur döngüsü
- [ ] 6.1 Dalgalar
- [ ] 6.2 Düşenler
- [ ] 6.3 İstatistikler ve kartlar
- [ ] 6.4 Silah yuvaları ve birleştirme
- [ ] 6.5 Mağaza ve eşyalar
- [ ] 6.6 Tam tur

### 7 — Silah ve zombi çeşitliliği
- [ ] 7.1 Silah davranış seti
- [ ] 7.2 Koşan ve tank
- [ ] 7.3 Tüküren ve patlayan
- [ ] 7.4 Boss
- [ ] 7.5 Yeniden ölçüm

### 8 — Arena, atmosfer, ses
- [ ] 8.1 Şehir sokağı parçaları
- [ ] 8.2 Engeller ve kaçınma
- [ ] 8.3 Işık, sis, ekran efektleri
- [ ] 8.4 Tam ses seti
- [ ] 8.5 Müzik kararı

### 9 — Arayüz ve akış
- [ ] 9.1 Ana menü ve duraklatma
- [ ] 9.2 Ayarlar
- [ ] 9.3 HUD son hali
- [ ] 9.4 Mağaza ve kart ekranları son hali
- [ ] 9.5 Tur sonu özeti
- [ ] 9.6 Kayıt dosyası
- [ ] 9.7 Gamepad ve oyun dili

### 10 — Kalıcı ilerleme
- [ ] 10.1 Kalıcı para ve kayıt
- [ ] 10.2 Asker sınıfları
- [ ] 10.3 Başlangıç silahı açılımları
- [ ] 10.4 Kalıcı yükseltmeler

### 11 — İçerik ve denge
- [ ] 11.1 Silah ve eşya sayısı
- [ ] 11.2 Dalga sayısı ve zorluk eğrisi
- [ ] 11.3 Fiyatlar ve düşme oranları
- [ ] 11.4 Üç farklı kurulum

### 12 — Yayın
- [ ] 12.1 Windows ve Linux çıktıları
- [ ] 12.2 README, CREDITS, ekran görüntüleri
- [ ] 12.3 itch.io sayfası
- [ ] 12.4 Web denemesi

## Biten aşamalar (özet)

**0 — Kurulum ve iskelet** (commit `a8efcd7`): MCP sunucuları bağlı, Blender'dan sahne okundu (5.3.0), Forward+ proje, GUT 9.7.1, Windows + Linux dışa aktarımı (Linux denenmedi), belgeler.

**1 — Kutu prototip** (commit `2f778dc`, `1d031b9`): kapsül asker (ivme + sürtünme), kenardan doğan ve itişen kutu zombiler (veri odaklı `EnemyManager` + `SpatialGrid`), otomatik tabanca ve mermi havuzu, can / temas hasarı / dokunulmazlık / ölüm / R, 55° izleyen kamera, F3 paneli ve F4–F6 tuşları, kalite profilleri, `--bench` ve `--capture` araçları, 31 GUT testi, tam ekran açılış.

## Ölçümler

| Ölçüm | Sonuç | Ortam | Tarih |
|---|---|---|---|
| 60 FPS'te en çok zombi (kutu zombi, high profil, gölge + 4x MSAA, vsync kapalı) | **~1350** (1350: 66–68 FPS, 1400: 44–52 FPS; iki çalıştırma) | RTX 3050 Ti Laptop, i7-11800H, Vulkan Forward+ | 2026-11-15 |
| 300 zombide | ~850 FPS (1.2 ms/kare) | aynı | 2026-11-15 |
| **Animasyonlu manken** (2.5 bin üçgen, 25 kemik, zombi başına AnimationPlayer, seyreltme yok), high profil, vsync kapalı: 60 FPS'te en çok zombi | **~500** (500: 62.7 FPS, 550: 53.2 FPS) | aynı | 2026-11-16 |
| Animasyonlu manken: 150 / 300 / 450 zombide | 241 / 120 / 70 FPS (4.2 / 8.4 / 14.3 ms) | aynı | 2026-11-16 |

Profil üst sınırları (2.5 ölçümüne göre, efektlere pay bırakılarak): low 150, medium 250, high 350. Animasyon güncelleme seyreltmesi gerekmedi; ileride efektler bütçeyi zorlarsa eklenir. Karışık türlerle 7.5'te yeniden ölçülecek.

## Bilinen notlar / sonraya kalanlar

- Silah gücü düşük (kalabalıkta hedef sürekli değişiyor, hasar dağılıyor) → 5.x ve 6.6.
- Asker zombilerin arasından itilerek geçebiliyor → 3.4 (dash) ve 4.4 (itme) ile ele alınır.
- Renkler oyunda Blender'dakinden açık (lacivert zırh soluk mavi görünüyor): ışık pozlaması yüksek → 5.7 ışık ayarı.
- Dash toz izi kare parçacıklardan oluşuyor (yer tutucu) → 5.2/5.3 efekt işinde yumuşatılır.
- Zombiler (ve asker) ekranda küçük görünüyor; Taha 2026-11-16'da doğruladı (`Tuning.CAMERA_DISTANCE` = 24) → 3.5.

## Taha'nın geri bildirimi

- 2026-11-16: Aşama 1 hissi zayıf: vuruş hissi yok, hareket ve koşu cansız, zombiler tehditsiz; "animasyon ve modellerle düzelebilir". Belgeler eksik ve ilerleme rastgele hissettiriyor → ana plan yeniden yazıldı (`ROADMAP.md`).
- 2026-11-15: "Pencere modunda bile küçük duruyor, oyun tam ekran olmalı." → tam ekran açılış + F11/Alt+Enter (`Tuning.FEATURE_START_FULLSCREEN`).

## Oturum günlüğü

### 2026-11-16 — Oturum 2
- Aşama 4 kapandı; 5.1: süzülen silahlar (`WeaponRig`, `WeaponVisual`, `WeaponSlots`), silah modelleri Blender scriptinden, F7 debug silahı. Toplam 64 test.
- 4.3–4.5: `ZombieRules`, `Knockback`, `CorpseList`; zombi durumları, hazırlıklı saldırı, itme, sendeleme, ölüm animasyonu ve solma. Toplam 59 test. Not: itme yüzünden tabanca hedef değiştiriyor, hasar sürüye yayılıyor (denge 5.6 ve 6.6'da).
- Zombi türleri listesi (Taha + Codex önerisi) `GAME_DESIGN.md` ve 7.2–7.3'e işlendi. 4.2: `AnimDerive`, `ZombieClips`, `ZombieClipData`; toplam 48 test.
- 4.1 genişletildi: Taha çok daha fazla çeşit ve koyu tonlar istedi → rol tabanlı palet (`ZombieLook`), 160 görünüm. Yeni zombi türleri (sürünen, zıplayan) 7.2'ye eklendi.
- Aşama 3 kapandı (Taha onayladı; ölüm animasyonu `GAME_OVER_DELAY` ile düzeltildi). 4.1: `build_zombie.py` ile dört çeşitli low-poly zombi, `ModelVariants`, zombi galerisi sahnesi.
- 3.2–3.5: `Locomotion` ve `Dash` saf kuralları (11 yeni test, toplam 42), `PlayerAnimator` animasyon ağacı, gövde yatması, takla ile dash, toz izi, HUD dash çubuğu, kamera 17 m + ileri bakış + sarsıntı. Taha animasyon önizlemesini onayladı.
- 3.1: asker konsepti (stilize iri, ağır zırhlı, lacivert + turuncu); Tripo modeli `build_soldier.py` ile temizlendi ve iskelete bağlandı; `PlayerVisual` modeli ve animasyonu sürüyor; `inspect_model.py` eklendi.
- Ortam kontrolü temiz (Godot 4.7.2, git, Node, `godot` + `blender` MCP bağlı, headless hatasız).
- 2.5: zombiler animasyonlu mankenle çizildi, ölçüm ~500 zombi / 60 FPS; profil sınırları 150 / 250 / 350. Taha: koşu Sprint, dash Roll, uzaktan saldıran zombiler istendi (7.3).
- 2.1–2.4: Quaternius UAL 1 + 2 seçildi (CC0, repo public kararıyla uyumlu). `tools/blender/build_anim_library.py` (penceresiz Blender) → 25 kemikli iskelet, 25 klip, manken. Godot'da kemik eşlemeli içe aktarım, denetim scripti, `anim_preview` sahnesi.
- Plan modu: Taha ile sekiz karar alındı, ana plan yeniden yapılandırıldı (önce dikey dilim). `ROADMAP.md`, `DECISIONS.md`, `TECH.md` yazıldı; `PROGRESS.md`, `GAME_DESIGN.md`, `CLAUDE.md` güncellendi. Kod değişmedi.

### 2026-11-15 — Oturum 1
- Ortam kontrolü: Godot 4.7.2 (mono değil), git 2.56, Node 26.13, godot-mcp ve blender-mcp bağlı.
- Aşama 0: `project.godot` (Forward+), GUT, duman testi, Windows + Linux export, belgeler, `.gitattributes` (LF). Commit `a8efcd7`.
- Aşama 1: saf kurallar (`SpatialGrid`, `Steering`, `CombatMath`, `Health`, `SpawnRules`) + 31 GUT testi; asker, `EnemyManager`, mermi havuzu, otomatik silah, arena, kamera, HUD, debug paneli, `--bench` ve `--capture`. Ölçüm ~1350 zombi.
