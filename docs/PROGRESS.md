# İlerleme

Her oturumun sonunda güncellenir. Yeni oturum buradan devam eder.

## Şu an

- **Aşama:** 1 — Çekirdek prototip: kod bitti, **kullanıcı oyun testi bekleniyor** ("30 sn çatışma gergin ve okunaklı mı?")
- **Sıradaki iş:** Kullanıcı onayı → Aşama 2 — Tur döngüsü. Aşama 2 başında sorulacak: silahlar askerin etrafında mı süzülsün, yalnız eldeki mi görünsün?
- **Bekleyen (kullanıcıdan):**
  - Aşama 1'i oynayıp yorum (hız, zombi sıklığı, silah gücü).
  - Blender'ı açıp 3D görünümde N → BlenderMCP → Connect to Claude (Aşama 0'ın son maddesi; Aşama 4'e kadar şart değil).
  - Linux deneme ortamı var mı (makine / WSL)?
  - Kod lisansı: MIT ve açık kaynak mı?

## Aşama durumu

| # | Aşama | Durum |
|---|---|---|
| 0 | Kurulum ve iskelet | Blender bağlantı doğrulaması dışında bitti |
| 1 | Çekirdek prototip | kod bitti, oyun testi bekleniyor |
| 2 | Tur döngüsü | — |
| 3 | Dash ve his | — |
| 4 | Asker | — |
| 5 | Zombiler | — |
| 6 | Arena, atmosfer, ses | — |
| 7 | Arayüz ve akış | — |
| 8 | Kalıcı ilerleme | — |
| 9 | İçerik ve denge | — |
| 10 | Yayın | — |

## Aşama 0 kontrol listesi

- [x] `claude mcp list`: `godot` ve `blender` Connected
- [x] Claude Blender'dan sahne bilgisini okuyabiliyor (2026-11-15: Blender 5.3.0, 3 nesne okundu; eklenti güncel değil, yukarıya bak)
- [x] Boş Godot projesi, Forward+, `godot --headless --path . --quit` hatasız
- [x] GUT 9.7.1 kurulu (Tower Climb'daki yerel kopyadan), örnek test geçiyor
- [x] Windows dışa aktarımı üretildi, `--headless --quit` ile açılıp kapandı
- [x] Linux dışa aktarımı üretildi (denenmedi; Linux ortamı yok)
- [x] `CLAUDE.md`, `docs/GAME_DESIGN.md`, `docs/PROGRESS.md`, `.gitignore`, `CREDITS.md`, ilk commit

## Aşama 1 kontrol listesi

- [x] Kapsül asker WASD/oklarla yürüyor (ivmelenme + sürtünme), arena duvarlarından çıkamıyor
- [x] Kutu zombiler kenardan, askerden ≥18 m uzakta doğuyor; doğma sıklığı zamanla artıyor
- [x] Zombiler üst üste binmeden askeri sarıyor (ızgaralı itişme; ekran görüntüsüyle doğrulandı)
- [x] Tabanca menzildeki en yakın zombiye kendisi ateş ediyor; mermiler havuzdan, kare başına doğru parçası çarpışması
- [x] Can, temas hasarı, vurulunca 0.5 sn dokunulmazlık (yanıp sönme), ölüm ekranı, R ile yeniden başlat
- [x] Sabit açılı (55°) yumuşak izleyen kamera, fizik enterpolasyonu açık
- [x] F3 debug paneli (FPS, zombi/üst sınır, mermi, draw call, profil); F4/F5/F6 debug tuşları; yalnız debug yapıda
- [x] Kalite profilleri (low/medium/high) tek tablodan; zombi üst sınırı koda gömülü değil
- [x] Sürü ölçümü yapıldı ve aşağıya yazıldı
- [ ] Kullanıcı: "30 sn çatışma gergin ve okunaklı" onayı

## Ölçümler

| Ölçüm | Sonuç | Ortam | Tarih |
|---|---|---|---|
| 60 FPS'te en çok zombi (kutu zombi, high profil, gölge + 4x MSAA, vsync kapalı) | **~1350** (1350: 66–68 FPS, 1400: 44–52 FPS; iki çalıştırma) | RTX 3050 Ti Laptop, i7-11800H, Vulkan Forward+ | 2026-11-15 |
| 300 zombide | ~850 FPS (1.2 ms/kare) | aynı | 2026-11-15 |

Profil üst sınırları buna göre: low 200, medium 350, high 600. İskeletli modellerle (Aşama 5) yeniden ölçülecek.

## Bilinen notlar / sonraya kalanlar

- Silah gücü düşük hissedilebilir (kalabalıkta hedef sürekli değiştiği için hasar dağılıyor). Denge Aşama 2'de.
- Hareketsiz duran asker ~30 sn'de ölüyor (17 öldürme). Hareket eden oyuncuyla gerginlik kullanıcı testinde ayarlanacak.
- Asker zombilerin arasından itilerek geçebiliyor (zombiler askeri iter değil, asker onları iter). Sıkışma istenirse Aşama 3'te dash ile birlikte ele alınır.

## Kullanıcı geri bildirimi (Aşama 0–1)

- 2026-11-15: "Pencere modunda bile küçük duruyor, oyun tam ekran olmalı." → Tam ekran açılış + F11/Alt+Enter, pencere 1600×900, `canvas_items` ölçekleme (HUD 1280×720 tasarımından ölçeklenir). Sabit: `Tuning.FEATURE_START_FULLSCREEN`. Ekran görüntüsüyle doğrulandı (1920×1080).
- Açık soru: asker/zombiler hâlâ küçük mü geliyor? Kamera yakınlığı `Tuning.CAMERA_DISTANCE` (şu an 24) ile ayarlanır.
- Blender: 2026-11-15 bağlandı, sahne bilgisi okunuyor (5.3.0). Eklenti protokolü 15, beklenen 16 → `uvx mcp-for-blender install-addon` ile güncellenebilir (Aşama 4'ten önce).

## Oturum günlüğü

### 2026-11-15 — Oturum 1
- Ortam kontrolü: Godot 4.7.2 (mono değil), git 2.56, Node 26.13, godot-mcp ve blender-mcp bağlı. Blender açık değildi.
- Aşama 0: `project.godot` (Forward+), GUT, duman testi, Windows + Linux export, belgeler, `.gitattributes` (LF). Commit `a8efcd7`.
- Aşama 1: saf kurallar (`SpatialGrid`, `Steering`, `CombatMath`, `Health`, `SpawnRules`) + 31 GUT testi; asker, veri odaklı `EnemyManager`, mermi havuzu, otomatik silah, arena, kamera, HUD, debug paneli, `--bench` ve `--capture` debug araçları. Ölçüm ~1350 zombi.
