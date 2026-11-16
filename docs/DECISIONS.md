# Deadzone Last Stand — Kararlar

Tarihli kararlar ve açık kararlar. Yeni karar en üste eklenir; açık karar verilince "Açık kararlar"dan çıkarılıp tarihli bölüme yazılır.

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
| Asker konsepti ve oranları | 3.1 |
| Zombi saldırısı: hazırlıklı vuruş mu, değince hasar mı | 4.3 (oynayarak) |
| İçerik hedefi sayıları | 6 ve 11 |
| Arenada engel yoğunluğu | 8.2 |
| Müzik | 8.5 |
| Gamepad, oyun dili | 9.7 |
| Kalıcı ilerleme kapsamı | 10 |
| Kod lisansı (MIT?), Linux deneme ortamı | 12'den önce |

