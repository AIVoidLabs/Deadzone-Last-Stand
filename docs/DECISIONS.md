# Deadzone Last Stand — Kararlar

Tarihli kararlar ve açık kararlar. Yeni karar en üste eklenir; açık karar verilince "Açık kararlar"dan çıkarılıp tarihli bölüme yazılır.

## 2026-11-17 — Aşama 6.2 düşenler (Taha)

- **Tek tür düşen: kristal** — hem XP hem para (iki ayrı para birimi yok). Ad Claude'dan: zırhın enerji teması.
- **Yalnız yakındakiler çekilir** (3 m); dalga sonunda hepsi.
- **Görünüm:** ilk deneme turkuaz sekizyüzlü; Taha "çok büyük ve çok basit" dedi → küçük, beyazımsı, altı köşeli taş kesimi kristal.
- Claude'un kararı: seviye eğrisi (seviye + 3)², Brotato'daki gibi; ses: kısa cam tınlaması (Taha dinleyip onaylar).

## 2026-11-17 — Aşama 6.1 dalgalar (Taha)

- Dikey dilim onaylandı ("her şey okey"); zombi saldırısı hazırlıklı vuruş olarak kaldı.
- **Tur: 5 dalga, 20 → 60 sn** (başlangıç değeri; kesin sayılar Aşama 11'de).
- **Mağaza gelene kadar dalga arası otomatik 3 sn** ("Dalga N" yazısı, tuş beklemez).
- **Zombiler ekranın hemen dışında doğar** (arena kenarı yerine); yerden kalkma yine çoğunlukla görünmez ama sürü ekrana hızlı girer.
- Claude'un kararı (gerekçeli): dalga sonunda devrilen zombiler öldürme sayılmaz ve ileride XP/para bırakmaz (Brotato'daki gibi); bekleme sırasında asker iyileşmez (iyileşme 6.3 istatistik/kart ya da 6.5 eşya işi).

## 2026-11-17 — Aşama 5.6–5.7 pompalı, ışık (Taha)

- Pompalı onaylandı ("güzel"), ayar değişmedi.
- **Işık: "dusk" (akşam) seçildi** (galeri `docs/concept/lighting_gallery.png`: classic / dusk / overcast). Koyu lekeli asfalt, sıcak alçak güneş, hafif mavi sis, AgX ton eşleme. Değerler `LightingData` tablosunda, seçim `Tuning.LIGHTING_PRESET`. 8.3'te (ışık, sis, ekran efektleri) buradan devam edilir.
- Asker zırhı soluk görünüyordu: Tripo dokusu açık tonlu. Doku değişmeden `Tuning.PLAYER_ALBEDO_TINT` ile koyulaştırılıp maviye çekildi.
- Dash toz izi kare parçacıklardan yumuşak yuvarlak bulutlara çevrildi (`docs/concept/dash_dust.png`).

## 2026-11-17 — Aşama 5.5 ilk sesler (Taha)

- **Zombiye isabet sesi yok:** her vuruşta çalması rahatsız edici. `Tuning.FEATURE_SFX_HIT = false` (dosyalar duruyor). Yerine **sürü homurtusu:** askerin 10 m çevresindeki zombi sayısı arttıkça homurtu sıklaşır ve yükselir (`HordeGroan`, `HordeAmbience`, `FEATURE_SFX_HORDE_GROAN`).
- **Atış sesi beğenildi. Her silah modelinin kendi sesi olacak:** silah satırındaki `sound` alanı; pompalı 5.6'da kendi sesini alır, diğerleri 7.1'de.
- **Adım sesi şimdilik metal zemin gibi, kabul.** İleride zemine duyarlı olacak (asfalt, metal, moloz…): 8.1 şehir parçaları gelince zemin türü, 8.4 tam ses setinde zemin başına adım çeşitleri.
- **Takla sesi çok baskındı:** kısıldı (-6 → -13 dB), hava hışırtısı azaltıldı; zırhlı asker hissi için zırh plakası ve alet çantası tıngırtısı eklendi (3 çeşit).
- Editör gömmesi kapatılınca F tuşları ve tam ekran sorunsuz (Taha doğruladı).
- **Zombi ölüm sesi de yok** (`FEATURE_SFX_ZOMBIE_DEATH = false`). Zombiden gelen tek ses sürü homurtusu.
- **Bunlar temel sesler.** Şimdilik böyle ilerlenir. İlerleyen aşamalarda (8.4 tam ses seti) ya yeniden düzenlenir ya da animasyon kütüphanesinde olduğu gibi Claude'un yönlendirmesiyle Taha ücretsiz lisanslı (CC0) bir ses paketi indirir; Claude lisansı kontrol edip seçim önerir.

## 2026-11-16 — Aşama 5.4 asker vurulunca (Taha)

- **Askerin vurulunca itilmesi iptal:** "çok uzağa alakasız itiliyoruz". `Tuning.FEATURE_PLAYER_KNOCKBACK = false`; kızarma, sarsıntı ve yanıp sönme kaldı.

## 2026-11-16 — Aşama 5.3 vuruş geri bildirimi (Taha)

- Kan sıçraması, lekeler ve hasar sayıları beğenildi ("kanlar vs iyi").
- **Öldürmede duraksama (hit-stop) iptal:** kalabalıkta oyun takılıyormuş gibi hissettiriyor. `Tuning.FEATURE_HIT_STOP = false`; kod (`HitStop`, `GameFlow.hit_stop`) duruyor, ileride boss ya da tek büyük vuruş gibi seyrek anlarda denenebilir. Öldürmedeki küçük kamera sarsıntısı kaldı.
- Taha oyunu Godot editöründen (Play) açıyor. Ölçüm: 234 zombi + 6 silah + tüm efektlerle 128 FPS (yüksek profil), yani takılma hissi FPS'ten değil duraksamadan.

## 2026-11-16 — Aşama 5.1 silah yerleşimi ve enerji çemberi (Taha)

- Geri bildirim: silah sola koşarken çok geride kalıyor, sağa koşarken askerin içine giriyor. → Silahlar askere sabit bağlandı (izleme gecikmesi kaldırıldı); süzülme hissi yalnız salınımdan.
- Hikâye: gelişmiş zırh, askerin çevresine bir **enerji çemberi** yansıtır; silahlar bu çemberin üstünde durur. Çember 5.1'de eklendi (turuncu, kesikli, dönen; silah yuvalarında parlar).
- İleride: çemberde yakın dövüş silahları da olabilir (**ışın kılıcı** vb.) → Aşama 7.1 silah davranış setine eklendi.

## 2026-11-16 — Aşama 4 kapanışı (Taha)

- Zombi saldırısı: **hazırlıklı vuruş** (kaçılabilir) varsayılan. Taha ayrıca seçim yapmadan "devam" dedi; "değince hasar" `Tuning.FEATURE_ZOMBIE_WINDUP_ATTACK = false` ile hâlâ geri açılabilir. Oynarken fikri değişirse 5.7 dilim onayında yeniden bakılır.

## 2026-11-16 — Zombi türleri listesi (Taha; Codex ile konuşup getirdi)

- Her tür oyuncuya ayrı bir karar çıkarmalı. Kabul edilen liste: sürü zombisi, koşucu (hazırlıklı atılma), çığlıkçı (zombi çağırır), zırhlı (önden dayanıklı, yandan/arkadan zayıf), tükürücü (yerde kalan asit alanı), patlayıcı (uyarı + patlama, zombilere de hasar). Önceki isteklerle birleşti: zıplayan, sürünen, tank, taş fırlatan. Tam tablo `GAME_DESIGN.md`, uygulama Aşama 7.2–7.3.
- Not (Claude): silahlar kendisi nişan aldığı için zırhlıda "açı değiştirmek" oyuncunun konumlanmasıyla olur; 7.3'te denenip ayarlanacak.

## 2026-11-16 — Aşama 4.1 zombi görünümü (Taha)

- Köşeli low-poly tarz ve renkler beğenildi. Çeşitlilik çok artırılacak (ekranda çok sayıda zombi olacak); koyu tonlar da eklenecek → 10 gövde × 16 renk şeması.
- Yeni zombi türleri istendi: yalnız yürüyen değil **sürünen, koşan, zıplayan**; görünümleri de farklı. Koşan zaten 7.2'deydi; sürünen ve zıplayan 7.2'ye eklendi. Kütüphanede koşu ve zıplama klipleri var; sürünme klibi yok, türetilecek.
- Tripo lisansı ayrıca doğrulandı (yukarıda, 3.1 notu).

## 2026-11-16 — Aşama 3.1 asker konsepti (Taha)

- Tripo modeli (`armored-soldier-3d-model.glb`) beğenildi; bu model üzerinden devam.
- Tripo lisansı: Taha doğruladı, açık repoda kullanımda sorun yok (2026-11-16).
- Oranlar: stilize ve iri (yaklaşık 5–6 kafa boyu). Tarz: ağır zırhlı, yakın gelecek. Renk: koyu lacivert + turuncu vurgu. Ayrıntı ve Tripo metni: `concept/soldier.md`.
- Geri bildirim: zombiler ekranda biraz küçük görünüyor; kamera yakınlığı 3.5'te ayarlanacak (Taha: "ileride ayarlanacaksa sorun değil").

## 2026-11-16 — Aşama 2.4 önizleme yorumu (Taha)

- Asker koşusu: **Sprint**. Dash: **Roll** (takla).
- Zombi yürüyüşü, bekleme ve saldırı (`Zombie_Walk_Fwd`, `Zombie_Idle`, `Zombie_Scratch`) beğenildi; vurulma ve ölüm klipleri "güzel".
- **Uzaktan saldıran zombiler gerekli:** asit, taş gibi şeyler fırlatıp hasar verenler; oyuncu bunlardan kaçabilmeli. Yol haritasında 7.3 buna göre genişletildi.

## 2026-11-16 — Aşama 2.1 (Taha)

- **Repo herkese açık olacak** (GitHub'da public). Sonuç: repoya giren her asset açık dağıtıma izin veren lisansta olmalı (CC0 ya da benzeri); Mixamo gibi ham dosya dağıtımı kısıtlı kaynaklar kullanılmaz.
- **Animasyon kütüphanesi:** Quaternius Universal Animation Library 1 + 2, ücretsiz Standard sürümleri (CC0). Taha indirdi; lisans metni paketin içinden doğrulandı.
- **Blender işleri penceresiz çalışır** (`blender --background --python <script>`); Taha'nın Blender'ı açıp bağlaması yalnız canlı önizleme istenirse gerekir. (Claude'un önerisi; 5.3.0 ile denendi.)

## 2026-11-16 — Ana plan (Taha)


| Konu | Karar |
|---|---|
| Aşama sırası | Önce dikey dilim (asker + zombi + silah hissi), sonra sistemler |
| Animasyon kaynağı | Ücretsiz ve lisansı sorunsuz hazır kütüphane + Claude'un Blender scriptleri ve kod tarafı cilası |
| Sürü hedefi | Ekranda 150–300 zombi, hepsi gerçek iskeletle, zengin animasyon |
| Fizik | Gerçekçilik değil, Brotato / Vampire Survivors anlayışı: elle yazılmış itme ve sendeleme; ragdoll yok. Patlamalar çevredeki zombilere de hasar verebilir. Ölen zombi solarak (fade out) silinir |
| Silah görünümü | 6 silahın hepsi askerin etrafında süzülür, her biri kendi hedefine döner |
| Şiddet | Stilize kan: sıçrama parçacıkları, yerde bir süre kalan lekeler; uzuv kopması yok |
| Tripo (Taha üretir) | Asker(ler), boss ve özel zombiler |
| Blender (Claude üretir) | Sıradan zombiler, silahlar, arena ve tüm çevre parçaları |
| Belgeler | Plan `ROADMAP.md`, durum `PROGRESS.md`, kararlar burada, teknik yapı `TECH.md`; her oturum buradan devam eder |

Fizik sorusuna Taha'nın kendi sözü: "Çok gerçekçiliğe gerek yok, Brotato tarzı Vampire Survivors anlayışından çıkmamalıyız; bazen patlamalar ve yandaki zombilere de hasar okey; ölen zombiler fade out gibi silinmeli."

Aşama 1 geri bildirimi (Taha): vuruş hissi yok, hareket cansız, zombiler tehditsiz; "animasyonlar ve karakter modellemeleri ile birlikte düzelebilir, erken konuşuyor olabilirim."

## 2026-11-15 — Başlangıç (Taha)

- Tur yapısı dalga + mağaza; kontrol otomatik ateş + dash; 6 silah yuvası ve birleştirme; kapalı şehir arenası.
- Masaüstü öncelikli (Windows + Linux); web en sonda ve hiçbir kararı sınırlamaz.
- Gerçek para yok; her şey oyunda kazanılan parayla.
- Oyun tam ekran açılır (F11 / Alt+Enter ile pencere).

## Açık kararlar

| Karar | Ne zaman |
|---|---|
| Eksik animasyonlar (ek zombi yürüyüşleri, yönlü ölümler): Claude Blender'da mı üretsin, ücretli Pro sürüm mü alınsın | 4.2 |
| İçerik hedefi sayıları | 6 ve 11 |
| Arenada engel yoğunluğu | 8.2 |
| Müzik | 8.5 |
| Gamepad, oyun dili | 9.7 |
| Kalıcı ilerleme kapsamı | 10 |
| Kod lisansı (MIT?), Linux deneme ortamı | 12'den önce |

