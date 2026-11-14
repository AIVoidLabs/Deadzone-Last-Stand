Plan · 15 Kasım 2026 · kod yazılmadı

# Deadzone Last Stand

3D low-poly, dalga tabanlı hayatta kalma oyunu. Zırhlı bir asker, kapalı bir şehir arenasında zombi sürülerine karşı otomatik ateş eden silahlarla ve dash ile ayakta kalmaya çalışır. Godot ile, baştan sona Claude Code ile geliştirilecek.

## Verilen kararlar

| Konu | Karar | Plana etkisi |
| --- | --- | --- |
| Tur yapısı | Dalga + mağaza (Brotato usulü) | Dalga arasında seviye atlama kartı ve mağaza ekranı. Dengeleme dalga dalga yapılır. |
| Kontrol | Otomatik ateş + dash | WASD hareket, silahlar en yakın zombiye kendisi nişan alır, Space ile bekleme süreli dash. |
| Platform | Masaüstü öncelikli (Windows + Linux); web en sonda | Oyun masaüstü için tasarlanır: Forward+ renderer, gölge ve efektler serbest. Web hiçbir kararı sınırlamaz; en sonda, düşük kalite profiliyle denenir. |
| Modeller | Asker Tripo, zombiler Blender | Askeri sen Tripo'da üretirsin, rig ve animasyon bende. Zombiler tek ortak iskeletten kodla çeşitlenir. |
| Silahlar | Çoklu silah yuvası | 6 yuvaya kadar silah, aynı silahtan iki tane birleşip üst kademeye çıkar. |
| Harita | Kapalı şehir arenası | Tek sokak/kavşak, kenarlar barikatlı, zombiler kenarlardan girer. Kamera askeri izler. |
| Satın alma | Yalnız oyunda kazanılan parayla | Gerçek para yok. Böyle anladım: tur içi mağaza ve turlar arası kalıcı açılımlar oyun parasıyla. Yanlışsa düzelt. |
| Çalışma biçimi | Tower Climb kuralları | Tek seferde tek özellik, aşama sonunda durup "devam" beklerim, GUT testleri, sayılar tek `Tuning` dosyasında, sesler kodla. |

Aşama 0

## Kurulum: bu makinede ne var, ne eksik

Makineyi taradım. Araçların hepsi Tower Climb'dan kalma kurulu duruyor. Eksik olan tek şey, iki MCP sunucusunun yalnız Tower-Climb klasörüne kayıtlı olması. Aşağıdaki iki komutu Deadzone klasöründe çalıştırman yeterli.

| Araç | Bulunan | Durum | Ne işe yarar |
| --- | --- | --- | --- |
| Godot | 4.7.2 Standard, `C:\Tools\Godot` | kurulu | Oyun motoru. `godot` komutu PATH'te. |
| Export şablonları | 4.7.2.stable | kurulu | Windows, Linux ve web çıktısı almak için. |
| Git + GitHub CLI | Kurulu, `gh` girişli | kurulu | Sürüm kontrolü. Repo: `AIVoidLabs/Deadzone-Last-Stand`, henüz commit yok. |
| Node.js | v26.13.0 | kurulu | godot-mcp sunucusu `npx` ile çalışır. |
| uv | 0.13.7 | kurulu | blender-mcp sunucusu `uvx` ile çalışır. |
| Blender | 5.3.0 | kurulu | Modelleme, rig, animasyon. |
| Blender eklentisi | `addon.py` eklenti klasöründe | doğrulanacak | Dosya yerinde. Etkin mi ve bağlanıyor mu, Blender açıkken bakılır. |
| godot-mcp | Yalnız Tower-Climb'da kayıtlı | eklenecek | Claude'un oyunu çalıştırıp hata çıktısını okuması. |
| blender-mcp | Yalnız Tower-Climb'da kayıtlı | eklenecek | Claude'un Blender'ı kodla sürmesi. |
| Tripo hesabı | Tower Climb'da kullanıldı | sende | Asker modeli. Ücretsiz planda web sitesinden, H2.5 ile üretip dışa aktarırsın. |
| GUT 9.7.x | Projeye özel | eklenecek | Test çatısı. Proje açılınca `addons/gut` altına kurulur. |

### Şimdi yapman gerekenler

1. Bir terminalde Deadzone klasörüne geç ve Godot MCP'yi ekle: cd C:\\Users\\pekta\\projeler\\Deadzone-Last-Stand claude mcp add godot -e GODOT_PATH="C:\\Tools\\Godot\\Godot_v4.7.2-stable_win64_console.exe" -- cmd /c npx @coding-solo/godot-mcp
2. Aynı klasörde Blender MCP'yi ekle: claude mcp add blender -- uvx blender-mcp
3. Kontrol et. Listede `godot` ve `blender` "Connected" görünmeli: claude mcp list
4. Blender'ı aç, **Edit → Preferences → Add-ons** içinde "Blender MCP" işaretli mi bak. 3D görünümde **N** tuşu → **BlenderMCP** sekmesi → **Connect to Claude**. Bu bağlantı Blender her açıldığında yeniden yapılır.
5. Tripo'ya giriş yapabildiğini doğrula (tripo3d.ai). Model üretimi Aşama 4'te.

MCP sunucuları klasöre özel kaydedilir. Bu yüzden her yeni oyun klasöründe 1. ve 2. adım tekrarlanır; başka hiçbir şeyi yeniden kurman gerekmez.

Sıfır bir bilgisayarda baştan kurulum

1. **Godot:** godotengine.org'dan "Windows 64-bit, Standard" (.NET olmayan) zip'i indir, `C:\Tools\Godot` içine aç. Aynı klasöre `godot.cmd` adında, içinde şu satır olan bir dosya koy ve klasörü kullanıcı PATH'ine ekle: @"%\~dp0Godot_v4.7.2-stable_win64_console.exe" %\*
2. **Export şablonları:** Godot editöründe **Editor → Manage Export Templates → Download and Install**.
3. **Git, GitHub CLI, Node, uv, Blender:** winget install Git.Git winget install GitHub.cli winget install OpenJS.NodeJS.LTS winget install astral-sh.uv winget install BlenderFoundation.Blender Sonra yeni bir terminal aç ve `gh auth login` ile giriş yap.
4. **Blender eklentisi:** `addon.py` dosyasının bir kopyası `Tower-Climb\tools\blender\addon.py` yolunda duruyor (kaynağı: github.com/ahujasid/blender-mcp). Blender'da **Edit → Preferences → Add-ons → Install from Disk** ile seç, kutusunu işaretle.
5. **MCP sunucuları:** yukarıdaki 1–3. adımlar.

### Aşama 0 bitti sayılır, eğer

- `claude mcp list` Deadzone klasöründe `godot` ve `blender` için "Connected" gösteriyorsa.
- Claude, Blender'a bağlanıp sahne bilgisini okuyabiliyorsa (eklenti durumu sorgusu).
- Boş Godot projesi açıldıysa: Forward+ renderer, `godot --headless --path . --quit` hatasız.
- GUT kurulu ve tek bir örnek test geçiyorsa.
- Boş sahne Windows ve Linux için dışa aktarılabildiyse (duman testi; sorun en başta çıksın). Web burada denenmez.
- Proje iskeleti hazırsa: `CLAUDE.md`, `docs/GAME_DESIGN.md`, `docs/PROGRESS.md`, `.gitignore`, ilk commit.

## Aşamalar

Her aşama oynanabilir bir şey bırakır. Görseller sona yakın gelir: önce gri kutularla oyun eğlenceli mi diye bakılır, sonra giydirilir.

0

### Kurulum ve proje iskeleti

sırada

Yukarıdaki bölüm. Araçlar bağlı, boş proje Windows ve Linux'a çıktı veriyor.

1

### Çekirdek prototip (kutularla)

Kapsül asker düz bir zeminde yürür, kutu zombiler ona yürür, tek silah en yakın hedefe kendisi ateş eder. Can, hasar, ölüm, yeniden başlat. Sabit açılı izleyen kamera. F3 debug paneli.

Bitti

30 saniyelik bir çatışma kutularla bile gergin ve okunaklı. Zombiler üst üste binmeden askeri sarıyor.

Ölçüm

Masaüstünde kaç zombiyle 60 FPS kalıyor? Dalga tasarımının tavanını bu belirler. Zombi üst sınırı koda gömülmez, kalite profilinden okunur.

Senden

Yok.

2

### Tur döngüsü

Dalga sayacı ve süresi, zombilerden düşen XP ve para, seviye atlayınca 3 karttan biri, dalga arasında mağaza, 6 silah yuvası ve birleştirme, temel istatistikler (can, hasar, atış hızı, menzil, hız, zırh, şans).

Bitti

Baştan sona bir tur oynanıyor: 5–6 dalga, 3–4 silah, 10 kadar eşya ile. Kazanma ve kaybetme var.

Senden

Yok.

3

### Dash ve his

Dash (kısa dokunulmazlık, bekleme süresi), vuruş geri bildirimi, hasar sayıları, ekran sarsıntısı, hit-stop, namlu parlaması, mermi izi, ölüm parçacıkları, para toplama çekimi.

Bitti

Kutularla oynarken her vuruş ve her kaçış hissediliyor. Efektler belirgin ama kalabalık değil.

Senden

Oynayıp yorum; efektlerin dozunu sen onaylarsın.

4

### Asker

Tripo modeli → Blender'da temizlik, rig, animasyonlar (bekleme, koşu, dash, vurulma, ölüm) → Godot. Fizik gövdesi ile görüntü ayrı kalır; model yalnız görüntü katmanına takılır. Silah modelleri ayrı ve basit, Blender'da kodla.

Bitti

Kapsülün yerinde animasyonlu asker var, silahlar görünüyor ve ateş ederken tepki veriyor.

Senden

Konsept görseli ve Tripo'da model üretimi (A-poz, tek parça, silahsız). Blender açık ve bağlı olmalı.

5

### Zombiler

Tek ortak iskelet ve ortak animasyon seti. Gövde, kafa, kıyafet ve renk parçaları karıştırılarak görseldeki çeşitlilik elde edilir. Davranış türleri: yürüyen, koşan, tank, tüküren (menzilli), patlayan, dalga sonu boss.

Bitti

Her türün silueti ve davranışı uzaktan ayırt ediliyor. Sürü, Aşama 1'de ölçülen sayıda akıcı çalışıyor.

Risk

Yüzlerce iskeletli model masaüstünde de pahalılaşabilir. Gerekirse uzak zombiler için animasyonu dokuya pişirme yöntemine geçilir.

Senden

Blender açık ve bağlı. Varyasyonları galeri görseliyle onaylarsın.

6

### Arena, atmosfer, ses

Şehir sokağı: yol, kaldırım, binalar, barikatlar, direkler, ağaçlar, terk edilmiş araçlar. Bazıları engel olur. Işık ve sis, zemin izleri. Ses efektleri kodla sentezlenir.

Bitti

Ekran görüntüsü örnek görseldeki havayı veriyor; asker ve zombiler zeminden net ayrışıyor.

Senden

Sesleri dinleyip onay (ben duyamam). Müzik kararı.

7

### Arayüz ve akış

Ana menü, duraklatma, ayarlar (ses, tam ekran, dil), HUD (can, XP, dalga süresi, para, dash), mağaza ve kart ekranlarının son hali, tur sonu özeti, kayıt dosyası.

Bitti

Oyun menüden açılıp tur bitince menüye dönüyor; ayarlar ve rekorlar kalıcı.

Senden

Yok.

8

### Kalıcı ilerleme

Turlardan kazanılan kalıcı para. Bununla açılan başlangıç silahları, asker sınıfları ve kalıcı yükseltmeler. Gerçek para yok.

Bitti

Kaybedilen tur bile ilerleme bırakıyor; açılacak bir sonraki şey hep görünür.

Senden

Kapsam onayı: kaç sınıf, kaç yükseltme.

9

### İçerik ve denge

Silah, eşya ve dalga sayısını hedefe çıkarma. Zorluk eğrisi, fiyatlar, düşme oranları. Zorluk seviyeleri. Başarımlar isteğe bağlı.

Bitti

20 dalgalık tur ilk denemede kazanılmıyor ama haksız da hissettirmiyor; en az üç farklı kurulum işe yarıyor.

Senden

Oynayış geri bildirimi. Bu aşama en çok senin oynamana bağlı.

10

### Yayın

Windows ve Linux çıktıları. README, CREDITS, ekran görüntüleri, simge. itch.io sayfası ve GitHub Release. Web en son denenir: düşük kalite profili ve yalnız web çıktısına özel Compatibility renderer ile. Olmazsa masaüstü sürümü bundan etkilenmez.

Bitti

Windows ve Linux çıktıları temiz bir makinede açılıp oynanıyor. Web sürümü için ayrı karar verilmiş: yayınla ya da bırak.

Senden

Yayın onayı ve itch.io sayfası. Linux çıktısını deneyecek bir ortam.

## İlk sürüm için içerik hedefi

Bu benim önerim; sayılar Aşama 2 ve 9'da seninle kesinleşir.

| Kalem | Hedef | Not |
| --- | --- | --- |
| Dalga | 20 | Her biri 30–90 sn, son dalga boss. |
| Silah | 12, her biri 4 kademe | Tabanca, pompalı, hafif makineli, tüfek, keskin nişancı, alev makinesi, el bombası, mayın, taret, bıçak, tel örgü, roketatar. |
| Eşya | 30 kadar | İstatistik değiştiren pasifler; bir kısmı bedelli (bir şey verir, bir şey alır). |
| Zombi türü | 6 + 1 boss | Görsel çeşitlilik bundan bağımsız, parça karışımından gelir. |
| Asker sınıfı | 3 | Farklı başlangıç silahı ve istatistik. Kalıcı parayla açılır. |
| Arena | 1 | İkinci arena sürüm sonrasına. |

## Baştan konacak mimari kurallar

### Motor

Godot 4.7.2 Standard, GDScript, statik tipleme. Forward+ renderer. Oynanış XZ düzleminde, yükseklik yok.

### Kalite profilleri

Zombi üst sınırı, gölge, parçacık yoğunluğu, ışık ve efektler tek bir profil dosyasından okunur (düşük, orta, yüksek). Ayarlardan değişir; web ileride yalnızca düşük profili seçer, oyun koduna dokunulmaz.

### Fizik ve görüntü ayrı

Asker ve zombinin hareket kodu modele dokunmaz; sinyalle haber verir. Model sonradan değişse oynanış bozulmaz.

### Sayılar tek yerde

Tüm oynanış değerleri `Tuning` içinde. Silah, eşya, zombi ve dalgalar veri tablosu; yeni içerik bir satır eklemektir.

### Kurallar saf, testli

Hasar, birleştirme, mağaza, dalga üretimi sahneden bağımsız sınıflarda ve GUT testiyle.

### Sürü bütçesi

Zombi ve mermiler havuzdan gelir, yok edilip yeniden yaratılmaz. Yol bulma yerine basit yönelme ve itişme.

### Kapatılabilir özellik

Her yeni özellik tek sabitle kapanır. Beğenmezsen anında çıkar.

## Başlamadan netleşmesi iyi olacaklar

Hiçbiri Aşama 0'ı durdurmaz; ilgili aşamaya gelince sorarım. Şimdiden fikrin varsa yaz.

| Konu | Soru | Ne zaman |
| --- | --- | --- |
| Silahların görünümü | 6 silah askerin etrafında mı süzülsün (Brotato gibi, önerim bu), yoksa yalnız eldeki mi görünsün? | Aşama 2 |
| Şiddet dozu | Kan olacak mı? Önerim: low-poly'ye uygun, yeşilimsi sıçrama ve parça, gerçekçi kan yok. | Aşama 3 |
| Asker konsepti | Tower Climb'daki gibi konsept görselini sen mi hazırlarsın? Oranlar: gerçekçi mi, hafif chibi mi? | Aşama 4 |
| Linux testi | Linux çıktısını deneyebileceğin bir makine ya da WSL var mı? Yoksa çıktı alınır ama denenmemiş kalır. | Aşama 0 |
| Gamepad | Klavye yanında kol desteği istenir mi? Otomatik ateş sayesinde ucuz. | Aşama 7 |
| Dil | Oyun içi metinler Türkçe mi, İngilizce mi, ikisi mi? | Aşama 7 |
| Lisans | Repo AIVoidLabs altında. Tower Climb gibi MIT ve açık kaynak mı? | Aşama 0 |