# Deadzone Last Stand — Oyun Tasarımı

Yaşayan belge. Sayılar başlangıç değeridir; gerçek kaynak `scripts/tuning.gd`. Burada değer değişirse orada da değişir (ya da tersi).

## Özet

Zırhlı ve kasklı bir asker, kapalı bir şehir kavşağında dalga dalga gelen zombilere karşı hayatta kalır. Oyuncu yalnız hareket eder ve dash atar; silahlar en yakın hedefe kendisi nişan alıp ateş eder. Dalga aralarında mağaza ve seviye kartlarıyla kurulum (build) güçlenir.

## Kontroller

| Tuş | İş |
| --- | --- |
| WASD / ok tuşları | Hareket (XZ düzleminde, kameraya göre) |
| Space | Dash: hareket yönüne (duruyorsa baktığı yöne) takla; süresince hasar almaz ve zombilerin içinden geçer |
| F11 / Alt+Enter | Tam ekran ↔ pencere (oyun tam ekran açılır) |
| R | Öldükten sonra yeniden başlat |
| Esc | Duraklat (Aşama 9.1) |
| F3 | Debug paneli (yalnız debug yapı) |

## Çekirdek döngü (Aşama 1)

- **Asker:** sabit hızla yürür, ivmelenme ve sürtünme ile yumuşak durur. Canı biter → ölüm ekranı → R.
- **Zombi:** askere doğru yürür, birbirini iter (üst üste binmez). Askerin içine girmez; değince temas hasarı verir. Vurulan asker kısa süre dokunulmaz olur (yanıp söner), böylece kalabalıkta hasar okunur kalır.
- **Silah:** menzil içindeki en yakın zombiye otomatik ateş eder. Mermi düz gider, ilk değdiği zombiye hasar verir.
- **Doğma:** zombiler arenanın kenarından, kameranın dışından gelir; sayı zamanla artar, üst sınır kalite profilinden.
- **Kamera:** sabit açılı (yaklaşık 55° eğik), askeri yumuşakça izler.

### Başlangıç değerleri (Aşama 1, ilk ayar)

| Değer | Başlangıç |
| --- | --- |
| Asker hızı | 6 m/sn |
| Asker canı | 100 |
| Zombi hızı | 2.6 m/sn |
| Zombi canı | 30 |
| Zombi temas hasarı | 10 |
| Vurulunca dokunulmazlık | 0.5 sn |
| Doğma aralığı | 1.0 sn → en az 0.12 sn; her 15 sn'de bir seferde +1 zombi |
| Silah hasarı | 10 |
| Atış aralığı | 0.35 sn |
| Menzil | 12 m |
| Mermi hızı | 30 m/sn |
| Arena | 60 × 60 m |

## His ve görünüm (Aşama 3–5, karar: 2026-11-16)

- **Anlayış:** gerçekçilik değil, Brotato / Vampire Survivors okunaklılığı. Fizik elle yazılır; ragdoll yok.
- **Silahlar:** 6 silahın hepsi askerin etrafında süzülür; her biri kendi hedefine döner ve ateşte geri teper. Asker hareket yönüne bakar.
- **Zombi tepkisi:** vurulunca vuruş yönünde geriye itilir (silahın `knockback` değeri / zombinin `weight` değeri; tabanca ≈ 0.4 m) ve kısa süre sendeler (yürüyen: 0.22 sn); sendeleme saldırı hazırlığını bozar.
- **Zombi saldırısı:** askere yaklaşınca durur, 0.5 sn hazırlanır (yönü kilitlenir), sonra vurur; asker o an erişimin (temas + 0.9 m) dışındaysa ıskalar. Ardından 0.6 sn toparlanır. "Değince hasar" `Tuning.FEATURE_ZOMBIE_WINDUP_ATTACK = false` ile geri açılır; hangisinin kalacağını Taha oynayarak seçer (4.3).
- **Zombi doğması ve ölümü:** yerden doğrularak doğar (0.9 sn). Ölünce vuruş yönüne düşer ve biraz kayar, 1.5 sn yerde kalır, 0.5 sn'de solarak silinir; ceset hedef alınmaz ve çarpışmaz.
- **Ölüm:** vuruş yönüne doğru ölüm animasyonu, ardından solarak silinme.
- **Silahlar ve enerji çemberi:** askerin zırhı çevresine turuncu bir enerji çemberi yansıtır; en çok 6 silah bu çemberin üstünde, askere sabit yuvalarda süzülür. Her silah kendi en yakın hedefine döner ve kendi namlusundan ateş eder. İleride yakın dövüş silahları (ışın kılıcı vb.) da çemberde durur (7.1).
- **Zombi türleri:** her tür oyuncuya ayrı bir karar çıkarır, siluet ve hareketle uzaktan ayırt edilir ve kendi içinde çok sayıda görünüme sahiptir (gövde çeşidi × renk şeması). Hedef liste (Aşama 7.2–7.3; Taha, 2026-11-16):

  | Tür | Davranış | Oyuncuya çıkardığı karar |
  |---|---|---|
  | Sürü zombisi (yürüyen) | Yavaş, yakın dövüş; kalabalık baskısını oluşturur | Sürekli hareket et, sürüden sıyrıl |
  | Koşucu | Kısa süre hızlanıp atılır; öncesinde belirgin hazırlık animasyonu | Zamanında dash at ya da rotasını boz |
  | Zıplayan | Kısa hazırlıktan sonra askerin üstüne atlar; düşeceği yer belli | İşareti gör, alandan çık |
  | Sürünen | Alçak, kalabalıkta zor fark edilir | Yere de bak; ayak altını temizle |
  | Tank | Yavaş, çok dayanıklı, ağır vurur | Ateşi ona yoğunlaştır ya da uzak dur |
  | Zırhlı | Önden dayanıklı; yandan ve arkadan daha çok hasar alır | Yalnız kaçma, açını değiştir |
  | Çığlıkçı | Uzakta durur; aralıklarla yeni zombi çağıran ses dalgası çıkarır | Kalabalık büyümeden bul, öncelikli hedef yap |
  | Tükürücü | Yerde bir süre kalan asit/çamur atar; alanı geçici kapatır | Güvenli koridora yönel, sıkışmadan rota değiştir |
  | Taş fırlatan | Uzaktan görülebilir, kaçılabilir atış yapar | Atışı gör, yana çekil |
  | Patlayıcı | Yaklaşınca kısa uyarı verir ve patlar; yakındaki zombilere de zarar verir | Mesafeyi koru, onu sürünün yanına çekip fırsata çevir |
- **Uzaktan saldıran zombiler:** bazı türler asit tükürür ya da taş gibi şeyler fırlatır. Atışlar görülebilir ve kaçılabilir olmalı (yavaşça gelen mermi ya da düşeceği yeri gösteren işaret). Aşama 7.3.
- **Asker animasyonları:** koşu `ual1/Sprint`, dash `ual1/Roll` (takla).
- **Patlama:** alan hasarı çevredeki zombilere de işler (patlayan zombi dahil).
- **Kan:** stilize; sıçrama parçacıkları ve yerde bir süre kalıp solan lekeler. Uzuv kopması yok.
- **Sürü:** ekranda 150–300 zombi, hepsi iskeletli ve animasyonlu.
- **Modeller:** asker(ler), boss ve özel zombiler Tripo'dan (Taha); sıradan zombiler, silahlar ve arena Blender'dan (Claude). Animasyonlar ücretsiz, lisansı sorunsuz hazır kütüphaneden + Blender ve kod cilası.

## Tur yapısı (Aşama 6, taslak)

- **Dalgalar (6.1):** tur 5 dalga, süreler 20 / 30 / 40 / 50 / 60 sn (~3.5 dk; kesin sayılar Aşama 11'de). Satırlar `WaveData`'da: doğma aralığı ve grup boyu dalga içinde doğrusal artar, aynı anda en çok zombi (60 → 350) kalite profilinin sınırıyla ayrıca kırpılır, tür karışımı ağırlıkla.
- Dalga süresi bitince doğma durur, kalan zombiler 0.8 sn içinde devrilip solar (öldürme sayılmaz, ileride düşen de bırakmaz), "DALGA TEMİZLENDİ", 3 sn ara, sıradaki dalga. Mağaza gelince (6.5) ara mağaza ekranı olur.
- Son dalga temizlenince "HAYATTA KALDIN" (R ile yeniden); ölünce "ÖLDÜN". İkisinde de dalga, süre, öldürme.
- Zombiler ekranın hemen dışında doğar (görünür alan kamera açısından hesaplanır, 3 m pay); duvar yüzünden olmazsa arena kenarı. `FEATURE_SPAWN_OFFSCREEN`.
- `FEATURE_WAVES = false`: Aşama 1'deki sonsuz, giderek hızlanan doğma.
- Ölen zombi XP ve para bırakır (6.2).
- Seviye atlayınca 3 karttan biri (istatistik artışı).
- 6 silah yuvası; aynı silah + aynı kademe iki tane → bir üst kademe (en çok 4).
- Temel istatistikler: can, hasar, atış hızı, menzil, hız, zırh, şans.

## Kalite profilleri

`low / medium / high`. Zombi üst sınırı, gölge, MSAA (ileride parçacık yoğunluğu) `scripts/data/quality_profiles.gd`'den okunur. Platform yalnız varsayılan profili seçer (masaüstü: high).

| Profil | Zombi üst sınırı | Gölge | MSAA |
| --- | --- | --- | --- |
| low | 150 | yok | yok |
| medium | 250 | var | 2x |
| high | 350 | var | 4x |

Aşama 2.5 ölçümü: animasyonlu, iskeletli mankenle 60 FPS tavanı ~500; 300'de ~120 FPS. Sınırlar efektlere pay bırakılarak kondu; karışık türlerle Aşama 7.5'te yeniden ölçülür.

## Açık sorular

`DECISIONS.md` içindeki "Açık kararlar" tablosu geçerli.
