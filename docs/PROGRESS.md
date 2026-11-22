# İlerleme

Her alt aşama bitince ve her oturumun sonunda güncellenir. Yeni oturum buradan devam eder.
Plan: `ROADMAP.md` · Kararlar: `DECISIONS.md` · Teknik yapı: `TECH.md`

## Şu an

**Oturum 15 (2026-11-22): 8.4 ses başladı; Taha'nın dinlemesi bekleniyor.** Kararlar DECISIONS 2026-11-22 (karma kaynak; sıra ortam → zombi → silah → arayüz). Sonnet alt ajanlar + ayrı gözden geçiren, ana döngü doğruladı.
- Zırhlı takla sesi (`d1cc2ab`, FEATURE_SFX_DASH_ARMORED; eski ses dosyaları aynen duruyor).
- 8.4a ortam: Master/SFX/Ambience/UI/Music yolları (`AudioBuses`), askerde AudioListener3D (`AmbienceRig`), 21 konumlu döngü (ateş, neon, bozuk neon, tel uğultusu; `AmbienceData` tablosu), rüzgâr + şehir yatağı, 25–60 sn'de bir uzak ses (siren/köpek/cam; saf `AmbienceScheduler` + 11 test). Taha'nın CC0 dosyaları `tools/sfx/process_ambience.py` ile işlendi (ham kaynak `assets/audio/source/` git dışı); neon/tel/rüzgâr kodla (`gen_ambience.py`). FEATURE_SFX_AMBIENCE (+ _EMITTERS/_BEDS/_DISTANT). 326 test.
- Taha ilk takla sesini reddetti (metal "çın çın", item sesi gibi) → metal katmanlar silindi, boğuk; kristal toplama sesi basık/kapalı ton (FEATURE_SFX_PICKUP_DARK) (`dd42c99`). Kural: ses dili kapalı, boğuk; parlak çınlama yok. CC0 dosyalar atıf gerektirmez (Taha), CREDITS'te lisans satırı kalır.
- **Taha onayladı (2026-11-22): takla, kristal toplama, 8.4a ortam sesleri.**
- 8.4b zombi sesleri (`8f9e3cb`): Taha'nın 7 CC0 paketi `tools/sfx/process_zombies.py` ile işlendi (23 dosya; paketlerde lisans dosyası yok, Taha beyanı CC0), 13 ses kodla (`gen_zombie_sfx.py`: ağır çarpma, taş, kalkan, boss hücum/uyarı). `ZombieSounds.wire` bağlar; yeni sinyaller `special_started`, `tongue_event`; `Audio.play_at` + saf `SoundDistance` (8 m tam, 34 m sessiz). Koşucu çığlığı hazırlık başında (uyarı). FEATURE_SFX_ZOMBIES, FEATURE_SFX_ZOMBIE_BODYFALL. 332 test. **Taha onayladı (2026-11-22)**; ek istek: zombiemoans zip'indeki iniltiler sürü oluşunca ek katman olarak çalsın (sürü inilti katmanı yapılıyor). Açık: boss ölüm kükremesi son kükremeden 4 sn içindeyse çalmaz; çığlıkçı sesi insan gibi gelebilir (perde -4 yarım ton).
- Açık: kapanışta ara sıra "ObjectDB leaked" (5 denemede 1, yalnız çıkışta).

**Oturum 13 (2026-11-21): 8.1 parçaları oyunda, Taha'nın görünüm testi bekleniyor.** 8.1a kavşak greybox (`8ba35ea`); kamera: Taha B'yi seçti (60°) + dinamik açı (yaw 7°, eğim 5°; 9.2'de aç/kapa ayarı) + FOV 30 / 37.2 m (aynı kadraj, az perspektif); 8.1c köşe binası A, Blender betiği `build_city_building.py` + `city_kit.py` (`2266e6f`, FEATURE_CITY_BUILDINGS); 8.1e/f yıpratma hattı `build_props.py` + `wreck_kit.py`: Kenney Car Kit (CC0) ve Taha'nın 5 CC0 modeli → 17 yıkık prop, `scripts/data/city_props.gd` tablosuyla yerleşim (FEATURE_CITY_PROPS; alan içinde 8 çarpışmalı obje, sokak ortası boş). 288 test. Hepsi Sonnet alt ajanlarla, ana döngü doğruladı.
- Açık: sahne çok karanlık (lamba havuzları dışı siyah; asker yalnız halkasıyla seçiliyor) → 8.3; trafik lambaları ay ışığında fazla açık, kâğıtlar beyaz zar gibi; tek bina modeli 4 köşede (çeşit gerekebilir); özel saldırılar (zıplama inişi, tükürük/taş, doğurma) bloklardan habersiz → 8.2; 5 CC0 modelin kaynak linkleri CREDITS'te eksik (Taha verecek).
- Taha 8.1 sahnesini/karanlığı/kamerayı onayladı; proplar koyulaştırıldı (kök neden: vertex color albedo kapalıydı), çöp/moloz yığınları, 4 engel adası (8.2 kararı: orta). 8.2: zombi teğet kaçınması (FEATURE_OBSTACLE_STEER), hızlı hareket/iniş/tükürük/taş/çağrı engel farkında, ada başına tek çarpışma; takılma ölçümü `--capture-stuck` (açık 1/0/0, kapalı 5/8/0). 301 test.
- 8.2c görüş hattı: yüksek binalar hedef seçimini ve mermiyi keser (FEATURE_BUILDING_LOS); bot öldürme 627→715 (dalgalı, düşüş yok). 302 test. **8.2 bitti.**
- 8.3 ilk tur (Oturum 13 devamı): hasar sayıları kapatıldı (FEATURE_DAMAGE_NUMBERS=false); 8.3a atmosfer (sis, hacimsel sis, glow, renk gradyanı, vinyet; city_atmosphere.gd), ıslak asfalt shader'ı, asker ışığı + rim; 8.3b/c ateş (city_flame.gdshader dil dil alev, duman, kıvılcım, titreyen ışık), 2 çöp ateşi, 4 soyut neon (biri bozuk), lamba konileri (biri titrek), kül. Hepsi profil + ayrı FEATURE_ sabitleri; `--quality=low|medium|high` debug argümanı. Bench yüksek: 300 zombi 66 FPS (önce 71).
- **Taha 8.3 ilk turu beğenmedi** (rim ışığı, ucuz ateş, boş orta). Yeni referans `build/reference/target_look_2.png`. Yeniden yapım: rim/asker ışığı kodu silindi; sıcak sodyum ışık dili + yüksek kontrast; çift sarı şerit; MultiMesh yer dekoru (560 kâğıt/karton kümeli, kan, koni, ceset); paralel teller + 2 direk; yeni alev shader'ı, kor, kıvılcım, ince duman, pus; 8 neon tabela (BAR, OPEN, 24H, MOTEL, PIZZA...); vitrin ateşi; sahte zemin ışıkları; merkez ışığı. Taha'nın görüşü bekleniyor.
- Taha yeniden yapımı beğendi ("genel olarak beğendim"). 8.3g: Kenney Particle Pack (CC0) duman (ince tül, Taha onayı), batı bölgesi kök nedenleri (zemin hash ızgarası, eski leke kutuları, kan yansıması, dev neon lekesi), 4 köşe lambası (biri bozuk). 8.3h: Kenney maskeli kan (gölcük, sıçrama, sürüklenme), koyu yırtık kâğıtlar, yanık/yağ/lastik/çatlak izleri, cephe pencereleri + duvar lambaları. Bench yüksek: 300 zombi 71.7 FPS.
- 8.3i: manken cesetler silindi → 9 gerçek zombi cesedi (ölüm klibinin son karesinde sabit, çarpışmasız, FEATURE_CITY_ZOMBIE_CORPSES); cephe pencereleri bina A ızgarasına hizalandı, mavi parlama yok. Bench yüksek: 300 zombi 71.5 FPS.
- **Oturum 14 (2026-11-22), 8.3j düzeltmeleri (Sonnet alt ajanlar + ayrı gözden geçiren), Taha 8.3'ü onayladı (2026-11-22); sıradaki 8.4 ses, kaynak (karma / kod / paket) ve sıra kararı bekleniyor:** asker albedosu açıldı (FEATURE_PLAYER_BRIGHT_ALBEDO; rim/ışıma yok; asker/zemin parlaklık oranı 0.89→1.61 batıda, (7,-3)'te ateş yanında 0.52→0.85); direk askeri örtünce noktalı eleme (FEATURE_POLE_FADE, saf `PoleFadeRules`); patlayan pencere kök nedeni bina modelinin `warm` malzemesi (emisyon 7), çalışma zamanında ambere indirildi (FEATURE_CITY_WINDOW_DIM); ceset üstündeki koni taşındı (FEATURE_CITY_CONE_CLEAR); batı kolu iki küçük çöp ateşi (FEATURE_CITY_WEST_LIGHT, omni yok; batı/doğu zemin parlaklığı x=12/18/24: %84/%77/%86, önce %76/%63/%62). Dış blok pencereleri yazıldı ama kapalı (FEATURE_CITY_OUTER_WINDOWS=false; siyah duvarda boşlukta asılı görünüyor). 315 test. Bench yüksek 300 zombi: yeni özellikler açık 63.4/64.5, kapalı 64.1/66.0 FPS (aynı oturum; önceki 71.5 ile fark bu özelliklerden değil, nedeni araştırılmadı).
- **Oturum sonu (2026-11-21):** 8.3 görünümü Taha'nın son onayına hazır; sıradaki oturum: Taha'nın 8.3 onayı → 8.4 ses (Taha "sese sonra geçeceğiz" dedi). Küçük açıklar: bir koni bir cesedin üstüne düşüyor; batı kolunun sol yarısı doğudan karanlık; dış bloklarda pencere yok.

**YENİ OTURUM BURADAN (Oturum 13): Aşama 8 başlıyor (arena, atmosfer, ses).** Taha Aşama 7'yi oynadı ve onayladı (2026-11-21): "oyun çok güzel bir seviyeye gelmiş", oyunu baştan sona bitirdi; **"şahsen oyun basit ama bunu dengeleriz"** → zorluk/derinlik Aşama 11'de (denge) ele alınır, şimdi kod değişmez. Yeni oturum başlangıcı: ortam kontrolü → bu bölüm → ROADMAP 8.1 satırı + DECISIONS 2026-11-20 hedef görünüm (gece şehir sokağı, üstten/uzak kamera, ortam > zombi sayısı) → 8.1 için kararları sor, kod yazma. Blender açık ve MCP bağlı olmalı. Aşama 8'de boss'un soluk görünmesi ve göğüs yarığının okunmaması ışıkla birlikte ele alınır.

**Oturum 12 (2026-11-21): Aşama 7 bitti, Taha onayladı (yukarıda).** Taha "alt ajanlarla komple bitir" dedi; tasarımı Claude verdi (DECISIONS 2026-11-20 7.3, spec `build/briefs/s73_design.md`, `s74_boss.md`). Sıradaki ana aşama 8 (arena, atmosfer, ses — hedef görünüm: gece şehir sokağı).
- **Dene:** `godot --path . -- --arena=armored|screamer|spitter|thrower|bloater|boss_heap` (arena: 1–0 tür, B boss, R doğur, G silah); normal oyunda `--wave=5` boss dalgası.
- **Ayar soruları (Taha'nın elinde):** zırhlıya daire çizerek dolaşmak zor (yavaş dönüş 1.8 rad/sn ama ölçümde arka isabet az; zigzag işe yarıyor) → `armor_turn_rate` düşürülebilir; çığlıkçının çağrısı WINDUP sonunda (çığlık tepesi 0.55 sn'de değil); boss saldırı ağırlıkları slam 3 / charge 3 / summon 4.
- **Görsel açıklar:** boss oyun ışığında soluk pembe, göğüs yarığı uzaktan seçilmiyor (Aşama 8 ışığıyla birlikte); zırhlıda ağız fazla açık; tükürücüde kese + karın "iki top"; taş fırlatanın dev kolu yakından "sosis"; çığlıkçının kolları çığlıkta T-poza yakın; ölüm kliplerinde 2–13 cm gömülmeler (boss en çok).
- **Bilinen:** bot hâlâ 4. dalgada kaybediyor (5. dalga/boss botla denenmedi; denge 11. aşamada); dilci 100'de pahalı; sesler (boss uyarısı, kükreme, tükürme) yok — sesler ayrı oturumda.

**Oturum 11 sonu (2026-11-20): Aşama V bitti, Taha'nın "devam" demesi bekleniyor.** Sıradaki: Aşama 7 kaldığı yerden (7.3 özel türler: kalan zırhlı, çığlıkçı, tükürücü, taş fırlatan, patlayıcı; DECISIONS K7). Önce 7.3 için kararlar sorulur (hangi türler, sıra, imzalar; yeni hatla: konsept → model → klipler → Taha onayı → oyun), kod yazılmaz.
- Oturum 11'de yapılanlar: sürüklenme takılması (`bb823c3`), tank 2.3 m (`177964b`), dilci hızlandı + `FEATURE_TONGUE_MELEE` (`402a47f`, `2918639`), refactor (`4b88fbc` TongueMeshUpdater, `278e226` TongueAttack + EnemyCombat, `9c4bc1d` compactor `_melee` taşıma + 2 test). 212 test. Hepsi alt ajanlarla (Sonnet uygulayıcı + ayrı Sonnet gözden geçirici), ana döngü doğruladı.
- Kalan küçük açıklar: tank sırt plakaları üstten tek tepelik gibi; zıplayanın şortu havada yelken gibi; ölüm pozlarında 2–4 cm gömülme; koşucuya karşı daire çizmek ayakta durmaktan kötü; bot 0 galibiyet (7.3'ten beri, 11. aşamada denge); kapanışta ara sıra "2 ObjectDB instances leaked"; Blender betikleri ve `tuning.gd`/`enemy_data.gd` 300 satırı aşıyor (bilerek bölünmedi).
- Sesler ayrı bir oturumda ele alınacak (Taha, gerekirse dışarıdan açık lisanslı ses indirir).

Oturum 8 (2026-11-19). Taha görsel kaliteden memnun değildi; yeni yön onaylandı (DECISIONS 2026-11-19). Aşama 7.3+ dondu, araya **V — Görsel yeniden yön** girdi. V.1 ve V.2 bitti. **V.4 sürüyor: Taha dilci videolarını ve gırtlak B'yi onayladı (2026-11-19). V.4 bitti: Taha oyun videolarını ve ısırma kuralını onayladı (2026-11-19). Sıradaki: V.5 (yeni hattın diğer türlere yayılması).**

- **Taha (2026-11-19): "genel işleyişten memnunum".** Bu oturumun çalışma biçimi korunur: her adım tek sabitle kapatılabilir; Blender'da pozlar MCP içinde kemik konumu ölçülerek bulunur ve `look` görüntüsüyle yinelenir; oyunda ekran görüntüsü + kare özeti + video; ölçümler sayıyla raporlanır (TONGUE sayaçları); eklenen tasarım kuralı (ısırma) açıkça onaya sunulur.
- **Yeni oturum başlangıcı:** ortam kontrolü → bu bölüm → ROADMAP V.5 satırı → V.5 için kararları sor (hangi türler önce, sıra, her türün imza hareketi: DECISIONS K5), kod yazma. Blender işinden önce `claude mcp list` + Blender'da BlenderMCP bağlantısı; MCP'de `read_factory_settings` çağırma. Küçük açıklar: ısırıp bırakmada da `break_free` oynuyor; 40 dilcide dil maliyeti ölçülmedi (`--bench`); `zombie_visual.gd` ve `enemy_manager.gd` 300 satırı aşıyor.

- **YENİ OTURUM BURADAN (Oturum 11, gece): Taha'nın arena geri bildirimi (2026-11-20). 1–3 yapıldı (Oturum 11), Taha'nın arenada denemesi bekleniyor.**
  1. ✔ **Tank büyüdü (`177964b`):** `_TANK_LOOK_V` `height` 1.85 → 2.3 m (yarıçap 0.75 ve erişim 1.5 zaten eski 2.4 m tanka göreydi; yürüme senkronu boy ölçeğini kendisi hesaplar). Görüntü `build/shots/tank_h23.png`.
  2. ✔ **Dilci hızlandı + yakın vuruş (`402a47f`, `2918639`; Sonnet ajan yazdı, ayrı Sonnet ajan gözden geçirdi):** speed 2.4→3.2, hazırlık 0.8→0.55, kilit 0.3→0.25, bekleme 5.0→3.0, ıskalama beklemesi 2.0→1.2.
     `FEATURE_TONGUE_MELEE`: CHASE→WINDUP'ta asker temas + `tongue_melee_range` (0.9) içindeyse dil yok; 0.3 sn hazırlık (windup klibi ölçekli), `lash` klibiyle vuruş (temas + 0.8 içindeyse `contact_damage`), 0.8 sn toparlanma. Karar `TongueRules.wants_melee` (4 test, 210 geçiyor). Klip: Blender'da yeni `swipe` yerine mevcut elle anahtarlı `lash` (Claude seçti, Taha beğenmezse swipe anahtarlanır).
     Ölçüm (`--god --no-weapons`, 8 sn): yakın (1.2 m) `shots=0 melee=7`; uzak (7 m) `shots=1 melee=0`; bayrak kapalı yakın `shots=2 melee=0`. **Taha'nın arenada denemesi bekleniyor.** Şüphe: 0.3 sn hazırlıkta windup klibi ~2.7× hızlı, sert görünebilir.
  3. ✔ **Düzeldi (Oturum 11): dil bağı kalkınca asker sürüklenme pozunda takılı kalıyordu.** Kök neden: `ec3b12e`'den beri ısırıp bırakmada
     (`broke_free=false`) `PlayerVisual` hiçbir şey çağırmıyordu; döngülü `drag` tek-sefer düğümü kendiliğinden bitmediği için açık kalıyordu
     (yakın mesafede her ısırma bu yoldan geçiyor). Düzeltme: `PlayerAnimator.release(broke_free)` sürüklenmeyi her durumda söndürür, kurtulma
     klibini yalnız asker kopardıysa oynatır. 2 yeni GUT testi (206 geçiyor); oyunda `--capture-near=3` ile ısırma sonrası bekleme duruşu görüldü
     (`build/shots/fix_tongue_drag.png`).
  4. **Hedef görünüm notu (DECISIONS 2026-11-20):** gece şehir sokağı, daha üstten/uzaktan kamera, çevre ana unsur. Aşama 8 planına girer.

- **Oturum 10, 2. tur (2026-11-20):** Taha v1 eleştirisini kabul etti, "düzeltip oyuna ekleyin" dedi. Hepsi oyunda, bayraklı, **Taha'nın arenada denemesi bekleniyor.**
  - Koşucu v2 (`e53d7f4`, oyunda `bf67714`, `FEATURE_RUNNER_MODEL`), zıplayan v2 (`b9bafa6`, `d53e049`, `FEATURE_JUMPER_MODEL`), tank v2 (`b3796c0`, `FEATURE_TANK_MODEL`). Her türün kendi kafası, tanımlı kaslar, ayak parmakları. Model tablosu `scripts/data/zombie_model_data.gd`.
  - `25ee792`: `GAME_PACE` 0.8 (hızlar, dash ve süreler değil), `FEATURE_RUNNER_SPRINT` (çığlık → durmadan koşu → pençe → geçip gider → döner), `FEATURE_JUMP_SHADOW_MARKER` (kırmızı halka yerine gölge).
  - Sürü (100 zombi, temiz): yürüyen 3.3, koşucu 3.5, tank 3.7, zıplayan 5.8 ms/kare.
  - Açıklar: tank sırt plakaları üstten tek tepelik gibi; zıplayanın şortu havada yelken gibi; ölüm pozlarında 2–4 cm gömülme; koşucuya karşı daire çizmek ayakta durmaktan kötü (12 vs 5 vuruş/19 sn); bot 0 galibiyet (7.3'ten beri).

- **Oturum 10, 1. tur (2026-11-20, paralel alt ajanlar):** her Blender ajanı kendi `blender --background` örneğinde çalıştı (Taha onayı).
  - Yürüyen oyunda: `af8df5e` (`FEATURE_WALKER_MODEL`), walk 0.70 sn döngü, 2.6 m/sn'de kayma 1–3 cm (`d2a07fc`), klip hızı gerçek hıza bağlı (`c6ff391`, `FEATURE_WALK_SPEED_SYNC`). Sürü: 100 yürüyen 3.4 ms, 300 yürüyen 10.0 ms/kare (temiz ölçüm).
  - **1v1 debug arenası** (`2da4997`): `scenes/debug/arena.tscn` (F6) ya da `-- --arena=<tür>`; 1–5 tür, R doğur, G silah, H ölümsüz, T dondur, K öldür, F7 silah. `FEATURE_DEBUG_ARENA`.
  - Konseptler v1 (`14643ee`): `docs/concept/{runner,jumper,tank}_v1_{lineup,signature,gamecam,silhouette,close}.png`. **Taha'nın yorumu bekleniyor.** Ortak zayıflık: kafa yürüyenden, yüz hamur gibi; kas formları balon; ayaklar parmaksız. Onaydan sonra oyun modeli + klipler (paralel), değerlendirme arenada (klip videosu yok).
  - Refactor borcu: `zombie_visual.gd` 303, `enemy_manager.gd` ~315, `walker_anims.py` 319, `walker_pose.py` 333, `build_jumper.py` 307, `tongue_rope.gd` ~400 satır.

- **Oturum 9 sonu (2026-11-19):** V.5'te yürüyen. Konsept onaylı (`850f3d1`), oyun modeli (`1aa67c5`) ve klipler (`9ce5318`) hazır, **henüz oyunda değil**. Sırayla:
  1. **Yürüyüşü 2.6 m/sn'ye göre yeniden anahtarla (Taha kararı):** oyun hızı değişmez. Uzun adımlı, öne yıkılır gibi giden bir sendeleme; ayaklar oyunun 2.6 m/sn hızında kaymamalı. Yalnız `walk` klibi değişir (`tools/blender/walker_anims.py` + `walker_pose.py`, `walker_game.py` ile dışa aktarım). Blender MCP gerekir.
  2. **Oyuna bağla:**
     - `FEATURE_WALKER_MODEL` bayrağı.
     - `ZombieVisual.VC_MODELS` içinde walker için 4 GLB'lik dizi (`zombie_walker_{office,worker,skinny,civilian}.glb`); eski `zombie_walker.glb` bayrak kapalıyken kalır.
     - WINDUP'ta attack klibi `play_timed(anim_attack, 0.7, 0.5)`, RECOVER'da klip tamamlansın.
     - Walker satırında yalnız `death_a/b` olsun.
     - Doğrulama: oyun görüntüsü + `--bench --bench-kind=walker` ile sürü ölçümü (100–300 zombi). LOD gerekirse bu ölçüm söyler.
  3. Sonra sıradaki tür koşucu ("Pençeli"): konsept → model → klipler → Taha onayı → oyun.
  - **Video kuralı (Taha, 2026-11-19):** video çekmek çok token tüketiyor. Taha'ya video gösterme. Video yalnız Claude'un geliştirmede gerçekten ihtiyacı varsa çekilir; o zaman da kare özetine bakılır. Taha'ya ekran görüntüsü yeter; isterse kendisi oyunda dener.
  - **Çalışma biçimi:** fable-orchestration. Ana döngü plan, brief ve doğrulama yapar; Blender işini Opus alt ajan, kod işini Sonnet alt ajan yapar. Briefler dosyada, alt ajanlar yalnız kendi dosyalarını commit eder.
  - **Küçük açıklar:**
    - GLB'de `COLOR_0` alfasız, dilcinin parıltı maskesi çalışmıyor olabilir.
    - `tongue_rope.gd` ~400 ve `walker_pose.py` 333 satır, bölünmeli.
    - Yürüyen ölümlerinde 1–2 karede ~5 cm gömülme var.

- **V.5 başladı (Oturum 9, 2026-11-19, alt ajanlarla):** sıra yürüyen → koşucu → zıplayan → tank (imzalar DECISIONS). Yürüyen konsepti Blender'da üretiliyor (Opus alt ajan).
  - V.4 borçları kapandı (Sonnet alt ajan, gözden geçirildi, 182 test geçiyor):
    - `ec3b12e`: ısırıp bırakınca `break_free` oynamıyor (`TongueRules.player_broke_free`, `released` olayında `broke_free`).
    - `b8fc08f`: `--bench --bench-kind=tongue|walker --bench-count=40` eklendi.
    - `802d434`: `enemy_manager.gd` ve `zombie_visual.gd` 300 satırın altına indi (`enemy_queries/burn/pool/compactor/spawner`, `zombie_clip_player`, `zombie_jump_marker`).
  - **Ölçüm (önemli):** 40 dilci 24 ms/kare (~41 FPS), 40 yürüyen 2.4 ms/kare (~410 FPS). Dilci başına ~0.55 ms. **Ayrıldı (`777e8f6`, `--bench-no-tongue` / `--bench-no-tongue-mesh`):**
    - Yeni model, shader ve glb klipleri: 40 zombide ~0.1–0.3 ms, yani bedava. Yürüyen bu yola güvenle geçebilir.
    - Verlet simülasyonu: ~1.4 ms.
    - Maliyetin ~19 ms'i `TongueRope._build_mesh()`'ten geliyor: ağ her karede, dil sarkarken de GDScript'te yeniden kuruluyor (528 köşe, indeksler her kare yeniden üretiliyor, `clear_surfaces` + `add_surface_from_arrays`).
    - Öneri: indeksleri bir kez üret; köşe sayısını 528'den ~150'ye indir; sarkarken ve ekran dışındayken ağı seyrek kur ya da hiç kurma.
  - **Dil ağı optimizasyonu (`125a374`, `FEATURE_TONGUE_MESH_FAST`):**
    - 40 dilci 23 ms → 5.7–6.1 ms/kare (Blender kapalıyken, temiz ölçüm). Görüntü kare özetinde aynı.
    - `tongue_rope.gd` ~400 satıra çıktı, bölünmeli.
  - **Yürüyen oyun modeli (`1aa67c5`):** Taha konsept v2.1'i (`850f3d1`) onayladı.
    - 4 ayrı GLB: `zombie_walker_{office,worker,skinny,civilian}.glb`. Eski `zombie_walker.glb` oyunda kullanıldığı için üzerine yazılmadı. Çeşitlerin kemik boyları farklı, bu yüzden her çeşidin kendi iskeleti var; kemik adları aynı.
    - Her çeşit ~4.1 bin üçgen, 26 kemik (25 + `jaw`). Önizleme: `scenes/debug/walker_preview.tscn`.
    - Kıyafet gövdenin üstüne boyalı renk; yırtık kenar ve kumaş kalınlığı gitti.
    - **Açık:** GLB'de `COLOR_0` alfasız çıkıyor, dilcinin parıltı maskesi (`COLOR.a`) GLB üzerinden çalışmıyor olabilir.
  - **Yürüyen klipleri (`9ce5318`):** idle, walk (1.1 sn), windup (0.5), attack (1.3, vuruş 0.7), stagger, death_a, death_b, spawn. Elle anahtarlandı, IK ile çözülüp dönüş olarak yazıldı. Betikler `walker_anims/falls/pose/check.py`. Videolar `build/movies/walker_*.avi`.
    - **Açık karar: hız uyuşmazlığı.** Klibin adımı 0.7 m/sn hıza göre yapılmış, oyundaki walker hızı 2.6 m/sn. Taha'ya soruldu.
    - **Entegrasyonda gerekecek:** WINDUP'ta attack klibi `play_timed(…, 0.7, 0.5)` ile oynamalı, RECOVER'da klip tamamlanmalı. Walker satırında `death_c` olmamalı.
  - Yürüyen konsepti v2: `b130705`.
    - Saç kask değil, ayakkabılar düzeldi, kumaş kenarları yumuşadı.
    - Kalan sorunlar: ağız içi kara top gibi, Skinny fazla pembe, yüz hâlâ kil gibi. Taha'nın yorumu bekleniyor.
  - Yürüyen konsepti v1: `9a053b6` (`build_walker.py`, `docs/concept/walker_v1_*.png`). Taha'nın yorumu bekleniyor. Zayıf yanlar: saç kask gibi, yüz karikatür, ayakkabı takunya.

- **V.4 2. kısım (2026-11-19, `09ea19e` + asker klipleri commit'i):**
  - **Model:** `FEATURE_DILCI_MODEL` açıkken `EnemyData` dilci satırındaki `look_v` alanları üste yazılır: model `ZombieVisual.VC_MODELS[&"dilci"]` (köşe renkli `zombie_vc.gdshader`, ZombieLook paleti yok, örnek başına hafif `tint`), klipler glb'nin kendi AnimationPlayer'ı (idle, walk, windup hazırlık süresine sığar, lash, pull, stagger, death_a, spawn). Model boyu AABB'den.
  - **Dil:** `DilciTongue` (TongueRope, Head kemiği + `MOUTH_REST` ofseti): dururken sarkar (0.42 m), hazırlıkta boğaza çekilir, olaylarla fırlar/tutunur/çekilir. Olay sözleşmesi `shoot/attach/to/off` (eski kutu dil `BeamTongue` aynı sözleşmeyle). Doku metre tabanlı (UV2 yay uzunluğu; sert halka çizgileri kalktı), uçuş boyunca düz çizgiye çekim (atış başı kıvrımı azaldı).
  - **Mekanik (`FEATURE_TONGUE_PULL`):** dil `tongue_speed` 16 m/sn düz uçar (yön hazırlığın son 0.3 sn'sinde kilitli, `tongue_lead` 0), ucun süpürdüğü yol askere değerse yakalar (dash/dokunulmazlık kaçırır, asker zaten bağlıysa geçer). Yeni durum `PULL`: asker `tongue_pull_speed` 1.8 m/sn ile çekilir (`Player.pull`, hareket+dash kilitli, silahlar ateş eder, asker dilciye döner); dilci ölünce, `tongue_pull_time` 3 sn dolunca ya da temas + `tongue_release_gap`'e gelince bırakır. **Yakına gelince ısırır (contact_damage) — Claude ekledi, Taha onayladı.** Kurallar `TongueRules` (7 test). Kapalıyken eski anlık ışın + 1 sn bağ.
  - **Ölçüm (`--capture-kind=tongue --god --no-weapons --capture-spawn=1 --capture-near=7`, 8 tekrar):** ayakta %100, daire %0, zigzag 0.7 sn %50, zigzag 1.5 sn %100 (dilciye doğru yürüyor). Yeni `--no-weapons` seçeneği; sonda `TONGUE shots/hits/bites/timeouts`.
  - **Asker klipleri (`FEATURE_PLAYER_DRAG_CLIPS`):** `tools/blender/player_anims.py` (Blender MCP'de mankende elle anahtarlandı, pozlar ölçülerek bulundu) → `assets/models/anim/player_anims.glb` (AnimationLibrary, ual1 ile aynı kemik eşlemesi): `drag` (0.8 sn döngü: halat çeker gibi geriye yaslanma, eller göğüste dili tutar, ön topuk gömülü, arka ayak tökezler, dilcinin çekişiyle silkelenme), `break_free` (0.8 sn: son asılış, kollar dışa fırlar, geriye sendeleme adımı, bekleme duruşu). Kodla titreme ve türetilmiş struggle/break_free yalnız bayrak kapalıyken.
  - **Öğrenim:** Blender MCP'de `read_factory_settings` çağırma (eklentiyi kapatır, bağlantı kopar); PowerShell 5.1 `Get-Content/Set-Content` UTF-8 dosyaları bozar.
  - **Açık:** ısırıp bırakınca da `break_free` oynuyor (asker koparmadı, dilci bıraktı); kaçış zorluğu Taha'nın elinde ayarlanacak; dilci dosya boyutları (`zombie_visual.gd` ~330, `enemy_manager.gd` ~460 satır) bölünmeli.

- **V.4 1. kısım (2026-11-19, Taha V.3'ü onayladı: "planladığın gibi devam et"):**
  - **Oyun modeli:** `tools/blender/dilci_game.py` (görünüş `build_dilci.py`'den) + ortak `tools/blender/zombie_game.py` (incelt, köşe rengi, birleştir, iskelet, uzaklıkla ağırlık, GLB). Çıktı `assets/models/characters/zombie_dilci.glb`: 3 çeşit (A 8.7k, B 8.7k, C 7.6k üçgen) tek iskelette. Doku/UV yok: renk köşelerde, `COLOR.a` = parıltı maskesi (göz, kese); Godot shader `assets/shaders/zombie_vc.gdshader` (flash/fade/burn sözleşmesi flash_lit ile aynı + `tint` + ince alaca). Dil ağda yok (oyunda TongueRope).
  - **İskelet:** 25 standart kemik + `jaw_l`, `jaw_r` (yarık çene), `sac` (kese ölçeği). Dinlenme pozu modelin kambur pozu. `.glb.import`'ta kemik eşlemesi `PATH:Dilci_Rig/Skeleton3D`; içe aktarım 28 kemik, `%GeneralSkeleton` yolları doğrulandı.
  - **Klipler (elle, `tools/blender/dilci_anims.py`, 30 FPS):** idle, walk (0.9 sn döngü), windup (0.8 sn: küçük çöküş → geriye gerilme, kese 1.75× şişer ve titrer), lash (0.35 sn: öne şaklama, çene sonuna dek, kese söner), pull (bağlıyken ritmik çekiş), stagger, death_a (dizler çöker, sırtüstü), spawn. Önizleme `godot --path . res://scenes/debug/dilci_preview.tscn`; video `build/movies/dilci_clips.avi`.
  - **Yordamsal dil (Sonnet alt ajan, gözden geçirildi):** `scripts/game/rope_sim.gd` (saf Verlet zinciri, 6 test), `scripts/fx/tongue_rope.gd` (sarkma, fırlatma dalgası, bağlı, kamçılı geri çekilme; kalın sivrilen boru), `assets/shaders/tongue.gdshader`, önizleme `scenes/debug/tongue_preview.tscn`, video `build/movies/tongue_close.avi`. Zayıf: sarkarken boğum çizgileri sert; atış başında 1–2 karelik kıvrım olabilir.
  - **Bilinen küçük:** döngü kliplerinin sonunda 1 karelik fazla tutma (2.43 sn / 2.4).

- **V.3 2. tur (2026-11-19):** Taha ilk denemeyi "çok sevdi", **zombiler tamamen Blender'da** (Tripo yok; DECISIONS). Betik ikiye bölündü: `tools/blender/zombie_kit.py` (ortak: gövde, metaball, gövde yüzeyinden kıyafet `garment()` — yırtık etek + delik, ten/kumaş malzemeleri, stüdyo) + `tools/blender/build_dilci.py` (dilci + `VARIANTS` tablosu). Yeni: yırtık tişört / atlet / çıplak, pantolon / şort (yırtık paça, delikler, kir ve kan lekesi), topuklu ayak, 3 ten tonu. Görüntüler `docs/concept/dilci_v2_lineup.png`, `dilci_v2_gamecam.png`. Ağ şimdilik ~105 bin yüz/zombi (görünüş için); oyun bütçesine (8–15 bin) indirme, iskelet ve dışa aktarım V.4'te. Çalıştırma: Blender MCP içinde `exec(open(r"<repo>/tools/blender/build_dilci.py", encoding="utf-8").read())` → `build/blender/dilci.blend`.
- **V.3 1. tur (eski betik `dilci_trial.py`, kaldırıldı):** oyun modeli değil, kalite denemesi. Gövde: iskelet noktaları + skin modifier + voxel remesh + gürültülü yer değiştirme; kafa ve çene: metaball kütleleri (negatifler göz çukuru/damak oyar); dil: incelen NURBS boru. İmza: ortadan yarılmış, dişli alt çene; yarıkların arasında damarlı, içten parlayan boğaz kesesi (dil burada durur, saldırı öncesi şişer = önsezi); ağızdan sarkan ıslak dil, kanca uçlu. Görüntüler `docs/concept/dilci_trial_v1_*.png` (tam boy, kafa, oyun kamerası). Claude'un değerlendirmesi: siluet ve dil oyun kamerasından okunuyor; yakında "kil/hamur" görünüyor (anatomi kaba, ayaklar topak, ten plastik), AAA seviyesi değil. Kodla heykel yapılamadığı için insansı gövde için Tripo temeli + Blender'da imza parça/malzeme/animasyon önerisi sürüyor; Taha'nın kararı bekleniyor. Yaklaşık 77 bin yüz (deneme, optimize değil).
- **V.2 önizleme aracı:** `tools/preview_movie.ps1` + `tools/godot/contact_sheet.gd`; ffmpeg yok, video AVI (MJPEG).

Oturum 7 (2026-11-18). Aşama 7.1 onaylı. **7.2 kod bitti, Taha'nın oynayıp yorumu bekliyor: koşucu + tank zombi** (zıplayan ve sürünen sonraya). Aşama 6 onayı hâlâ bekliyor. 154 test, push yok.

- **7.2 (koşucu + tank):** `EnemyData` satırları (eksik alanlar yürüyenden gelir; `attack_kind` `melee`/`lunge`), tür başına model (`zombie_runner.glb` 4 çeşit × 8 şema, `zombie_tank.glb` 4 çeşit × 6 şema; `build_zombie.py -- runner|tank|all`, tank için omuz zırhı + göğüs plakası), tür başına havuz (`Zombie.kind`). **Koşucu (can 18, hız 3.8, atılış 9 m/sn):** yaklaşınca çömelir (0.65 sn), `LungeRules` ile oyuncunun gideceği yere nişan alır (lead 0.9), son 0.22 sn yön kilitli, atılırken 2.0 rad/sn ile izler; ıskalayınca 0.9 sn toparlanır; atılırken sendelemez, hazırlıkta vurulursa atılış bozulur. **Tank (can 220, hız 1.5, ağırlık 4, vuruş 35, sendelemez):** 0.9 sn hazırlık, 1.5 m erişim. Dalga 2'den runner, 4'ten tank (`WaveData.mix`). `FEATURE_ZOMBIE_VARIETY`, `FEATURE_ZOMBIE_LUNGE`. Ölçüm: ayakta duran asker %100 vurulur, daire çizerek kaçan ~%14 (`--capture-kind=runner --god --circle --headless --fixed-fps 60` → `LUNGE starts/hits`). Gerçek kaçış zorluğu Taha'nın elinde ayarlanır. Bot 5/5 tur kazandı.
- **Taha geri bildirimi (2026-11-18), düzeltme SONRAYA (Taha: "şimdi yapma"):** (1) **Dil görünümü berbat:** dümdüz çizgi gibi, doğal ve animasyonlu durmuyor → dil yeniden tasarlanacak (ağızdan çıkan kalın, uçlu, dalgalanan/yaylanan, atışta uzayıp çekilen, ıslak görünümlü; tek kutu yerine eğri/segmentli ağ ya da animasyonlu mesh). (2) **Bağlanma (çırpınma) animasyonu çok kötü:** türetilen `struggle` klibi + kodla titreme doğal değil → daha iyi bir çırpınma (belki Blender'da elle animasyon ya da farklı kaynak klip). (3) **Kurtulduktan sonra koşma animasyonu tamamen bozuluyor:** hata. Şüphe: `PlayerAnimator`'daki `struggle`/`free` tek-sefer düğümleri (abort + fire zinciri) koşu karışımını bozuyor ya da kurtulma klibi bitince koşu hızı/harmanı yerine oturmuyor; `_pivot.position` titremesi sıfırlanmıyor olabilir. Yeniden üretmek: `--capture-root=S` ve ardından yürü. Önce kök neden bulunacak, sonra düzeltilecek.
- **7.3 başı: zıplayan + dilci (kod bitti 2026-11-18, Taha testi bekliyor).** Özel saldırılar `SpecialAttacks` sınıfında (koşucunun atılışı da buraya taşındı); `ZombieRules` yeni durumlar `JUMP` (havada, vurulamaz) ve `LASH` (dil bağda). **Zıplayan (can 40, hasar 14):** 7 m'de çömelir (0.7 sn), yerde `jump_marker` halkası (askeri önden izler, son 0.3 sn kilitli, dış kenar iniş şokunun gerçek sınırı), 0.9 sn'de ~3.5 m yay çizerek iner (görüntü yükselir, fizik gövdesi yerde), havadayken silahlar hedef almaz (`_targetable`), iniş: 1.5 m şok + toz halkası + kamera sarsıntısı + ses (şimdilik `explosion`), 1.6 sn toparlanma. **Dilci (can 35, hasar 6):** 7.5 m'den 0.8 sn hazırlanır (son 0.3 sn yön kilitli), dil atar (ışın, ıskalarsa 0.25 sn görünür); isabet: asker tam 1 sn bağlı (hareket + dash yok, silahlar çalışır; `Player.root/release_root`, `FEATURE_ROOT`), dilci ölürse çözülür, 5 sn bekleme. Asker animasyonları: bağlanınca çırpınma (`struggle` + gövde titremesi), çözülünce kollarını açarak kurtulma (`break_free`); `PlayerClipData` + `PlayerAnimator` iki yeni tek-sefer düğümü. Modeller `build_zombie.py -- jumper|tongue` (uyluklu atletik / iri kafalı açık çeneli, dil kırmızı). Dalga: zıplayan 3'ten, dilci 4'ten (`FEATURE_ZOMBIE_JUMP`, `FEATURE_ZOMBIE_TONGUE`). 164 test. **Ölçüm (`--god`):** zıplayan: ayakta %100, zigzag ~%16, daire ~%6; dilci: ayakta %100, daire ve radyal kaçış ~%100 (ışın anında vurur), yan zigzag ~%76. **Bot uyarısı:** kaçmayan bot yeni türlerle 6 turda 0 galibiyet (önceki set 5/5, ikisi kapalı 3/5); insan dash'iyle farklı olur ama zorluk yüksek, ayar düğmeleri `EnemyData` ve `WaveData.mix`.
- **Dash ve hız (Taha: önemli):** yeni istatistik `dash_distance` (dash hızı), kart + `Atılış Bobini`, `Hafif Çizme`; hareket hızı kartları 4/8/12/16, dash bekleme kartları 6/12/18/24.
- **Eksik:** koşucuya özel ses (atılış), zıplayan ve sürünen, tank vuruş anı (`attack_anim_hit_time` 0.55 tahmin) ve hazırlık ekranda gözle doğrulanmadı.

- **7.1 kararları (Taha, 2026-11-18):** yakın dövüş ilk iş. Silahlar: bıçak (tekli dürtme), katana (yay savurma), ışın kılıcı (geniş savurma + yanma), **ateşli kılıç** (yanma, Taha ekledi); SMG, uzay silahları (plazma tüfeği = delip geçen, graviton topu = ittirme; sonra istenirse yenileri), bomba atar (alan hasarı). Yakın dövüş de 6 yuvadan birini kullanır, birleşme kuralları aynı. Zor erişim: 10–15 dalgalık oyuna göre silahlar dalga kilidiyle (`min_wave`) ve nadirlikle (`weight`) mağazaya çıkar, fiyatlar yüksek.
- **Uzak silahlar (2026-11-18):** SMG (hızlı, sapmalı), plazma tüfeği (`pierce` 4, cyan iz), graviton topu (`behavior: &"burst"`: 80° koniyi bir kerede iter, mor iz), bomba atar (`explode_radius` 3 m, yay çizen kısa tıknaz mermi, `ExplosionFx` + kamera sarsıntısı). `ProjectilePool.fire(..., opts)`: pierce, explode_radius, color, size, length, arc; `EnemyManager.query_circle`. 4 yeni model, 4 yeni ses (`plasma`, `graviton`, `launcher`, `explosion`; SMG `shot_1`'i kısık kullanır). `FEATURE_EXPLOSION_FX`.
- **Yeni oturum başlangıcı:** ortam kontrolü → bu bölüm → `GAME_DESIGN.md` zombi türleri tablosu ve ROADMAP 7.2 satırı → 7.2 için kararları sor (hangi türler, hız/can/ağırlık, siluet ve hareket farkı, Blender modelleri), kod yazma. Yeni zombi türü eklenince `EnemyData` satırı + `drop_value` + `WaveData.mix` satırı gerekir; model Blender'dan (`build_zombie.py` hattı), skill'ler `creature-artist`, `rigging`, `animation`, `lowpoly-style`.
- **Silah sayıları ilk tahmin;** 11. aşamada dengelenir. Taha silahlardan memnun.
- **Yakın dövüş nasıl çalışır:** `WeaponData` satırında `behavior: &"melee"`; `max_range` = menzil, `melee_arc_deg` = yay (0 = tekli dürtme), `burn_dps/burn_time` = yanma. `MeleeRules` (saf: yay + yanma sayacı, 9 test), `EnemyManager.query_arc/ignite`, görüntü `WeaponVisual` (kabzadan savurma, öne atılma) + `MeleeSlash` (kesik izi, `FEATURE_MELEE_SLASH_FX`), yanan zombi turuncu parlar (`flash_lit` `burn`, `FEATURE_BURN`). Modeller `build_weapons.py` (kökeni kabza), sesler `gen_sfx.py` `swing_*`. Mağaza: `WeaponData.shop_pool(wave)` + ağırlıklı çekiliş (`ShopRules`).
- **Denge notu:** yeni silahların sayıları ilk tahmin; bot 3 turda kazandı (bıçak alındı). Gerçek denge Taha'nın oynayışıyla.
- **Yeni oturum başlangıcı:** ortam kontrolü → Taha'nın yakın dövüş yorumu → 7.1'in kalanı (SMG, uzay silahları, bomba atar).
- **Aşama 6'dan miras:** kademe değerleri `WeaponData.TIERS`; mağaza `ItemData` / `ShopRules` / `ShopFlow`; dalga tablosu `WaveData` (üst sınırlar 60/90/120/180/260); yeni zombi türü eklenince `drop_value` ve `WaveData.mix` satırı gerekir. Denge ölçümü: `tools/autoplay_runs.ps1`.
- **Tasarım borcu (Aşama 9):** kart ekranı, mağaza, HUD, ölüm/kazanma ekranları prototip → 9.3–9.5.
- **Açık küçük konular:** dalga arasında iyileşme yok; kristal toplama sesi ve XP çubuğu rengi yorum almadı; oyun 10–15 dalgaya uzayacak (11.2'de WaveData genişler).
- **Taha oyunu Godot editöründen (Play) açıyor.** Gömülü pencerede tam ekran yok, F tuşları ulaşmayabilir; "Embed Game on Next Play" kapatılır. Yedekler Ctrl+3 … Ctrl+9. F7 artık sırayla pompalı, bıçak, katana, ışın kılıcı, ateşli kılıç, SMG, plazma, graviton, bomba atar ekler; `--tiers=knife:1,katana:2` ile görüntü.

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
| 7 | Silah ve zombi çeşitliliği | ✔ bitti (2026-11-21, Taha oynadı ve onayladı) |
| V | Görsel yeniden yön | ✔ bitti (2026-11-20) |
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
- [x] 7.1 Silah davranış seti — yakın dövüş (bıçak, katana, ışın kılıcı, ateşli kılıç + yanma) 2026-11-18, Taha onayladı. Commit'ler `51062b0`, `962f58a`, `a97f11b`; SMG, plazma, graviton, bomba atar da eklendi
- [x] 7.2 Koşucu ve tank — kod bitti 2026-11-18, Taha'nın oynayıp yorumu bekliyor (ayrıntı "Şu an"). Zıplayan ve dilci kodlandı (7.3), sürünen sırada
- [x] 7.3 Özel türler — 2026-11-21: zırhlı, çığlıkçı, tükürücü, taş fırlatan, patlayıcı (mekanik `3b43f6a`, `3007806`, `e585a6e`, `4e01975`, `3535f57`; modeller `822500a`, `b9b18d9`, `ff0d289`, `8d8012e`, `faa7104`; entegrasyon `0da196e`, `a0fb6fb`, `752bd44`, `e46e146`; gözden geçirme `a3956ac`, `0cf3726`, `31a55c1`). Taha'nın arenada denemesi bekleniyor
- [x] 7.4 Boss "Yığın" — 2026-11-21 (`7b99e3d` saldırı düzeni + öfke, `534b579` boss dalgası + uyarı + can çubuğu, `ac9b9a1` model + klipler, `08c349e` oyuna bağlandı). Taha'nın denemesi bekleniyor
- [x] 7.5 Yeniden ölçüm — 2026-11-21 (Ölçümler tablosu; profil sınırları değişmedi)

### V — Görsel yeniden yön
- [x] V.1 Kurtulma hatası düzeltmesi — 2026-11-19 (`79ca05a`; `break_free` tek sefer, `ZombieClipData`/`PlayerClipData` satırında `loop` alanı, 3 yeni test; oyunda kurtulma sonrası koşu görüntüyle doğrulandı)
- [x] V.2 Animasyon önizleme video aracı — 2026-11-19 (`tools/preview_movie.ps1`: kare dizisi + kare özeti + AVI; iki deneme: anim_preview ve dilci saldırısı)
- [x] V.3 Üslup rehberi + konsept galerisi + Blender deneme modeli — 2026-11-19 (dilci denemesi; sonuç: Tripo gerekmez, zombiler tamamen Blender'da)
- [x] V.4 Dilci uçtan uca dikey dilim — 2026-11-19 (`571d6f2`, `25e12f1`, `09ea19e`, `4257599`; Taha oyun videosunu onayladı)
- [x] V.5 Yeni hattın diğer türlere yayılması — 2026-11-20 (yürüyen, koşucu, zıplayan, tank oyunda; sürü ölçüldü; arena düzeltmeleri `bb823c3`, `177964b`, `402a47f`; refactor `4b88fbc`, `278e226`, `9c4bc1d`; Taha onayladı)
- [x] V.6 Asker animasyon cilası — 2026-11-20 yapılmadı, Taha: "askerin animasyonları güzel kalsın" (DECISIONS)

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
| **7.5 tür başına 100 zombi** (yeni modeller, high, vsync kapalı, makine sakin) | yürüyen 3.37, zırhlı 3.66, tükürücü 3.43, taş fırlatan 3.71, koşucu 3.52, tank 3.94, zıplayan 4.12 ms/kare; çığlıkçı 12.2 ms (çağrılarla 350 aktif); **dilci 18.9 ms** (dil ağı; dalgalarda az); patlayıcı zincirde tek kare 36 ms sıçrama | RTX 3050 Ti Laptop | 2026-11-21 |
| 7.5 yürüyen 300 | 10.17 ms (98 FPS) → profil sınırları low 150 / medium 250 / high 350 yeterli, değişmedi | aynı | 2026-11-21 |
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

- Uzak silahlar eklendi (yukarıda). Bot turu 3/3 kazandı, 145 test. Ekran görüntüsünde patlama parlaması ağır kaldı → daha şeffaf ve küçük yapıldı; Taha'nın gözüyle ayarlanır.

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
