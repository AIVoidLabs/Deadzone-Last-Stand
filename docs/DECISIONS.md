# Deadzone Last Stand — Kararlar

Tarihli kararlar ve açık kararlar. Yeni karar en üste eklenir; açık karar verilince "Açık kararlar"dan çıkarılıp tarihli bölüme yazılır.

## 2026-11-19 — Zombiler tamamen Blender'da (Taha)

Taha, dilcinin yalnız Blender Python ile yapılan denemesini (skin modifier gövde, metaball kafa ve çene, bölünmüş çene, boğaz kesesi, ıslak dil; `docs/concept/dilci_trial_v1_*.png`) görünce: "oluşturduğun modeli çok sevdim". Devam tamamen Blender'da; zombiler için Tripo yok.

- **Karar:** tüm zombiler tamamen Blender'da Claude'un scriptleriyle üretilir. Zombiler için K2'nin (Tripo temeli + Claude bitirir) yerine geçer. Asker mevcut Tripo modeli olarak kalır. Boss: sonra karar verilir (varsayılan yine Blender).
- **Hat:** Blender MCP ile çalıştırılan Blender Python scriptleri. Gövdeler skin modifier + voxel remesh; kafa ve imza parçalar metaball; kıyafet (pantolon, yırtık tişört vb.) gövde yüzeyinden üretilir, yırtık etek ve delikli; her zombi için renk ve kıyafet çeşitleri veriyle; animasyonlar elle anahtarlanan scriptlerle (K3).
- **Detay:** ince detay aranmıyor (Brotato tarzı oyun, yukarıdan kamera); çeşitlilik kıyafet, renk şeması ve gövde çeşitlerinden gelir.

## 2026-11-19 — Görsel yeniden yön (Taha)

Taha görsel kaliteden memnun değil: zombiler düz low-poly (`build_zombie.py`, ~650 üçgen, kutu kafa, palet renkleri), asker ise dokulu Tripo modeli; özel hareketler (atılış, zıplama, dil hazırlığı, çırpınma/kurtulma) gerçek animasyon değil, kütüphane kliplerine koddan eklenen sabit kemik açıları; dil 8 cm'lik kutu, 0.12 sn'de uzar ve ışın gibi anında vurur. Aşağıdaki yön onaylandı.

- **K1 Üslup:** düz low-poly bırakıldı. Zombiler askerle uyumlu: stilize-gerçekçi, dokulu, orta poligon. Kamera ~17 m yukarıdan baktığı için siluet, imza parça (dil, pençe, kambur duruş) ve hareket okunmalı. Yeni bütçeler: sıradan zombi 3–5 bin üçgen, özel zombi 8–15 bin, boss ~20 bin, uzaklık için LOD; sürü ölçüm aracıyla yeniden ölçülür. "Tek palet malzemesi" kuralı kalktı.
- **K2 Modeller:** temel modeli Taha Tripo'da üretir (istem ve konsepti Claude yazar); Claude blender-mcp ile Blender'da bitirir: temizlik, 25 kemikli iskelete bağlama, imza parçalar (dil kemik zinciri, pençeler), malzeme. Yordamsal `build_zombie.py` emekli (eski; yenisi gelene kadar repoda kalır). Tasarımlar özgün: referanslar yalnız his verir, başka oyunların karakterleri kopyalanmaz. — aynı gün değişti: zombiler tamamen Blender'da (üstteki karar)
- **K3 Animasyon üç katman:** (1) temel hareket CC0 Quaternius kütüphanesinden; (2) imza hareketler Blender'da elle anahtarlanır, yeniden üretilebilir script olarak saklanır (hazırlık, abartı, devam hareketi, oturma); (3) Godot'da yordamsal katman (yay/verlet dil zinciri, ikincil hareket). İmza hareketi koddan sabit kemik açısı ekleyerek türetmek artık yasak (ofset yalnız yürüyüş çeşitleri gibi küçük farklar için).
- **K4 Dil mekaniği yeniden tasarımı:** hazırlık (kafa geriye gider, çene açılır, boğaz şişer) → dil görülür hızda fırlar ve dalgalanır, dash ile kaçılabilir → isabette asker yavaşça zombiye doğru çekilir → dilci vurulup öldürülürse asker kurtulur. Dil: yordamsal, eğri, uca doğru incelen ıslak tüp; geri çekilirken kırbaç gibi savrulur. Askerin gerçek sürüklenme/çırpınma ve kurtulma animasyonları olur. (Bu, 2026-11-18'deki "tam 1 sn bağlı" tasarımının yerine geçer.)
- **K5 Her türün kimliği:** ayrı siluet, tek imza hareket ve oyuncuya zorlattığı bir karar. Örnek: uzun pençeli, ince "Pençeli": sessizce çömelir, yaklaşınca çığlık atar ve pençeleriyle atılır.
- **K6 Süreç kapısı:** konsept → model → animasyon önizlemesi (video / kare özeti) → Taha onayı → oynanış. Bu sıra bitmeden yeni görsel içerik oyuna girmez. Ekran görüntüsü animasyonu yargılamaya yetmez. Önizleme video aracı yapılıyor.
- **K7 Plan:** Aşama 7.3 ve 7'nin kalanı dondu. 7 ile 8 arasına ara ana aşama **V — Görsel yeniden yön** eklendi (V.1 kurtulma hatası, V.2 önizleme video aracı, V.3 üslup rehberi + konsept galerisi + Blender deneme modeli, V.4 dilci dikey dilimi, V.5 yeni hattın türlere yayılması, V.6 asker animasyon cilası). Bitiş ölçütü: Taha'nın yeni görsel dili ve dilci dilimini onaylaması. V bitince 7 kaldığı yerden devam eder.
- **Yayın ve lisans:** repo GitHub'da herkese açık olacak, oyun itch.io'da ücretsiz indirilecek. Repodaki her asset açık dağıtıma izin vermeli (CC0 ya da `CREDITS.md` satırlı CC-BY). Mixamo kullanılamaz (ham dosya dağıtımını yasaklıyor). Kod lisansı (MIT önerisi) hâlâ açık; yayından önce sorulur.
- **Eksik animasyon sorusu çözüldü:** Claude Blender'da elle anahtarlar + CC0 kütüphane; ücretli paketler yalnız Taha lisansı kontrol ettikten sonra.
- **Blender MCP durumu:** Blender 5.3 bağlı; eklentide yalnız bpy kod çalıştırma ve viewport görüntüsü açık; üreticiler (Tripo/Hyper3D/Hunyuan/Meshy) ve kütüphaneler (Poly Haven/Sketchfab/Poly Pizza) kapalı.
- **Çalışma biçimi:** Claude iyi tanımlanmış işleri model açıkça belirtilerek Sonnet alt ajanlara verebilir (hız ve jeton tasarrufu); tasarım kararı ve doğrulama ana döngüde kalır.

## 2026-11-18 — Sıradaki zombi türleri: zıplayan ve dilci (Taha)

- Koşucu + tank onaylandı ("okey"). **Sıraya eklendi, hemen başlanmayacak** (Taha: aklına geldi, yazdırdı).
- **Genel ilke:** Kaçışlar zorlayıcı olmalı, oyun basit olmamalı.
- **Zıplayan:** gerçekten havada olduğu hissedilmeli (yay çizen yükseliş, küçülen gölge, havadayken silahlarla vurulamaz). Düşeceği yer yerde halkayla işaretli; halka askeri önden nişanlar, son 0.3 sn kilitlenir. İniş alan hasarı + şok dalgası + kamera sarsıntısı. Dash dokunulmazlığı ya da halkadan çıkmak kurtarır. Taslak: can 40, 7 m'de çömelir, hazırlık 0.7 sn, havada 0.9 sn, yükseklik ~3.5 m, iniş yarıçapı 1.5 m, hasar 18, iniş sonrası 1.2 sn toparlanma.
- **Dilci (bağlayan):** Uzakta (~7 m) durur, 0.8 sn hazırlanıp dilini fırlatır. İsabet ederse asker **tam 1 sn bağlı**: hareket edemez, **dash atılamaz** (Taha kesin), silahlar ateş eder; sonra dil otomatik bırakır. Dilci ölürse bağ çözülür. Dash dokunulmazlığı dili ıskalatır. İsabetten sonra ~4 sn bekleme, hasar küçük (6), dalga 4'ten itibaren.
- **Asker animasyonları (Taha: önemli):** bağlanınca **çırpınma** animasyonu, bırakılınca **kollarını açarak bağdan kurtulma** animasyonuna geçer. Bunlar için ortak kütüphanede uygun klip yoksa Blender'da/koddan türetilir (`ZombieClipData` yöntemi gibi).
- Gereken parçalar: oyuncuya "bağlı" durumu (saf kural + test), dil görseli (ince uzayan çizgi ağı), iki yeni zombi modeli (Blender), `FEATURE_ZOMBIE_JUMP`, `FEATURE_ZOMBIE_TONGUE`.

## 2026-11-18 — Dilci görsel ve animasyon geri bildirimi (Taha)

- İlk sürüm beğenilmedi: dil dümdüz çizgi ("berbat"), bağlanma animasyonu çok kötü, kurtulunca koşma animasyonu bozuluyor. Düzeltmeler sonraya bırakıldı (Taha: şimdi yapma); ayrıntı `PROGRESS.md` "Şu an".

## 2026-11-18 — Zıplayan ve dilci onaylandı, kodlandı (Taha)

- Tasarım onayı: kaçışlar zorlayıcı, dilci bağlayınca dash yok, bağ 1 sn, çırpınma ve kollarını açarak kurtulma animasyonları. Zıplayan sıçrama hissi veriyor (yay, yer halkası, iniş şoku). Taha "şimdi başlamak zorunda değilsin" dedi, sonra "kaldığımız yerden devam" ile başlandı.
- Bot dengesi sert: dilci dili ışın gibi anında vurduğu için radyal kaçış işe yaramaz, yalnız yan kaçış ve dash kurtarır (bilinçli). Gerekirse dalga ağırlıkları ya da dilci bekleme süresi gevşetilir.

## 2026-11-18 — Aşama 7.2 koşucu ve tank (Taha)

- İlk tür seti koşucu + tank (Taha onayladı; zıplayan ve sürünen sonra). Koşucu atılışı rastgele değil: hazırlıkta oyuncunun hızına göre önden nişan (`LungeRules`), son 0.22 sn yön kilitli, atılırken sınırlı dönüşle izler; kaçmak kolay olmamalı. Dash ve hız önemli: yeni istatistik `dash_mesafesi`, kart/eşya (`Atılış Bobini`, `Hafif Çizme`), hareket hızı kartları ×1.33, dash bekleme kartları büyüdü. Blender'da ek rötuş serbest.

## 2026-11-17 — Aşama 6.3 istatistikler ve kartlar (Taha)

- **Kart seçimi dalga sonunda** (Brotato gibi), dalga içinde akış kesilmez.
- **İstatistikler:** temel 7 (can, hasar, atış hızı, menzil, hız, zırh, şans) + can yenileme, toplama menzili, dash bekleme süresi.
- **4 nadirlik kademesi** (sıradan / nadir / destansı / efsanevi), renkle ayrılır; seviye ve şansla üst kademe sıklaşır.
- Taha onayladı (işlev okey); **kart ekranının görünümü basit, genel tasarım düzeltmelerinde (9.4) yeniden yapılacak.**
- Claude'un kararları: kart değerleri ve kademe olasılıkları Brotato oranlarından uyarlandı (`CardData`); zırh mevcut düz düşme kuralıyla (`CombatMath.mitigate`); kart başına farklı istatistik; yenileme yok (mağazada olacak).

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
- **Blender işleri penceresiz çalışır** (`blender --background --python <script>`); Taha'nın Blender'ı açıp bağlaması yalnız canlı önizleme istenirse gerekir. (Claude'un önerisi; 5.3.0 ile denendi.) — 2026-11-19: geçersiz, Blender MCP etkileşimli hattın parçası

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
| İçerik hedefi sayıları | 6 ve 11 |
| Arenada engel yoğunluğu | 8.2 |
| Müzik | 8.5 |
| Gamepad, oyun dili | 9.7 |
| Kalıcı ilerleme kapsamı | 10 |
| Kod lisansı (MIT?), Linux deneme ortamı | 12'den önce |

