# Deadzone Last Stand — Claude Code Talimatları

3D stilize, dalga tabanlı hayatta kalma oyunu. Zırhlı ve kasklı bir asker, kapalı bir şehir arenasında zombi sürülerine karşı otomatik ateş eden silahlarla ve dash ile ayakta kalmaya çalışır. Brotato'nun tur yapısı (dalga + mağaza + silah yuvaları), Vampire Survivors'ın sürü hissi; kendi adı, karakterleri ve görselleriyle özgün bir oyun.

- **Motor:** Godot 4.7.2 (Standard sürüm, .NET DEĞİL) — **Dil:** GDScript
- **Renderer:** Forward+
- **Hedef:** masaüstü (Windows + Linux). Web en sonda denenir ve hiçbir kararı sınırlamaz (bölüm 1, kural 6).
- **Yol haritası:** `docs/ROADMAP.md` (ana ve alt aşamalar, bitiş ölçütleri; yalnız kararla değişir)
- **Durum:** `docs/PROGRESS.md` (güncel alt aşama, kontrol listesi, ölçümler, oturum günlüğü)
- **Kararlar:** `docs/DECISIONS.md` (tarihli kararlar + açık kararlar)
- **Teknik yapı:** `docs/TECH.md` (teknoloji, iskelet standardı, model bütçeleri, model hattı)
- **Tasarım:** `docs/GAME_DESIGN.md` (mekanikler ve başlangıç ayar değerleri)
- Eski yol haritası sayfası (2026-11-15, artık güncel değil): https://claude.ai/artifact/7sYmrAtEEhywsxCcwPpkjy

Kullanıcıyla Türkçe konuş.

---

## 0. Ortam kontrolü — her oturumun başında, kod yazmadan önce

Sırayla kontrol et ve sonucu tablo olarak raporla (araç | sürüm | durum):

1. `godot --version` → 4.x olmalı, çıktıda `mono` geçmemeli.
2. `git --version` çalışmalı; klasör bir git reposu olmalı.
3. `node --version` çalışmalı (godot-mcp için).
4. `claude mcp list` içinde `godot` görünmeli. Yoksa uyar ama durma; `godot` CLI ile devam edilebilir.
5. Proje varsa: `godot --headless --path . --quit` hatasız bitmeli.

1, 2 veya 5 başarısızsa **kod yazma**: eksik olanı ve nasıl kurulacağını söyle, dur.
Aşamaya özel ön koşullar (Blender, blender-mcp, Tripo, indirilecek dosyalar) `docs/ROADMAP.md`'deki "Taha" sütununda; onları yalnız o alt aşamaya gelince kontrol et.

Ardından `docs/PROGRESS.md`'yi ve `docs/ROADMAP.md`'de güncel alt aşamanın satırını oku; kullanıcıya tek cümleyle hangi alt aşamada olduğumuzu ve sıradaki işi söyle.

### MCP sunucuları (klasöre özel kaydedilir; bu klasörde bir kez eklenir)

```
claude mcp add godot -e GODOT_PATH="C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" -- cmd /c npx @coding-solo/godot-mcp
claude mcp add blender -- uvx blender-mcp
```

Blender tarafı: Blender açık olmalı, 3D görünümde N → BlenderMCP sekmesi → Connect to Claude (Blender her açıldığında yeniden). Yol başka makinede farklı olabilir; `GODOT_PATH`'i o makinedeki konsol exe'sine göre ver.

---

## 1. Altın kurallar

1. **Asla kendiliğinden bir sonraki aşamaya geçme.** Aşama bitince bölüm 2'deki bildirimi yap ve kullanıcının "devam" demesini bekle.
2. **Tek seferde tek özellik.** Bitir → çalıştır/doğrula (GUT + ekran görüntüsü) → commit → `PROGRESS.md` güncelle → kullanıcıya nasıl test edeceğini söyle.
3. **Ön koşulu kurulmamış bir araca ihtiyaç duyarsan dur ve bildir**, etrafından dolanma.
4. **Ücretli servis kullanma, hesap açma, internetten asset indirme.** Bunları kullanıcıya bırak, ne gerektiğini söyle.
5. Görsel bir şey değiştirdiğinde ekran görüntüsü al ya da iste; göremediğin şeyi "güzel oldu" diye raporlama. Sesleri duyamazsın; sesleri kullanıcı dinleyip onaylar.
6. **Web hiçbir kararı sınırlamaz.** Web gerekçesiyle özellik, efekt ya da zombi sayısı kısma. Platforma bağlı her değer kalite profilinden okunur (bölüm 3).
7. **Her yeni özellik tek sabitle kapatılabilir olmalı.** Kullanıcı beğenmezse anında çıkarılabilmeli.
8. Onay almadan kod yazma. Birden çok görsel seçenek varsa önce galeri görseliyle göster. Sessizce karar verme; kısa gerekçe ver.
9. **Görsel kalite önceliklidir.** Model, malzeme, ışık, efekt veya arena işi yaparken ilgili Blender skill'lerini kullan, Blender'ı blender-mcp ile aktif olarak açıp düzenle ve viewport görüntüsüyle yinele. Sonuç yalnız teknik olarak çalışan değil, Deadzone'un görsel diline uyan ve oyunda okunaklı olmalı. Tek seferde bir görsel yön göster; Taha'nın geri bildirimiyle cilala. Görsel iş 'çalışıyor' ile bitmez: konsept → model → animasyon önizlemesi → Taha onayı → oynanış. İmza hareketler koddan sabit açı eklenerek türetilmez; Blender'da elle anahtarlanır.
10. İyi tanımlanmış işler model açıkça belirtilerek Sonnet alt ajanlara verilebilir; tasarım kararı ve doğrulama ana döngüde.

---

## 2. Aşamalar ve geçiş kuralı

Tam plan `docs/ROADMAP.md`'de: her ana aşama alt aşamalara (2.1, 2.2 …) bölünür, her alt aşamanın bitiş ölçütü ve kullanıcının işi orada yazılıdır. Sıra ilkesi: **önce dikey dilim** (Aşama 2–5), sistemler ve içerik sonra.

| # | Ana aşama | Özet |
|---|---|---|
| 0 | Kurulum ve iskelet | ✔ bitti |
| 1 | Kutu prototip | ✔ bitti |
| 2 | Model ve animasyon hattı | Animasyon kütüphanesi, ortak iskelet, deneme mankeni, animasyonlu sürü ölçümü |
| 3 | Dikey dilim: asker | Tripo modeli, hareket modeli, animasyonlar, dash, kamera |
| 4 | Dikey dilim: zombi | Blender zombisi, animasyonlar, durum makinesi ve saldırı, itme ve sendeleme, ölüm |
| 5 | Dikey dilim: silah ve vuruş hissi | Süzülen silahlar, atış görseli, vuruş geri bildirimi, ilk sesler, pompalı, **dikey dilim onayı** |
| 6 | Tur döngüsü | Dalgalar, düşenler, istatistik ve kartlar, yuvalar ve birleştirme, mağaza, tam tur |
| 7 | Silah ve zombi çeşitliliği (7.3+ dondu) | Silah davranış seti, koşan, tank, tüküren, patlayan, boss |
| V | Görsel yeniden yön | Kurtulma hatası, önizleme aracı, üslup + deneme modeli, dilci dilimi, türlere yayılma, asker cilası |
| 8 | Arena, atmosfer, ses | Şehir sokağı, engeller, ışık ve sis, tam ses seti, müzik |
| 9 | Arayüz ve akış | Menü, duraklatma, ayarlar, HUD, son ekranlar, kayıt |
| 10 | Kalıcı ilerleme | Kalıcı para, asker sınıfları, açılımlar, yükseltmeler |
| 11 | İçerik ve denge | Sayılar hedefe, zorluk eğrisi, üç farklı kurulum |
| 12 | Yayın | Windows + Linux, itch.io, en son web denemesi |

**Alt aşama bitince:** doğrula (GUT + ekran görüntüsü) → commit → `PROGRESS.md`'de kutuyu işaretle (tarih + commit) ve "Şu an" bölümünü güncelle → kullanıcıya nasıl test edeceğini söyle. Kullanıcının testi ya da işi gereken alt aşamada onu bekle; gerekmiyorsa aynı ana aşama içinde sıradaki alt aşamaya geç.

**Ana aşama bitince:** aşağıdaki bildirimi yap ve "devam" bekle.

### Aşama bittiğinde kullanıcıya TAM OLARAK bu formatta bildir, sonra dur:

```
🚩 AŞAMA TAMAMLANDI: <no> — <ad>

✅ Yapılanlar:
- ...

🎮 Test etmek için:
- ... (hangi tuşlar, neye bakmalı)

➡️ Sıradaki aşama: <no> — <ad>
🔧 Senin yapman gerekenler: <ROADMAP'teki "Taha" sütunu, yoksa "Yok">

Hazır olduğunda "devam" yaz.
```

Sıradaki aşamanın ön koşulu varsa, kullanıcı "devam" dedikten sonra önce o araçları kontrol et (sürüm komutu / `claude mcp list` / Blender eklenti durumu); eksik varsa yine dur.

---

## 3. Mimari kurallar

### Oynanış düzlemi
- 3D sahne, oynanış **XZ düzleminde**; yükseklik (zıplama, kat) yok. Kamera sabit açılı, askeri izler.
- Kontrol: WASD hareket, Space dash. Silahlar hedefi kendisi seçer ve kendisi ateş eder; oyuncu nişan almaz.

### Karakter: fizik ve görüntü ayrı
```
Player (CharacterBody3D)      ← hareket, çarpışma, durum
 ├─ CollisionShape3D          ← sabit kapsül; modele göre büyütülmez
 └─ Visual (Node3D)           ← yalnız görüntü ve efekt (şimdi kapsül, Aşama 3.1'de model)
```
- Hareket kodu `Visual`'ın çocuklarına **hiçbir zaman** doğrudan dokunmaz; `state_changed(new_state, old_state)` ve `event(name: StringName, data: Dictionary)` sinyalleriyle haber verir. Aynı ayrım zombiler için de geçerli.
- `RigidBody3D` ya da hazır fizik davranışı kullanılmaz; hareket elle yazılır.

### Ayar değerleri ve içerik
- Tüm oynanış sayıları tek yerde: `scripts/tuning.gd` (`class_name Tuning`, `const`). Kodda sihirli sayı yok.
- Silah, eşya, zombi türü ve dalgalar **veri tablosu**; yeni içerik bir satır eklemektir, yeni kod dalı değil.
- Çalışma zamanı etkileri (eşya, yükseltme) çarpanlarla uygulanır; `Tuning` sabit kalır.

### Kalite profilleri (platforma bağlı her şey buradan)
- Zombi üst sınırı, gölge, parçacık yoğunluğu, ışık ve ekran efektleri tek profil kaynağından okunur (düşük / orta / yüksek); ayarlardan değişir.
- Bu değerleri koda gömme; `OS.has_feature("web")` gibi platform dallarını oyun koduna yayma. Platform yalnız varsayılan profili seçer.

### Sürü bütçesi
- Zombi, mermi, toplanabilir ve efektler **havuzdan** gelir; her seferinde yaratılıp yok edilmez.
- Zombiler için yol bulma (navigation) yok; basit yönelme + birbirini itme.
- Hedef seçimi ve çarpışma sorguları her karede tüm listeyi taramamalı.

### Saf kurallar + test
- Hasar hesabı, silah birleştirme, mağaza, dalga üretimi, kart seçimi gibi kurallar sahneden bağımsız saf sınıflarda; hepsi GUT testli. Saf sınıflar autoload'a dokunmaz, değer parametreyle gelir.

### Akış ve arayüz
- Duraklatma ve oyun akışı tek yerden yönetilir (`GameFlow` autoload); `get_tree().paused`'a başka yerden dokunma. `Engine.time_scale`'e yalnız `GameFlow.hit_stop` dokunur; süreler gerçek zamanla ölçülür.
- Arayüz anchor/container ile kurulur, her pencere boyutunda çalışır. Oyun içi yazılar minimal.
- Debug tuşları ve paneli yalnız debug yapıda çalışır (`OS.is_debug_build()`); yayın sürümünde yok.

### Klasör yapısı
```
scenes/        main.tscn, player/, enemies/, weapons/, world/, ui/, fx/
scripts/       tuning.gd, autoload/, game/ (saf kurallar), data/ (içerik tabloları), player/, enemies/, weapons/, world/, ui/, fx/
assets/        models/, shaders/, audio/, fonts/, textures/
tests/         GUT testleri
tools/         yardımcı scriptler (blender/, sfx/)
docs/          GAME_DESIGN.md, PROGRESS.md, concept/
```

---

## 4. Kod standartları

- GDScript'te **statik tipleme** (`var speed: float = 0.0`, `func dash() -> void:`).
- Tanımlayıcılar İngilizce, yorumlar kısa ve Türkçe olabilir.
- Bir fonksiyon tek iş yapsın; dosyalar ~300 satırı geçmesin.
- `.tscn` dosyalarını elle düzenlerken dikkat (uid/ext_resource tutarlılığı). Sahneler sade olsun; mümkünse düğümleri kodla oluştur.
- Her değişiklikten sonra `godot --headless --path . --quit` ile hata kontrolü. Yeni kod uyarısız kalmalı.

### Testler (GUT, `addons/gut/`)
- GUT sürümü Godot sürümüyle eşleşmeli: Godot 4.7 → GUT 9.7.x. GUT dosyalarını düzenleme.
- Test dosyaları `tests/test_*.gd`, `extends GutTest`; ayarlar `.gutconfig.json`.
- Çalıştırma (PowerShell): `godot --headless --path . -s res://addons/gut/gut_cmdln.gd` → "All tests passed" ve çıkış kodu 0.
- Beklenen değerleri `Tuning`'den türet; ayar değişince testler kırılmasın.

### Doğrulama araçları (yalnız debug yapı; ana sahneye argümanla eklenir)
- Ekran görüntüsü: `godot --path . -- --capture=build/shots/x.png --capture-seconds=8 [--capture-spawn=300] [--autopilot] [--god] [--capture-dash=S] [--capture-kill=S] [--camera-distance=M] [--weapons=N] [--debug-panel] [--wave=N] [--capture-wave-end=S] [--levels=N] [--capture-pick]` → PNG'yi Read ile aç. `--wave=N`: N. dalgadan başlar; `--capture-wave-end=S`: görüntüden S sn önce dalgayı bitirir; `--levels=N`: N seviye atlatır (kart ekranı dalga arasında açılır); `--capture-pick`: açılan kart ekranında 1'e basar. `--autopilot`: asker ölümsüz, daire çizer. `--god`: asker ölümsüz, yerinde durur (zombi saldırısını görmek için).
- Özel saldırı ölçümü: `godot --headless --path . --fixed-fps 60 -- --capture=build/shots/x.png --capture-seconds=19 --capture-spawn=40 --capture-kind=runner|jumper|tongue --god [--circle | --zigzag=0.7] [--capture-near=7]` → sonda `LUNGE/JUMP/TONGUE` sayaçları (ayakta duran asker %100 vurulur; kaçışlar bu sayılarla ayarlanır). `--capture-root=S`: asker S sn önce 1 sn bağlanır (çırpınma/kurtulma karesi).
- Tam tur botu (denge ölçümü): `powershell -File tools/autoplay_runs.ps1 -Runs 5` (içeride `godot --headless --path . --fixed-fps 60 -- --autoplay`) → bot kaçar, kart seçer, mağazadan alır; dalga başına öldürme / kristal / hasar / silah raporu ve `RESULT WIN|LOSS`; ~10 sn'de biter. Bot insan değildir: sayıların yönünü gösterir, zorluğu kesinleştirmez.
- Sürü ölçümü: `godot --path . -- --bench` → vsync kapalı, 50'şer zombi ekler, 60 FPS altına düşünce durur; sonuç stdout'ta `BENCH` satırları ve `user://bench_result.txt`.
- `-s` ile çalışan SceneTree betikleri autoload'ları göremez; oyun sınıflarına dokunan araçları bu yüzden betik olarak değil, debug düğümü olarak yaz.
- Animasyon önizleme: `godot --path . res://scenes/debug/anim_preview.tscn [-- --model=soldier] [--capture=build/shots/anim.png]` → her klip bir modelde.
- **Hareketli önizleme (animasyon değerlendirmesi için zorunlu):** `powershell -File tools/preview_movie.ps1 -Name <ad> [-Seconds 6] [-Fps 30] [-Scene res://...] [-GameArgs "<oyun argümanları>"] [-Cols 4] [-Rows 3] [-Skip 0]` → `build/movies/<ad>_sheet.png` (kare özeti, Read ile bak) + `build/movies/<ad>.avi` (Taha izler; ffmpeg varsa `.mp4`). Pencere açılır; ana sahne argümanlarına `--capture` kendiliğinden eklenir. Örnek dilci: `-GameArgs "--capture-spawn=40 --capture-kind=tongue --god --capture-near=7"`.
- Model inceleme: `blender --background --python tools/blender/inspect_model.py -- <model> build/shots/<ad>` → üç yönden görüntü + ölçüler.
- Zombi galerisi: `godot --path . res://scenes/debug/zombie_gallery.tscn [-- --clips] [--capture=build/shots/zombies.png]` → gövde çeşitleri ve renk şemaları; `--clips` ile zombi klip seti (her klip adıyla).
- `--import` çıktısındaki `ERROR` satırlarını süzmeden oku; doku ve model hataları yalnız orada görünür.
- Debug tuşları: F3 panel, F4 +50 zombi, F5 ölümsüz, F6 kalite profili, F7 +silah (en çok 6; `Tuning.DEBUG_WEAPONS` sırasıyla: tabancayla başlanınca ilk F7 pompalı), F8 dalgayı bitir, F9 +1 seviye. Fn kilitli dizüstünde aynı sırayla Ctrl+3 … Ctrl+9; tam ekran F11 ya da Alt+Enter. Editörün gömülü oyun penceresinde (Game sekmesi, "Embed Game on Next Play") tam ekran desteklenmez ve tuşlar editöre gidebilir; debug tuşlarını denerken gömmeyi kapat ya da `godot --path .` kullan.

### Model hattı (Aşama 2–4, 7)
- Blender işleri script olarak `tools/blender/` altında saklanır; model elle değil script ile yeniden üretilebilir olmalı.
- **Blender + MCP etkileşimli üretim hattının parçasıdır.** Her Blender işinde önce `claude mcp list` ile `blender` bağlantısını kontrol et; Blender açıksa `blender-mcp` eklentisinden bağlanmış olmalı. MCP bağlantısı yoksa sessizce arka plan betiğine geçme: Taha'dan Blender'ı açıp N → BlenderMCP → Connect to Claude ile bağlamasını iste, ardından devam et. Blender MCP'yi sahne kurma, modeli canlı inceleme, malzeme/ışık/kompozisyon ayarı ve viewport ekran görüntüsü alma için aktif kullan.
- **Yeniden üretilebilirlik şartı:** MCP ile bulunan ve Taha'nın beğendiği son görünüm, `tools/blender/<asset>.py` içinde temiz ve tekrar çalıştırılabilir üretim adımı olarak saklanır. Son doğrulamayı bu scripti Blender MCP üzerinden yeniden çalıştırarak yap; elle yapılan kalıcı değişiklikleri scriptte karşılığı olmadan bırakma. MCP canlı Blender oturumu ve script birbirini tamamlar: MCP görsel keşif/cila için, script kaynak gerçekliği ve yeniden üretim için kullanılır.
- Model dışa aktarımından sonra `godot --headless --path . --import` ve `godot --headless --path . -s res://tools/godot/check_anim_import.gd` ile içe aktarımı doğrula; oyunda veya model inceleme sahnesinde görüntü alıp gerçek sonucu kontrol et. Görsel kaliteyi viewport/oyun görüntüsünden değerlendir; ölçüler, topoloji, animasyon ve export için ilgili Blender skill'lerinin QA adımlarını da uygula.
- İskelet standardı, kemik eşlemesi ve komutların açıklaması `docs/TECH.md`'de. Her karakter 25 kemikli ortak iskelete bağlanır.
- Model kaynağı: zombiler tamamen Blender'da Claude'un scriptleriyle (`tools/blender/zombie_kit.py` + `build_<tür>.py`, Blender MCP ile çalıştırılır ve görüntüyle yinelenir); kıyafet, renk ve gövde çeşitleri veriyle. Asker Tripo modeli. Bütçeler `docs/TECH.md`.
- Ham Tripo dosyası ve ham kütüphane paketleri (`assets/models/source/`) git'e girmez.
- Blender skill'leri `.claude/skills/` altında (arjun988/blender-skills'ten seçilmiş 35 skill + ortak `references/`, MIT). İşe başlamadan ilgili skill'leri aç ve kullan: genelde `blender-director` + `lowpoly-style`/`stylized-style`; karakterde `character-artist`/`creature-artist` ve `rigging`/`animation`; silah/prop'ta `hard-surface`/`prop-artist`; arenada `environment-artist`, `apocalypse-worlds`, `lighting`, `set-dressing`; her işte gerektiğinde `materials`, `uv-workflow`, `asset-optimization`, `godot-export`, `qa-review`. Skill seçimini ihtiyaca göre dar tut; ilgisiz skill'leri topluca yükleme. Skill'ler kalite ve Blender iş akışını yönlendirir; yukarıdaki MCP + script sözleşmesi Deadzone'un kalıcı üretim kuralıdır. Export her zaman GLB'dir (`godot-export`); polycount ve doku sınırları `docs/TECH.md` ile çelişirse `docs/TECH.md` geçerlidir.

---

## 5. Git

- Her çalışan adımdan sonra commit. Mesaj kısa ve açıklayıcı (ör. `feat: dash eklendi`).
- Remote: `origin` → `AIVoidLabs/Deadzone-Last-Stand`. **Push'u yalnız kullanıcı isterse yap.** `gh` kurulu ve girişli.
- `.gitignore`: `.godot/`, dışa aktarım çıktıları (`build/`), ham model kaynakları.

---

## 6. Lisans ve asset'ler

- Repo herkese açık, oyun itch.io'da ücretsiz: yalnız açık dağıtıma izin veren asset (CC0 / atıflı CC-BY); Mixamo yok.
- Dışarıdan gelen her asset ve araç için `CREDITS.md`'ye kaynak + lisans satırı ekle.
- Kod lisansı henüz kararlaştırılmadı; kullanıcıya sor, kendiliğinden LICENSE ekleme.

---

## 7. Henüz kararlaştırılmamış konular

Liste `docs/DECISIONS.md` içindeki "Açık kararlar" tablosunda, hangi alt aşamada sorulacağıyla birlikte. İlgili alt aşamaya gelince kullanıcıya sor; kendi başına karar verip ilerleme. Verilen karar aynı dosyaya tarihle yazılır.
