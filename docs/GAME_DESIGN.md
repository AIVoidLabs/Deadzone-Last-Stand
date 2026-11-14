# Deadzone Last Stand — Oyun Tasarımı

Yaşayan belge. Sayılar başlangıç değeridir; gerçek kaynak `scripts/tuning.gd`. Burada değer değişirse orada da değişir (ya da tersi).

## Özet

Zırhlı ve kasklı bir asker, kapalı bir şehir kavşağında dalga dalga gelen zombilere karşı hayatta kalır. Oyuncu yalnız hareket eder ve dash atar; silahlar en yakın hedefe kendisi nişan alıp ateş eder. Dalga aralarında mağaza ve seviye kartlarıyla kurulum (build) güçlenir.

## Kontroller

| Tuş | İş |
| --- | --- |
| WASD / ok tuşları | Hareket (XZ düzleminde, kameraya göre) |
| Space | Dash (Aşama 3) |
| R | Öldükten sonra yeniden başlat |
| Esc | Duraklat (Aşama 7) |
| F3 | Debug paneli (yalnız debug yapı) |

## Çekirdek döngü (Aşama 1)

- **Asker:** sabit hızla yürür, ivmelenme ve sürtünme ile yumuşak durur. Canı biter → ölüm ekranı → R.
- **Zombi:** askere doğru yürür, birbirini iter (üst üste binmez). Askere değince bekleme süreli temas hasarı verir.
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
| Zombi temas hasarı | 10, 0.8 sn'de bir |
| Silah hasarı | 10 |
| Atış aralığı | 0.35 sn |
| Menzil | 12 m |
| Mermi hızı | 30 m/sn |
| Arena | 60 × 60 m |

## Tur yapısı (Aşama 2, taslak)

- Dalga süresi 30–90 sn; dalga bitince mağaza. Ölen zombi XP ve para bırakır.
- Seviye atlayınca 3 karttan biri (istatistik artışı).
- 6 silah yuvası; aynı silah + aynı kademe iki tane → bir üst kademe (en çok 4).
- Temel istatistikler: can, hasar, atış hızı, menzil, hız, zırh, şans.

## Kalite profilleri

`low / medium / high`. Zombi üst sınırı, gölge, parçacık yoğunluğu bu profillerden okunur. Platform yalnız varsayılan profili seçer.

## Açık sorular

`CLAUDE.md` bölüm 7'deki liste geçerli.
