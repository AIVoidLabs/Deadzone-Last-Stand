# İlerleme

Her alt aşama bitince ve her oturumun sonunda güncellenir. Yeni oturum buradan devam eder.
Plan: `ROADMAP.md` · Kararlar: `DECISIONS.md` · Teknik yapı: `TECH.md`

## Şu an

Oturum 6 (2026-11-18). **Aşama 7.1 başladı: yakın dövüş silahları kod olarak bitti** (bıçak, katana, ışın kılıcı, ateşli kılıç); Taha oynayıp yorum yapacak. Aşama 6 onayı hâlâ bekliyor. 145 test, commit yapıldı, push yok.

- **7.1 kararları (Taha, 2026-11-18):** yakın dövüş ilk iş. Silahlar: bıçak (tekli dürtme), katana (yay savurma), ışın kılıcı (geniş savurma + yanma), **ateşli kılıç** (yanma, Taha ekledi); SMG, uzay silahları (plazma tüfeği = delip geçen, graviton topu = ittirme; sonra istenirse yenileri), bomba atar (alan hasarı). Yakın dövüş de 6 yuvadan birini kullanır, birleşme kuralları aynı. Zor erişim: 10–15 dalgalık oyuna göre silahlar dalga kilidiyle (`min_wave`) ve nadirlikle (`weight`) mağazaya çıkar, fiyatlar yüksek.
- **Sırada (7.1'in kalanı):** SMG, plazma tüfeği, graviton topu, bomba atar; sonra 7.2.
- **Yakın dövüş nasıl çalışır:** `WeaponData` satırında `behavior: &"melee"`; `max_range` = menzil, `melee_arc_deg` = yay (0 = tekli dürtme), `burn_dps/burn_time` = yanma. `MeleeRules` (saf: yay + yanma sayacı, 9 test), `EnemyManager.query_arc/ignite`, görüntü `WeaponVisual` (kabzadan savurma, öne atılma) + `MeleeSlash` (kesik izi, `FEATURE_MELEE_SLASH_FX`), yanan zombi turuncu parlar (`flash_lit` `burn`, `FEATURE_BURN`). Modeller `build_weapons.py` (kökeni kabza), sesler `gen_sfx.py` `swing_*`. Mağaza: `WeaponData.shop_pool(wave)` + ağırlıklı çekiliş (`ShopRules`).
- **Denge notu:** yeni silahların sayıları ilk tahmin; bot 3 turda kazandı (bıçak alındı). Gerçek denge Taha'nın oynayışıyla.
- **Yeni oturum başlangıcı:** ortam kontrolü → Taha'nın yakın dövüş yorumu → 7.1'in kalanı (SMG, uzay silahları, bomba atar).
- **Aşama 6'dan miras:** kademe değerleri `WeaponData.TIERS`; mağaza `ItemData` / `ShopRules` / `ShopFlow`; dalga tablosu `WaveData` (üst sınırlar 60/90/120/180/260); yeni zombi türü eklenince `drop_value` ve `WaveData.mix` satırı gerekir. Denge ölçümü: `tools/autoplay_runs.ps1`.
- **Tasarım borcu (Aşama 9):** kart ekranı, mağaza, HUD, ölüm/kazanma ekranları prototip → 9.3–9.5.
- **Açık küçük konular:** dalga arasında iyileşme yok; kristal toplama sesi ve XP çubuğu rengi yorum almadı; oyun 10–15 dalgaya uzayacak (11.2'de WaveData genişler).
- **Taha oyunu Godot editöründen (Play) açıyor.** Gömülü pencerede tam ekran yok, F tuşları ulaşmayabilir; "Embed Game on Next Play" kapatılır. Yedekler Ctrl+3 … Ctrl+9. F7 artık sırayla pompalı, bıçak, katana, ışın kılıcı, ateşli kılıç ekler; `--tiers=knife:1,katana:2` ile görüntü.

## Ana aşama durumu

| # | Aşama | Durum |
|---|---|---|
| 0 | Kurulum ve iskelet | ✔ bitti |
| 1 | Kutu prototip | ✔ bitti (his onayı 5.7'de verildi) |
| 2 | Model ve animasyon hattı | ✔ bitti (2026-11-16) |
| 3 | Dikey dilim: asker | ✔ bitti (2026-11-16) |
| 4 | Dikey dilim: zombi | ✔ bitti (2026-11-16) |
| 5 | Dikey dilim: silah ve vuruş hissi | ✔ bitti (2026-11-17, dikey dilim onaylandı) |
| 6 | Tur döngüsü | ✔ kod bitti 2026-11-18 (Taha'nın oynayıp onayı bekleniyor: 6.4–6.6) |
| 7 | Silah ve zombi çeşitliliği | 7.1 başladı (yakın dövüş bitti) |
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
- [x] 5.1 Süzülen silah yuvaları — kod bitti 2026-11-16 (`WeaponRig` + `WeaponSlots` 5 test; 6 yuva çemberde, her silah kendi en yakın hedefine döner ve kendi namlusundan ateş eder, geri tepme + salınım; `build_weapons.py`: tabanca ve pompalı). Taha: silah koşarken geride kalıyor/içe giriyor → yuvalar askere sabitlendi; enerji çemberi eklendi (`EnergyRing`, `FEATURE_ENERGY_RING`). Taha: "harika olmuş"
- [x] 5.2 Atış görseli — kod bitti 2026-11-16 (mermi izi: parlak baş, sönen kuyruk; namlu parlaması: kameraya dönük yıldız + kısa nokta ışığı; isabet kıvılcımı: havuzlu, hız yönünde çizgi, sayısı kalite profilinden). Taha itiraz etmedi
- [x] 5.3 Vuruş geri bildirimi — kod bitti 2026-11-16 (`BloodFx`: havuzlu kan sıçraması, ölümde 3 kat; yerde solan lekeler tek MultiMesh, en çok 48/128/256; `DamageNumbers`: yükselip sönen sayılar, öldürende turuncu ve büyük; `HitStop` + 5 test: öldürmede 45 ms yavaşlama, arada 0.3 sn bekleme, `GameFlow.hit_stop`; öldürmede küçük kamera sarsıntısı). Taha: kan ve sayılar iyi; duraksama kalabalıkta takılma gibi hissettirdi → kapatıldı (`FEATURE_HIT_STOP = false`)
- [x] 5.4 Asker vurulunca — 2026-11-17 (`41b3ce8`, `9767e2a`). Ekran kenarı kızarması, can %35'in altındayken nabız; sarsıntı ve yanıp sönme zaten vardı. Taha: itilme kötü → kapatıldı (`FEATURE_PLAYER_KNOCKBACK = false`); kızarmayı onayladı
- [x] 5.5 İlk sesler — 2026-11-17 (`de2a620`, `510b83d`; temel sesler, 8.4'te yeniden ele alınır) (`tools/sfx/gen_sfx.py`: Python standart kütüphanesiyle sentez, sabit tohum, 6 ses 13 dosya; `Audio` autoload: 32 oynatıcılık havuz, "SFX" veri yolu; `SoundData` tablosu: düzey, perde payı, aynı anda en çok kopya, çalışlar arası bekleme; `VoiceLimiter` + `Stride` 10 test; adımlar koşu klibinin temposundan). Taha ilk tur: atış iyi, isabet sesi kapatıldı → sürü homurtusu eklendi (`HordeGroan` + 3 test), takla kısıldı + alet çantası tıngırtısı; zombi ölüm sesi de kapatıldı. Taha: "şimdilik böyle ilerleyelim"
- [x] 5.6 İkinci silah: pompalı — 2026-11-17 (`30532d3`; Taha: "güzel") (`shotgun` satırı: 6 saçma × 7 hasar, 30° yelpaze + rastgele sapma, 7 m, 1.1 sn; saçma başına itme toplanır, yakından ~1.7 m savurur (tabanca ~0.4 m); büyük namlu parlaması, atışta hafif kamera sarsıntısı `FEATURE_FIRE_SHAKE`; kendi sesi: tok patlama + pompa çekme; `Spread` + 3 test; F7 sırayla pompalı / tabanca ekler)
- [x] 5.7 Dilim cilası ve **dikey dilim onayı** — 2026-11-17, Taha onayladı ("her şey okey"); zombi saldırısı hazırlıklı vuruş olarak kaldı. Cila (ışık ön ayarları `LightingData`, Taha "dusk" seçti; asker renk tonu `PLAYER_ALBEDO_TINT`; yumuşak dash tozu; kapanışta ses sızıntısı düzeltildi). 258 zombi + 4 silah, akşam ışığı: 135 FPS

### 6 — Tur döngüsü
- [x] 6.1 Dalgalar — 2026-11-17 (`2cc7038`; Taha yorum yapmadan "devam" dedi) (`WaveData` 5 dalga, `WaveRun` + 7 test, `SpawnDirector`, ekran dışı doğma `SpawnRules` + 5 test, dalga sayacı ve ortadaki yazılar `WaveBanner`, "HAYATTA KALDIN" ekranı, F8 dalgayı bitir). 97 test
- [x] 6.2 Düşenler — 2026-11-17 (`3120d29`, `64c3908`; Taha: "şu an okey") (`Pickups`: tek MultiMesh, dönme shader'da; `PickupRules` + `RunLoot` 8 test; sekerek düşme, 3 m çekim, dalga sonunda hepsi; HUD XP çubuğu + seviye + kristal sayısı; toplama sesi `pickup_1..3`; `FEATURE_PICKUPS`). 105 test
- [x] 6.3 İstatistikler ve kartlar — 2026-11-17 (`677a86f`; Taha: işlev onaylı, kart görünümü basit → 9.4'te yeniden tasarlanacak) (`StatData` 10 istatistik, `CardData` 4 kademe, `PlayerStats` + `CardRules` 11 test; `LevelUpFlow` dalga arasında kristaller toplanınca açılır, `CardScreen` 3 kart + güncel artışlar; `GameFlow.open_menu`; asker/silah/kristal değerleri istatistikten; F9 +seviye; `FEATURE_LEVEL_CARDS`). 116 test
- [x] 6.4 Silah yuvaları ve birleştirme — kod bitti 2026-11-18, Taha testi bekliyor (`WeaponMerge` + 9 test: yeni silah kademe 1, aynı silah + aynı kademe kendiliğinden birleşir, zincirleme, en çok 4; 6/6 doluyken birleşemeyen reddedilir. `WeaponData.TIERS` kademe sütunu: hasar ×1/1.5/2.2/3.2, atış hızı ×1/1.12/1.25/1.4. Görünüm: gri → yeşil → mavi → altın renk + ışıma + hafif büyüme. F7 ile dene: ilk F7 pompalı, ikinci tabanca → başlangıç tabancasıyla birleşir; `--tiers=pistol:1,shotgun:3` ile görüntü; `FEATURE_WEAPON_MERGE`). Birleşme animasyonu (Taha isteği, 2026-11-18): silah küçükten yaylanarak oturur + kademe renginde parlar (`WeaponVisual`), genişleyen halka + kıvılcım (`MergeBurst`, sayı kalite profilinden); `FEATURE_MERGE_FX`, `MERGE_FX_TIME`; `--capture-merge=S` ile görüntü. 125 test
- [x] 6.5 Mağaza ve eşyalar — kod bitti 2026-11-18, Taha testi bekliyor. Taha'nın kararları: raf 4 ürün karışık (silah olasılığı %30), yenileme 5 kristal + her seferinde +2 (dalga başında sıfırlanır), kilit var, 10 eşya (artı + eksi bedel, yığılır), silah alınır (6.4 kurallarıyla birleşir), satılır (kademe bedelinin yarısı, son silah satılamaz). Fiyatlar dalga başına +%15. (`ItemData` 10 eşya, `ShopRules` + 9 test, `ShopFlow` dalga arası kart ekranından sonra açılır ve oyunu durdurur, `ShopScreen` sade görünüm [1–4 al, R yenile, Enter sonraki dalga]; mağaza açılana kadar ara süresi akmaz `SpawnDirector.hold_break`; "sonraki dalga" arayı bitirir; `StatData` eksi değer gösterimi; `FEATURE_SHOP`). Görüntüler: `--crystals=N --capture-wave-end=S --capture-pick [--capture-pick-key=R|Enter]`. 134 test. Fiyat/gelir dengesi 6.6'da
- [x] 6.6 Tam tur — kod ve ilk denge bitti 2026-11-18, Taha'nın oynayıp yorumu bekliyor. Tam tur botu (`Autoplay`, `tools/autoplay_runs.ps1`: ~10 sn'de 5 dalga) ölçüm aracı oldu. Ölçümle bulunan **hata:** temizlik sırasında düşen kristal yerde kalıp mağaza ve kartları bekletiyordu → dalga sonunda düşen her kristal de çekilir (`Pickups.pull_all`). **Denge değişiklikleri:** zombi kristali 1 → 3; dalga 1 hafifledi (tek zombi, aralık 1.1→0.8), dalga 2–5 daha yumuşak tırmanış ve üst sınırlar 60/90/120/180/260 (`WaveData`); mağazada silah olasılığı %30 → %40. Bot sonucu (6 tur): 4 kazandı, 2 dalga 4–5'te öldü; 3–4 silah ve K2 birleşmeleri dalga 4–5'te görülüyor; dalga başına kristal ~45 → ~650. Bot insan değil: gerçek denge Taha'nın oynayışıyla ayarlanır

### 7 — Silah ve zombi çeşitliliği
- [ ] 7.1 Silah davranış seti — yakın dövüş (bıçak, katana, ışın kılıcı, ateşli kılıç + yanma) kod bitti 2026-11-18, Taha testi bekliyor; SMG, plazma, graviton, bomba atar kaldı
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

- Silah gücü düşük: zombi itilince tabanca başka hedefe dönüyor, hasar sürüye dağılıyor → 5.6 (pompalı) ve 6.6 dengesi.
- Zombi doğması (yerden kalkma) kamera dışında oluyor, oyunda pek görünmüyor → 6.1 dalgalarda doğma yerleri.
- Silahlar 1.1 m'de, sürüde zombi başlarının arasına gömülebiliyor; Taha şimdilik itiraz etmedi.
- Kapalı ama kodu duran özellikler: öldürmede duraksama (`FEATURE_HIT_STOP`, kalabalıkta takılma hissi), askerin vurulunca itilmesi (`FEATURE_PLAYER_KNOCKBACK`, "alakasız itiliyoruz"). Yeniden açmadan önce Taha'ya sor.
- Sesler: adım sesi zemine duyarlı olacak (8.1 zemin türleri, 8.4 ses seti); her silahın kendi atış sesi (5.6 pompalı, 7.1 diğerleri). Zombi isabet sesi kapalı (`FEATURE_SFX_HIT`).
- Hasar sayıları kalabalıkta çok; Taha şimdilik "iyi" dedi. 9.3 HUD'da ayarla birlikte gözden geçirilebilir.
- İleride (Taha'nın fikirleri): enerji çemberinde yakın dövüş silahları, ışın kılıcı (7.1); zombi türleri tablosu `GAME_DESIGN.md` (7.2–7.3).

## Taha'nın geri bildirimi

- 2026-11-16 (5.x): silah sola koşarken geride kalıyor, sağa koşarken gövdeye giriyor → yuvalar askere sabitlendi; zırhın enerji çemberi fikri (eklendi), "harika olmuş". Kanlar iyi; öldürmede duraksama takılma gibi → kapatıldı. Vurulunca itilme "çok kötü" → kapatıldı. Editörden oynarken F tuşları çalışmadı → gömülü pencere (yukarıda).
- 2026-11-16 (4.x): zombi tarzı ve renkleri beğenildi, çok daha fazla çeşit ve koyu tonlar istendi (160 görünüm yapıldı); yeni türler: sürünen, koşan, zıplayan; Codex'le konuşup getirdiği tür listesi (çığlıkçı, zırhlı, tükürücü, patlayıcı) plana işlendi.
- 2026-11-16 (3.x): Tripo lisansı sorunsuz; dash toz izi dandik; ölüm animasyonu oynamıyordu (düzeltildi).
- 2026-11-16: Aşama 1 hissi zayıf: vuruş hissi yok, hareket ve koşu cansız, zombiler tehditsiz; "animasyon ve modellerle düzelebilir". Belgeler eksik ve ilerleme rastgele hissettiriyor → ana plan yeniden yazıldı (`ROADMAP.md`).
- 2026-11-15: "Pencere modunda bile küçük duruyor, oyun tam ekran olmalı." → tam ekran açılış + F11/Alt+Enter (`Tuning.FEATURE_START_FULLSCREEN`).

## Oturum günlüğü

### 2026-11-18 — Oturum 6
- 7.1 kararları alındı (yukarıda "Şu an"). Yakın dövüş silahları yapıldı: `MeleeRules` + 9 test, `query_arc`/`ignite`, kesik izi, yanma görseli, 4 model (Blender, headless betik), `swing_*` sesleri, mağaza dalga kilidi + ağırlık (2 test). 145 test. Bot turu 3/3 kazandı.
- Taha: kesik izi "beyaz koni gibi yoğun" → rüzgar tarzına çevrildi: dış kenarda incelen hilal, ince kopuk rüzgar çizgileri, yumuşak uçlar, sönerken dağılma; bıçakta dışa ilerleyen ince çizgi (`melee_slash.gdshader`, `MeleeSlash`). Taha'nın onayı bekleniyor.
- Not: Blender MCP açıkken betikte `read_factory_settings` çalıştırmak MCP bağlantısını koparır; modeller headless (`blender --background --python tools/blender/build_weapons.py`) üretilir.

### 2026-11-18 — Oturum 5
- **Oturum sonu özeti:** Aşama 6 kod olarak bitti (6.4 silah kademeleri ve birleşme, 6.5 mağaza ve eşyalar, 6.6 tam tur botu ve ilk denge). 134 test. Commit'ler: `2ae8783` (6.6), `c50fe1f` (6.5), `bb02b95` (birleşme animasyonu), `07e9f8d` (6.4). Taha onayı bekleniyor; Aşama 7'yi temiz oturumda başlatacak.
- 6.4: Taha'nın kararları: öneriler kabul, kademe görünümü renk + model güncellemesi; sonradan birleşme animasyonu istedi (yaylanarak oturma, parlama, halka, kıvılcım).
- 6.5: Taha'nın kararları: 4 ürün karışık raf, artan fiyatlı yenileme + kilit, 10 eşya (artı + eksi bedel), silah alınır / birleşir / satılır. Mağaza dalga arasında kart ekranından sonra açılır ve oyunu durdurur.
- 6.6: Tam tur botu (`Autoplay`) yazıldı; kristalin yerde kalıp mağazayı kilitlediği hata bulundu ve düzeltildi; zombi kristali 3, dalgalar yumuşatıldı, mağazada silah olasılığı %40.
- Kapanışta bir kez "2 nesne sızdı" uyarısı görüldü, tekrarlanmadı; ayrıca doğrulanmadı (eski ses sızıntısı türünden olabilir).

### 2026-11-17 — Oturum 4
- **Oturum sonu özeti:** dikey dilim onaylandı, Aşama 5 kapandı; 6.1 dalgalar, 6.2 kristaller, 6.3 istatistikler ve kartlar bitti (Taha onayladı). 116 test. Commit'ler: `677a86f` (6.3), `64c3908` / `3120d29` (6.2), `2cc7038` (6.1), `3b51589` (5.7). Sıradaki 6.4; sorulacaklar "Şu an" bölümünde.
- Ortam kontrolü temiz. Taha dikey dilimi onayladı → 5.7 ve Aşama 5 kapandı (Aşama 1 his onayı dahil).
- 6.1: Taha'nın kararları: 5 dalga 20→60 sn, otomatik 3 sn ara, ekran dışı doğma. Doğma `EnemyManager`'dan `SpawnDirector`'a taşındı (sonsuz mod `FEATURE_WAVES = false` ile duruyor, denendi). Kazanınca 1.5 sn bekleme (`VICTORY_DELAY`), devrilen zombiler donmasın diye. 97 test geçiyor.
- 6.2: Taha'nın kararları: tek tür düşen (kristal = XP + para), yalnız yakındakiler çekilir, dönen turkuaz kristal. İlk görüntüde kristal ışımadan beyaza kaçıyordu → ışıma azaltıldı, renk doygunlaştı. Taha: "çok büyük ve çok basit, küçük ve beyazımsı olsun" → boy 0.2 → 0.11, beyazımsı buz mavisi, altı köşeli taş kesimi (üst ucu uzun) (`64c3908`). Debug paneli XP çubuğunun altına kaydı.
- 6.3: Taha'nın kararları: kartlar dalga sonunda, 10 istatistik, 4 kademe. İlk görüntüde kartta istatistik iki kez yazıyordu (ad + "+5% menzil") → büyük satır yalnız değer. Capture'a `--levels`, `--capture-pick`; debug paneline kart artışları satırı.
- Not: PowerShell 5.1'de `Get-Content | Set-Content` UTF-8 dosyayı bozuyor (Türkçe harfler); dosya düzenlemesini Python ya da Edit ile yap.

### 2026-11-17 — Oturum 3
- **Oturum sonu özeti:** 5.4–5.6 kapandı, 5.7 cilası bitti (onay bekliyor). Son commit'ler: `0b10609` (akşam ışığı), `10eb870` (ışık ön ayarları, asker tonu, dash tozu), `99b42fb` (ses sızıntısı), `30532d3` (pompalı), `510b83d` / `cbdc768` (5.5). 85 test geçiyor. Bu oturumun sonunda model Sonnet 5.5'e alındı (varsayılan).
- Ortam kontrolü temiz. Taha 5.4 kızarmayı onayladı; F tuşları gömme kapalıyken sorunsuz.
- 5.5 ilk tur geri bildirimi: isabet sesi kapandı, sürü homurtusu (5 çeşit, yoğunluğa göre sıklık ve düzey), takla kısıldı + zırh/alet çantası tıngırtısı (3 çeşit); zombi ölüm sesi kapandı, 5.5 temel seslerle kapandı.
- 5.6: pompalı (`Spread`, silah tablosunda varsayılan alanlar `DEFAULTS`, `add_debug_weapon`). 85 test. Kapanışta çalan seslerin sızıntı uyarısı bulundu ve düzeltildi (`99b42fb`).
- 5.7: ışık galerisi (`make_gallery.gd`), Taha "dusk" seçti; asker renk tonu; yumuşak dash tozu.
- 5.5: ses sentezi (`tools/sfx/gen_sfx.py`), `Audio` havuzu, `SoundData`, `VoiceLimiter`, `Stride`, `Footsteps`; F3 panelinde çalan ses sayısı. 79 test geçiyor. 150 zombi + 6 silahta 9 sn'de 193 ses, aynı anda en çok 9, 144 FPS.

### 2026-11-16 — Oturum 2
- **Oturum sonu özeti:** Aşama 3 ve 4 kapandı; Aşama 5'te 5.1–5.3 bitti, 5.4 yorum bekliyor. 69 GUT testi geçiyor. Bu oturumun son commit'leri: `9767e2a` (itilme kapalı, gömülü pencerede tam ekran denenmiyor), `bc18079`, `41b3ce8` (5.4), `c42e2c3` (duraksama kapalı), `996a2d7` (Ctrl yedek tuşlar), `a6facff` (5.3), `571c76e` (5.2), `57d6d23` ve `8b3ab3c` (5.1). Ölçüm: 234 zombi + 6 silah + tüm efektler, yüksek profil 128 FPS.
- 5.2–5.4: mermi izi, namlu parlaması + ışık, isabet kıvılcımı; kan sıçraması, yerde solan lekeler (MultiMesh), hasar sayıları, `HitStop` (kapalı), öldürmede sarsıntı; ekran kenarı kızarması (`HurtVignette`), askerin itilmesi (kapalı). Debug tuşlarına Ctrl+3…7 yedekleri.
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
