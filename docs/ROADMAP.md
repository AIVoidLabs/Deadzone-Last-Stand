# Deadzone Last Stand — Yol Haritası

Ana ve alt aşamalar, bitiş ölçütleri, Taha'nın işleri. **Yalnız kararla değişir**; değişiklik `DECISIONS.md`'ye tarihle yazılır.
Güncel durum: `PROGRESS.md` · Kararlar: `DECISIONS.md` · Teknik yapı: `TECH.md` · Tasarım: `GAME_DESIGN.md`

Onay: 2026-11-16 (Taha). Sıra ilkesi: **önce dikey dilim** (Aşama 2–5: tek asker + tek zombi + iki silah gerçek model, animasyon, ses ve vuruş hissiyle keyifli 60 saniye); sistemler ve içerik bunun üstüne kurulur.
Önceki plan (2026-11-15, sıfır makine kurulum adımları dahil): `archive/ROADMAP-2026-11-15.md`.

## Aşamalar

Çalışma düzeni: her **alt aşama** tek özelliktir → doğrula (GUT + ekran görüntüsü) → commit → `PROGRESS.md` güncelle → Taha'ya nasıl test edeceğini söyle. Her **ana aşama** sonunda 🚩 bildirimi yapılır ve "devam" beklenir. "Taha" sütunu o adımda Taha'nın yapacağı iştir.

### 0 — Kurulum ve iskelet ✔ bitti
### 1 — Kutu prototip ✔ bitti (his onayı Aşama 5 sonuna devredildi)

### 2 — Model ve animasyon hattı
Amaç: gerçek karakter üretmeden önce hattın ve performansın kanıtlanması.

| # | Alt aşama | Bitti sayılır, eğer… | Taha |
|---|---|---|---|
| 2.1 | Animasyon kütüphanesi seçimi | Adaylar (önce CC0: Quaternius Universal Animation Library; yedek: Mixamo) lisansı ve içeriğiyle karşılaştırıldı, seçim yapıldı, `CREDITS.md`'ye yazıldı | Seçimi onaylar, dosyaları indirir |
| 2.2 | Ortak iskelet standardı | Kemik adları, ölçek, yön, dinlenme pozu `docs/TECH.md`'de yazılı; Godot içe aktarım ayarı (kemik eşleme) çalışıyor | — |
| 2.3 | Deneme mankeni | Claude'un Blender scriptiyle ürettiği low-poly manken ortak iskelette; script → `.glb` → Godot akışı tek komutla yineleniyor (Blender penceresiz çalışır) | — |
| 2.4 | Animasyon aktarımı | Manken Godot'da kütüphaneden yürüme, koşu, vurulma, ölüm oynuyor; döngüler temiz | Ekran görüntüsü/kısa test |
| 2.5 | Sürü performans ölçümü | 150 / 300 / 450 animasyonlu manken ölçüldü; profil sınırları ve seyreltme ayarı belirlendi; 300'de 60 FPS tutuyor ya da çözüm kararı verildi | Sonuca göre karar |

### 3 — Dikey dilim: asker (koşma ve kaçma hissi)

| # | Alt aşama | Bitti sayılır, eğer… | Taha |
|---|---|---|---|
| 3.1 | Asker modeli | Tripo modeli Blender'da temizlendi (üçgen bütçesi, malzeme), ortak iskelete bağlandı, Godot'da duruyor | Konsept onayı, Tripo'da model (A-poz, tek parça, silahsız) |
| 3.2 | Hareket modeli | İvme, duruş, dönüş yeniden ayarlandı; gövde harekete doğru hafif yatıyor; hız değerleri oynanarak seçildi | Oynayıp yorum |
| 3.3 | Asker animasyonları | Bekleme, koşu (hıza bağlı), vurulma, ölüm `AnimationTree` ile akıcı geçiyor; ayak kaymıyor | Oynayıp yorum |
| 3.4 | Dash | Kısa dokunulmazlık, bekleme süresi, zombilerin arasından geçiş, iz efekti, HUD göstergesi | Oynayıp yorum |
| 3.5 | Kamera | Yakınlık ve açı yeniden seçildi (karakterler küçük görünmüyor); hafif ileri bakış; sarsıntı altyapısı | Yakınlık onayı |

### 4 — Dikey dilim: zombi (tehdit hissi)

| # | Alt aşama | Bitti sayılır, eğer… | Taha |
|---|---|---|---|
| 4.1 | Yürüyen zombi modeli | Claude'un Blender'da ürettiği low-poly zombi ortak iskelette; 3–4 parça/renk çeşidi | Görünüm onayı (galeri görseli) |
| 4.2 | Zombi animasyonları | 2–3 sürünme/yürüyüş çeşidi, saldırı, sendeleme, 2–3 ölüm, yerden doğma; zombiler aynı adımda yürümüyor | Oynayıp yorum |
| 4.3 | Durum makinesi ve saldırı | Doğma → kovalama → saldırı → sendeleme → ölme. Saldırı kısa hazırlıkla vurur (kaçılabilir); eski "değince hasar" tek sabitle geri açılabilir | İki saldırı biçimini deneyip seçer |
| 4.4 | İtme ve sendeleme | Vurulan zombi geriye itilir ve kısa süre sendeler; ağırlık türe göre; itişme korunur | Oynayıp yorum |
| 4.5 | Ölüm | Vuruş yönüne doğru ölüm animasyonu, ardından solarak silinme ve havuza dönüş | Oynayıp yorum |

### 5 — Dikey dilim: silah ve vuruş hissi

| # | Alt aşama | Bitti sayılır, eğer… | Taha |
|---|---|---|---|
| 5.1 | Süzülen silah yuvaları | 6 yuva askerin çevresinde; her silah kendi hedefine döner, ateşte geri teper; silah modelleri Blender'dan | Oynayıp yorum |
| 5.2 | Atış görseli | Namlu parlaması, mermi izi, isabet kıvılcımı | Oynayıp yorum |
| 5.3 | Vuruş geri bildirimi | Parlama, kan sıçraması, yerde solan lekeler, hasar sayıları, öldürmede küçük hit-stop ve sarsıntı; hepsi havuzlu, yoğunluk kalite profilinden | Efekt dozunu onaylar |
| 5.4 | Asker vurulunca | Ekran kenarı kızarması, sarsıntı, kısa geri itilme, yanıp sönme | Oynayıp yorum |
| 5.5 | İlk sesler | Atış, isabet, zombi ölümü, adım, dash, asker vurulma sesleri kodla sentezlendi | Dinleyip onaylar |
| 5.6 | İkinci silah: pompalı | Saçılan atış ve güçlü itme; iki silah belirgin farklı hissediyor | Oynayıp yorum |
| 5.7 | Dilim cilası ve onay | Zemin ve ışık karakterleri net gösteriyor; 60 saniyelik çatışma oynaması keyifli | **Dikey dilim onayı** |

### 6 — Tur döngüsü

| # | Alt aşama | Bitti sayılır, eğer… |
|---|---|---|
| 6.1 | Dalgalar | Dalga tablosu, sayaç ve süre; dalga bitince kalan zombiler solarak ölür; kazanma ve kaybetme |
| 6.2 | Düşenler | XP ve para havuzdan düşer, askere çekilir, dalga sonunda otomatik toplanır |
| 6.3 | İstatistikler ve kartlar | Can, hasar, atış hızı, menzil, hız, zırh, şans çarpanlarla; seviye atlayınca 3 karttan biri |
| 6.4 | Silah yuvaları ve birleştirme | 6 yuva, aynı silah + aynı kademe → üst kademe (en çok 4) |
| 6.5 | Mağaza ve eşyalar | Dalga arası mağaza, yenileme, ~10 eşya |
| 6.6 | Tam tur | 5–6 dalga, 3–4 silah ile baştan sona oynanıyor; ilk denge |

Arayüz bu aşamada işlevsel ve sade; son görünüm Aşama 9'da. Taha her alt aşamayı oynar.

### 7 — Silah ve zombi çeşitliliği

| # | Alt aşama | Bitti sayılır, eğer… | Taha |
|---|---|---|---|
| 7.1 | Silah davranış seti | Veri satırından seçilen davranışlar: tek mermi, saçılma, delip geçme, patlama (alan hasarı), yakın dövüş savurma, yanma | Oynayıp yorum |
| 7.2 | Koşan ve tank | Blender'dan; siluet ve hareketle uzaktan ayırt ediliyor | Görünüm onayı |
| 7.3 | Tüküren ve patlayan | Tüküren uzaktan mermi atar; patlayan ölünce alan hasarı verir ve çevresindeki zombilere de zarar verir | Tripo'da özel zombi modelleri |
| 7.4 | Boss | Kendi saldırı düzenleri, can çubuğu, boss dalgası | Tripo'da boss modeli |
| 7.5 | Yeniden ölçüm | Karışık türlerle sürü ölçümü; profil sınırları güncel | — |

### 8 — Arena, atmosfer, ses
8.1 Şehir sokağı parçaları (yol, kaldırım, binalar, barikat, enkaz; Blender) · 8.2 Engeller ve zombilerin engel çevresinden dolaşması (yol bulma yok, basit kaçınma) · 8.3 Işık, sis, ekran efektleri; karakterler zeminden net ayrışıyor · 8.4 Tam ses seti · 8.5 Müzik kararı. — Taha: görünüm ve ses onayı, müzik kararı.

### 9 — Arayüz ve akış
9.1 Ana menü ve duraklatma · 9.2 Ayarlar (ses, tam ekran, kalite profili) · 9.3 HUD son hali · 9.4 Mağaza ve kart ekranları son hali · 9.5 Tur sonu özeti · 9.6 Kayıt dosyası · 9.7 Gamepad ve oyun dili (karara göre). — Taha: gamepad ve dil kararı.

### 10 — Kalıcı ilerleme
10.1 Kalıcı para ve kayıt · 10.2 Asker sınıfları (Tripo modelleri) · 10.3 Başlangıç silahı açılımları · 10.4 Kalıcı yükseltmeler. Gerçek para yok. — Taha: kapsam onayı, diğer asker modelleri.

### 11 — İçerik ve denge
11.1 Silah ve eşya sayısı hedefe · 11.2 Dalga sayısı ve zorluk eğrisi · 11.3 Fiyatlar ve düşme oranları · 11.4 En az üç farklı kurulum işe yarıyor. İçerik hedefi (öneri, bu aşamada kesinleşir): 20 dalga, 12 silah × 4 kademe, ~30 eşya, 6 zombi türü + 1 boss, 3 asker sınıfı, 1 arena. — Taha: oynayış geri bildirimi.

### 12 — Yayın
12.1 Windows ve Linux çıktıları temiz makinede · 12.2 README, CREDITS, ekran görüntüleri · 12.3 itch.io sayfası · 12.4 Web denemesi (düşük profil + Compatibility; yayınla ya da bırak). — Taha: yayın onayı.


## Doğrulama

- **Her alt aşama:** GUT "All tests passed"; `godot --path . -- --capture=build/shots/<ad>.png --capture-seconds=8 --autopilot` ile ekran görüntüsü Read ile incelenir; Taha `godot --path .` ile oynar.
- **Performans (2.5, 7.5):** `godot --path . -- --bench` animasyonlu zombilerle; sonuç `PROGRESS.md` ölçüm tablosuna yazılır.
- **Model hattı:** `tools/blender/` scripti baştan çalıştırılınca aynı `.glb` üretilir; `godot --headless --import` hatasız.
- **Sesler:** Taha dinleyip onaylar (Claude duyamaz).
