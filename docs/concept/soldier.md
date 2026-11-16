# Asker konsepti (Aşama 3.1)

Karar: 2026-11-16, Taha.

| Konu | Karar |
|---|---|
| Oranlar | Stilize ve iri: biraz büyük kafa ve kask, geniş omuz, kalın kol ve bacak, yaklaşık 5–6 kafa boyu |
| Tarz | Ağır zırhlı, yakın gelecek: tam kapalı kask, kalın zırh plakaları, hafif bilimkurgu havası |
| Renk | Koyu lacivert zırh, turuncu vizör ve vurgu şeritleri |

## Tripo için model koşulları

Bunlar rig ve animasyonun düzgün oturması için şart:

- **A-poz:** kollar gövdeden yaklaşık 45° açık ve düz, bacaklar hafif aralık, dik duruş.
- **Tek parça, tek karakter;** zemin, kaide ya da ikinci nesne yok.
- **Silahsız, eller boş.** Silahlar oyunda askerin etrafında süzülüyor.
- **Eller kapalı eldiven** (parmaklar bitişik ya da yumruk). İskelette parmak kemiği yok.
- **Sarkan parça yok:** pelerin, uzun kayış, anten, büyük sırt çantası olmasın.
- **Simetrik,** yüz tamamen kaskın arkasında.
- Kollar gövdeye, bacaklar birbirine değmesin (ağırlık boyama için).

## Tripo'ya yazılacak metin

```
Stylized low-poly game character, heavy armored near-future soldier, full body, standing in A-pose with arms straight and held 45 degrees away from the body, legs slightly apart, facing forward, symmetrical. Chunky heroic proportions: slightly oversized helmet, broad shoulders, thick arms and legs, about 5.5 heads tall. Fully enclosed helmet with a glowing orange visor, thick dark navy blue armor plates on chest, shoulders, forearms and shins, orange accent stripes, dark grey undersuit, heavy boots, closed armored gloves with fingers together. Empty hands, no weapon, no backpack, no cape, no loose straps. Clean flat colors, simple shapes, hard edges, single character, no base, no ground.
```

Görselden üreteceksen aynı koşullar geçerli: önden, tam boy, A-poz, düz arka plan.

## Tripo'da adımlar (Taha)

1. Metinden (ya da görselden) modeli üret; doku açık olsun.
2. Sonucu döndürüp bak: A-poz mu, eller boş mu, kollar gövdeden ayrık mı? Değilse yeniden üret.
3. **Tripo'nun kendi rig / animasyon özelliğini kullanma;** iskeleti Claude bağlayacak.
4. **GLB** olarak dışa aktar (dokular dahil).
5. Dosyayı `assets/models/source/soldier/` klasörüne koy (bu klasör git'e girmez). Birden çok deneme varsa hepsini koyabilirsin; en iyisini birlikte seçeriz.

## Sonrası (Claude)

Penceresiz Blender scripti: temizlik → üçgen sayısını ~3–5 bine indirme → boyu 1.83 m'ye ölçekleme → 25 kemikli ortak iskelete bağlama → `assets/models/characters/soldier.glb` → Godot'da önizleme ve ekran görüntüsü.
