# İlerleme

Her oturumun sonunda güncellenir. Yeni oturum buradan devam eder.

## Şu an

- **Aşama:** 0 — Kurulum ve iskelet (Blender bağlantı doğrulaması dışında bitti)
- **Sıradaki iş:** Aşama 1 — Çekirdek prototip
- **Bekleyen (kullanıcıdan):** Blender'ı açıp BlenderMCP → Connect to Claude; Linux deneme ortamı var mı; kod lisansı (MIT?)

## Aşama durumu

| # | Aşama | Durum |
|---|---|---|
| 0 | Kurulum ve iskelet | Blender bağlantısı dışında bitti |
| 1 | Çekirdek prototip | sırada |
| 2 | Tur döngüsü | — |
| 3 | Dash ve his | — |
| 4 | Asker | — |
| 5 | Zombiler | — |
| 6 | Arena, atmosfer, ses | — |
| 7 | Arayüz ve akış | — |
| 8 | Kalıcı ilerleme | — |
| 9 | İçerik ve denge | — |
| 10 | Yayın | — |

## Aşama 0 kontrol listesi

- [x] `claude mcp list`: `godot` ve `blender` Connected
- [ ] Claude Blender'dan sahne bilgisini okuyabiliyor (Blender kapalıydı; "Could not connect to Blender")
- [x] Boş Godot projesi, Forward+, `godot --headless --path . --quit` hatasız
- [x] GUT 9.7.1 kurulu (Tower Climb'daki yerel kopyadan), örnek test geçiyor
- [x] Windows dışa aktarımı: `build/windows/DeadzoneLastStand.exe` üretildi, `--headless --quit` ile açılıp kapandı
- [x] Linux dışa aktarımı: `build/linux/DeadzoneLastStand.x86_64` üretildi (denenmedi; Linux ortamı yok)
- [x] `CLAUDE.md`, `docs/GAME_DESIGN.md`, `docs/PROGRESS.md`, `.gitignore`, `CREDITS.md`, ilk commit

## Ölçümler

| Ölçüm | Sonuç | Tarih |
|---|---|---|
| 60 FPS'te en çok zombi (masaüstü) | ölçülmedi (Aşama 1) | — |

## Oturum günlüğü

### 2026-11-15 — Oturum 1
- Ortam kontrolü: Godot 4.7.2 (mono değil), git 2.56, Node 26.13, godot-mcp ve blender-mcp bağlı.
- Aşama 0 iskeleti kuruldu: `project.godot` (Forward+), boş `main.tscn`, GUT, `.gutconfig.json`, duman testi, Windows + Linux export ön ayarları, belgeler.
- Blender açık değildi; bağlantı doğrulaması bekliyor.
