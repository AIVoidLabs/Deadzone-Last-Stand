# Krediler

## Kod ve araçlar

| Ne | Kaynak | Lisans | Nerede |
|---|---|---|---|
| GUT — Godot Unit Testing 9.7.1 | https://github.com/bitwes/Gut/releases/tag/v9.7.1 (Tom "Butch" Wesley) | MIT | `addons/gut/` (yalnız geliştirme; dışa aktarıma girmez) |
| Godot Engine 4.7 | https://godotengine.org | MIT | Motor (projeye gömülü değil) |

## Görseller, modeller, ses

| Ne | Kaynak | Lisans | Nerede |
|---|---|---|---|
| Asker modeli | Tripo (tripo3d.ai) ile Taha tarafından üretildi; Blender scriptiyle sadeleştirilip iskelete bağlandı | Tripo kullanım koşulları — Taha doğruladı, sorun yok (2026-11-16) | `assets/models/characters/soldier.glb`, `soldier_albedo.jpg` |
| Universal Animation Library (Standard) | https://quaternius.com/packs/universalanimationlibrary.html (Quaternius) | CC0 1.0 | Ham dosya `assets/models/source/animations/UAL1/` (git'e girmez); seçilen klipler `assets/models/` altında |
| Universal Animation Library 2 (Standard) | https://quaternius.com/packs/universalanimationlibrary2.html (Quaternius) | CC0 1.0 | Ham dosya `assets/models/source/animations/UAL2/` (git'e girmez); seçilen klipler `assets/models/` altında |
| Ses efektleri (atış, isabet, zombi ölümü, adım, dash, asker vurulma) | Projede koddan sentezlendi: `tools/sfx/gen_sfx.py` (dış kaynak yok) | Projenin kendisi | `assets/audio/sfx/` |
| Car Kit 3.1 | https://kenney.nl/assets/car-kit (Kenney) | CC0 1.0 (paketteki License.txt) | Ham dosya `assets/models/source/kenney_car_kit/` (git'e girmez); yıpratılmış türevleri `assets/models/world/props/` |
| Barikat, kâğıt enkazı, trafik bariyeri, trafik lambası, çöp kutusu (5 GLB) | Taha indirdi (kaynak linki eklenecek) | CC0 (Taha beyanı, 2026-11-21) | Ham dosya `assets/models/source/*.glb` (git'e girmez); yıpratılmış türevleri `assets/models/world/props/` |
| Particle Pack 1.1 | https://kenney.nl/assets/particle-pack (Kenney) | CC0 1.0 (paketteki License.txt) | Ham dosya `assets/models/source/kenney_particle_pack/` (git'e girmez); seçilen dokular `assets/textures/fx/kenney/` |
| Ortam sesleri (neon vızıltısı, tel uğultusu, rüzgar, şehir uğultusu, yer tutucu ateş ve uzak sesler) | Projede koddan sentezlendi: `tools/sfx/gen_ambience.py` (dış kaynak yok; ateş ve uzak sesler yer tutucu, gerçek CC0 dosyalarla değişecek) | Projenin kendisi | `assets/audio/ambience/` |
| Ortam sesi: busy_cyberworld.ogg (şehir yatağı) | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/ambience/` (git'e girmez); işlenmiş türevi `assets/audio/ambience/*_cc0.wav` (`tools/sfx/process_ambience.py`) |
| Ortam sesi: fire-1.ogg (ateş döngüsü) | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/ambience/` (git'e girmez); işlenmiş türevi `assets/audio/ambience/*_cc0.wav` (`tools/sfx/process_ambience.py`) |
| Ortam sesi: storm_3_siren.ogg (uzak siren (kırpılmış bölüm)) | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/ambience/` (git'e girmez); işlenmiş türevi `assets/audio/ambience/*_cc0.wav` (`tools/sfx/process_ambience.py`) |
| Ortam sesi: dog_barking_mono.wav (uzak köpek havlaması) | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/ambience/` (git'e girmez); işlenmiş türevi `assets/audio/ambience/*_cc0.wav` (`tools/sfx/process_ambience.py`) |
| Ortam sesi: glass_breaking.wav (uzak cam kırılması) | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/ambience/` (git'e girmez); işlenmiş türevi `assets/audio/ambience/*_cc0.wav` (`tools/sfx/process_ambience.py`) |
| Zombi sesi paketi: zombiemoans_-_wav (ZombieMoans Track 5-7) | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/zombies/` (git'e girmez); işlenmiş türevleri `assets/audio/sfx/z_*.wav` (`tools/sfx/process_zombies.py`) |
| Zombi sesi paketi: darsycho__zombie-moans.ogg | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/zombies/` (git'e girmez); işlenmiş türevleri `assets/audio/sfx/z_*.wav` (`tools/sfx/process_zombies.py`) |
| Zombi sesi paketi: high_pitch_scream.mp3 | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/zombies/` (git'e girmez); işlenmiş türevleri `assets/audio/sfx/z_*.wav` (`tools/sfx/process_zombies.py`) |
| Zombi sesi paketi: monster_sfx_pack_2 | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/zombies/` (git'e girmez); işlenmiş türevleri `assets/audio/sfx/z_*.wav` (`tools/sfx/process_zombies.py`) |
| Zombi sesi paketi: yelling sounds | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/zombies/` (git'e girmez); işlenmiş türevleri `assets/audio/sfx/z_*.wav` (`tools/sfx/process_zombies.py`) |
| Zombi sesi paketi: independent_nu_ljudbank extreme_splatter | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/zombies/` (git'e girmez); işlenmiş türevleri `assets/audio/sfx/z_*.wav` (`tools/sfx/process_zombies.py`) |
| Zombi sesi paketi: independent_nu_ljudbank wet_squish_slurp_impacts | Taha indirdi (atıf gerekmez) | CC0 (Taha beyanı) | Ham dosya `assets/audio/source/zombies/` (git'e girmez); işlenmiş türevleri `assets/audio/sfx/z_*.wav` (`tools/sfx/process_zombies.py`) |
| Zombi sesleri (ağır darbe, kaya, kalkan, boss koşu ve uyarı) | Projede koddan sentezlendi: `tools/sfx/gen_zombie_sfx.py` (dış kaynak yok) | Proje içi | `assets/audio/sfx/z_heavy_impact_*.wav`, `z_rock_impact_*.wav`, `z_shield_thunk_*.wav`, `z_boss_charge_1.wav`, `z_boss_warning_1.wav` |
| Inter (arayüz yazı tipi, değişken wght) | https://github.com/rsms/inter (Blender 5.3 paketinden kopyalandı) | SIL OFL 1.1 (`assets/fonts/OFL-Inter.txt`) | `assets/fonts/Inter.woff2` |
