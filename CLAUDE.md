# Deadzone Last Stand — Claude Code Talimatları

3D low-poly, dalga tabanlı hayatta kalma oyunu. Zırhlı ve kasklı bir asker, kapalı bir şehir arenasında zombi sürülerine karşı otomatik ateş eden silahlarla ve dash ile ayakta kalmaya çalışır. Brotato'nun tur yapısı (dalga + mağaza + silah yuvaları), Vampire Survivors'ın sürü hissi; kendi adı, karakterleri ve görselleriyle özgün bir oyun.

- **Motor:** Godot 4.7.2 (Standard sürüm, .NET DEĞİL) — **Dil:** GDScript
- **Renderer:** Forward+
- **Hedef:** masaüstü (Windows + Linux). Web en sonda denenir ve hiçbir kararı sınırlamaz (bölüm 1, kural 6).
- **Tasarım:** `docs/GAME_DESIGN.md` (mekanikler ve başlangıç ayar değerleri; Aşama 0'da yazılır)
- **Durum:** `docs/PROGRESS.md` (hangi aşamadayız, ne bitti, sırada ne var; Aşama 0'da yazılır)
- **Yol haritası:** https://claude.ai/artifact/7sYmrAtEEhywsxCcwPpkjy

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
Aşamaya özel ön koşullar (Blender, blender-mcp, Tripo) bölüm 2'deki tabloda; onları yalnız o aşamaya gelince kontrol et.

Ardından `docs/PROGRESS.md`'yi oku ve kullanıcıya tek cümleyle hangi aşamada olduğumuzu ve sıradaki işi söyle.

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

---

## 2. Aşamalar ve geçiş kuralı

| # | Aşama | Bitti sayılır, eğer… | Bu aşama için kullanıcının yapması gerekenler |
|---|---|---|---|
| 0 | **Kurulum ve iskelet** | `claude mcp list`'te `godot` ve `blender` bağlı; Claude Blender'dan sahne bilgisini okuyabiliyor; boş proje (Forward+) headless hatasız; GUT kurulu ve örnek test geçiyor; boş sahne Windows ve Linux'a dışa aktarılıyor; `docs/GAME_DESIGN.md`, `docs/PROGRESS.md`, `.gitignore`, ilk commit hazır. | İki `claude mcp add` komutu, Blender'da Connect |
| 1 | **Çekirdek prototip** (kutularla) | Kapsül asker yürüyor; kutu zombiler üst üste binmeden onu sarıyor; tek silah en yakın hedefe kendisi ateş ediyor; can, hasar, ölüm, yeniden başlat; izleyen kamera; F3 debug paneli. 30 saniyelik çatışma kutularla bile gergin ve okunaklı. Masaüstünde kaç zombiyle 60 FPS kaldığı ölçülüp `PROGRESS.md`'ye yazıldı. | Yok |
| 2 | **Tur döngüsü** | Dalga sayacı ve süresi; XP ve para düşmesi; seviye atlayınca 3 karttan biri; dalga arası mağaza; 6 silah yuvası ve birleştirme; temel istatistikler. 5–6 dalga, 3–4 silah, ~10 eşya ile baştan sona bir tur oynanıyor; kazanma ve kaybetme var. | Yok |
| 3 | **Dash ve his** | Dash (kısa dokunulmazlık, bekleme süresi), vuruş geri bildirimi, hasar sayıları, sarsıntı, hit-stop, namlu parlaması, mermi izi, ölüm parçacıkları, para çekimi. Efektler belirgin ama kalabalık değil. | Oynayıp efekt dozunu onaylamak |
| 4 | **Asker** | Tripo modeli Blender'da temizlendi, riglendi, animasyonları (bekleme, koşu, dash, vurulma, ölüm) yapıldı ve görüntü katmanına takıldı; silah modelleri görünüyor. | Konsept görseli, **Tripo**'da model (A-poz, tek parça, silahsız), **Blender** açık ve bağlı |
| 5 | **Zombiler** | Tek ortak iskelet ve animasyon seti; parça/renk karışımıyla görsel çeşitlilik; türler (yürüyen, koşan, tank, tüküren, patlayan, boss) uzaktan ayırt ediliyor; sürü Aşama 1'de ölçülen sayıda akıcı. | **Blender** açık ve bağlı; varyasyon onayı |
| 6 | **Arena, atmosfer, ses** | Şehir sokağı (yol, kaldırım, binalar, barikatlar, engeller), ışık ve sis; ses efektleri kodla sentezlendi. Asker ve zombiler zeminden net ayrışıyor. | Sesleri dinleyip onay; müzik kararı |
| 7 | **Arayüz ve akış** | Ana menü, duraklatma, ayarlar (ses, tam ekran, kalite profili), HUD, mağaza ve kart ekranlarının son hali, tur sonu özeti, kayıt dosyası. | Yok |
| 8 | **Kalıcı ilerleme** | Turlardan kazanılan kalıcı para; bununla açılan başlangıç silahları, asker sınıfları, kalıcı yükseltmeler. Gerçek para yok. | Kapsam onayı |
| 9 | **İçerik ve denge** | Silah, eşya, dalga sayısı hedefe çıktı; zorluk eğrisi, fiyatlar, düşme oranları ayarlandı; en az üç farklı kurulum işe yarıyor. | Oynayış geri bildirimi |
| 10 | **Yayın** | Windows ve Linux çıktıları temiz makinede oynanıyor; README, CREDITS, ekran görüntüleri hazır. Web en son, düşük profil + yalnız web çıktısına özel Compatibility ile denendi; yayınla ya da bırak kararı verildi. | Yayın onayı, itch.io sayfası |

İlk sürüm içerik hedefi (öneri, Aşama 2 ve 9'da kullanıcıyla kesinleşir): 20 dalga, 12 silah × 4 kademe, ~30 eşya, 6 zombi türü + 1 boss, 3 asker sınıfı, 1 arena.

### Aşama bittiğinde kullanıcıya TAM OLARAK bu formatta bildir, sonra dur:

```
🚩 AŞAMA TAMAMLANDI: <no> — <ad>

✅ Yapılanlar:
- ...

🎮 Test etmek için:
- ... (hangi tuşlar, neye bakmalı)

➡️ Sıradaki aşama: <no> — <ad>
🔧 Senin yapman gerekenler: <bölüm 2 tablosundaki liste, yoksa "Yok">

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
 └─ Visual (Node3D)           ← yalnız görüntü ve efekt (şimdi kapsül, Aşama 4'te model)
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
- Duraklatma ve oyun akışı tek yerden yönetilir (`GameFlow` autoload); `get_tree().paused`'a başka yerden dokunma. `Engine.time_scale`'e dokunan her şey hit-stop ile uyumlu olmalı.
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

### Model hattı (Aşama 4–5)
- Blender işleri script olarak `tools/blender/` altında saklanır; model elle değil script ile yeniden üretilebilir olmalı.
- Akış: script → pozu sıfırla → kaydet → `.glb` dışa aktar → `godot --headless --import`.
- Ham Tripo dosyası git'e girmez.

---

## 5. Git

- Her çalışan adımdan sonra commit. Mesaj kısa ve açıklayıcı (ör. `feat: dash eklendi`).
- Remote: `origin` → `AIVoidLabs/Deadzone-Last-Stand`. **Push'u yalnız kullanıcı isterse yap.** `gh` kurulu ve girişli.
- `.gitignore`: `.godot/`, dışa aktarım çıktıları (`build/`), ham model kaynakları.

---

## 6. Lisans ve asset'ler

- Dışarıdan gelen her asset ve araç için `CREDITS.md`'ye kaynak + lisans satırı ekle.
- Kod lisansı henüz kararlaştırılmadı; kullanıcıya sor, kendiliğinden LICENSE ekleme.

---

## 7. Henüz kararlaştırılmamış konular

İlgili aşamaya gelince kullanıcıya sor; kendi başına karar verip ilerleme.

- Silahlar askerin etrafında mı süzülsün, yalnız eldeki mi görünsün? (Aşama 2)
- Kan ve şiddet dozu. (Aşama 3)
- Asker konsepti ve oranları. (Aşama 4)
- Gamepad desteği, oyun dili. (Aşama 7)
- Kalıcı ilerlemenin kapsamı. (Aşama 8)
