# İlerleme

Her alt aşama bitince ve her oturumun sonunda güncellenir. Yeni oturum buradan devam eder.
Plan: `ROADMAP.md` · Kararlar: `DECISIONS.md` · Teknik yapı: `TECH.md`

## Şu an

- **Ana aşama:** 3 — Dikey dilim: asker
- **Alt aşama:** 3.1 — Asker modeli (konsept kararlaştı, **Taha'nın Tripo modeli bekleniyor**)
- **Sıradaki iş:** model gelince penceresiz Blender scriptiyle temizle, ortak iskelete bağla, Godot'da önizle.
- **Bekleyen (Taha'dan):**
  - 3.1: `docs/concept/soldier.md`'deki metinle Tripo'da asker modeli (A-poz, tek parça, silahsız, Tripo rig'i kullanılmadan), GLB olarak `assets/models/source/soldier/` altına.
  - Acil değil: kod lisansı (MIT?), Linux deneme ortamı.
- **Not:** Blender MCP eklentisi 2026-11-16'da güncellendi (`uvx mcp-for-blender install-addon`); Blender yeniden başlatılınca etkinleşir. Scriptler zaten penceresiz çalışıyor.

## Ana aşama durumu

| # | Aşama | Durum |
|---|---|---|
| 0 | Kurulum ve iskelet | ✔ bitti |
| 1 | Kutu prototip | ✔ bitti (his onayı 5.7'ye devredildi) |
| 2 | Model ve animasyon hattı | ✔ bitti (2026-11-16) |
| 3 | Dikey dilim: asker | sürüyor (3.1) |
| 4 | Dikey dilim: zombi | — |
| 5 | Dikey dilim: silah ve vuruş hissi | — |
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
- [ ] 3.1 Asker modeli
- [ ] 3.2 Hareket modeli
- [ ] 3.3 Asker animasyonları
- [ ] 3.4 Dash
- [ ] 3.5 Kamera

### 4 — Dikey dilim: zombi
- [ ] 4.1 Yürüyen zombi modeli
- [ ] 4.2 Zombi animasyonları
- [ ] 4.3 Durum makinesi ve saldırı
- [ ] 4.4 İtme ve sendeleme
- [ ] 4.5 Ölüm

### 5 — Dikey dilim: silah ve vuruş hissi
- [ ] 5.1 Süzülen silah yuvaları
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
- Zombiler (ve asker) ekranda küçük görünüyor; Taha 2026-11-16'da doğruladı (`Tuning.CAMERA_DISTANCE` = 24) → 3.5.

## Taha'nın geri bildirimi

- 2026-11-16: Aşama 1 hissi zayıf: vuruş hissi yok, hareket ve koşu cansız, zombiler tehditsiz; "animasyon ve modellerle düzelebilir". Belgeler eksik ve ilerleme rastgele hissettiriyor → ana plan yeniden yazıldı (`ROADMAP.md`).
- 2026-11-15: "Pencere modunda bile küçük duruyor, oyun tam ekran olmalı." → tam ekran açılış + F11/Alt+Enter (`Tuning.FEATURE_START_FULLSCREEN`).

## Oturum günlüğü

### 2026-11-16 — Oturum 2
- Ortam kontrolü temiz (Godot 4.7.2, git, Node, `godot` + `blender` MCP bağlı, headless hatasız).
- 2.5: zombiler animasyonlu mankenle çizildi, ölçüm ~500 zombi / 60 FPS; profil sınırları 150 / 250 / 350. Taha: koşu Sprint, dash Roll, uzaktan saldıran zombiler istendi (7.3).
- 2.1–2.4: Quaternius UAL 1 + 2 seçildi (CC0, repo public kararıyla uyumlu). `tools/blender/build_anim_library.py` (penceresiz Blender) → 25 kemikli iskelet, 25 klip, manken. Godot'da kemik eşlemeli içe aktarım, denetim scripti, `anim_preview` sahnesi.
- Plan modu: Taha ile sekiz karar alındı, ana plan yeniden yapılandırıldı (önce dikey dilim). `ROADMAP.md`, `DECISIONS.md`, `TECH.md` yazıldı; `PROGRESS.md`, `GAME_DESIGN.md`, `CLAUDE.md` güncellendi. Kod değişmedi.

### 2026-11-15 — Oturum 1
- Ortam kontrolü: Godot 4.7.2 (mono değil), git 2.56, Node 26.13, godot-mcp ve blender-mcp bağlı.
- Aşama 0: `project.godot` (Forward+), GUT, duman testi, Windows + Linux export, belgeler, `.gitattributes` (LF). Commit `a8efcd7`.
- Aşama 1: saf kurallar (`SpatialGrid`, `Steering`, `CombatMath`, `Health`, `SpawnRules`) + 31 GUT testi; asker, `EnemyManager`, mermi havuzu, otomatik silah, arena, kamera, HUD, debug paneli, `--bench` ve `--capture`. Ölçüm ~1350 zombi.
