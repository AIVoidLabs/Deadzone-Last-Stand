"""UI kiti dokuları (Aşama 9): yordamsal fırça / yırtık kenar / sıçrama maskeleri.
Çalıştır: blender --background --python tools/blender/ui_textures.py
Çıktı: assets/textures/ui/*.png (RGB, maske olarak kullanılır; renk shader'dan gelir)."""
import os
import numpy as np
import bpy

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "textures", "ui")
os.makedirs(OUT, exist_ok=True)


def smooth(t):
    return t * t * (3.0 - 2.0 * t)


def sstep(a, b, x):
    return smooth(np.clip((x - a) / (b - a), 0.0, 1.0))


def vnoise(h, w, cy, cx, rng, wrap=False):
    """Değer gürültüsü: h x w piksel, cy x cx hücre."""
    g = rng.random((cy + 1, cx + 1)).astype(np.float32)
    if wrap:
        g[-1, :] = g[0, :]
        g[:, -1] = g[:, 0]
    ys = np.linspace(0, cy, h, endpoint=False, dtype=np.float32)
    xs = np.linspace(0, cx, w, endpoint=False, dtype=np.float32)
    y0 = ys.astype(int)
    x0 = xs.astype(int)
    fy = smooth(ys - y0)[:, None]
    fx = smooth(xs - x0)[None, :]
    a = g[y0][:, x0]
    b = g[y0][:, x0 + 1]
    c = g[y0 + 1][:, x0]
    d = g[y0 + 1][:, x0 + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(h, w, cy, cx, rng, octaves=5, gain=0.5, wrap=False):
    tot = np.zeros((h, w), np.float32)
    amp = 1.0
    norm = 0.0
    for _ in range(octaves):
        tot += amp * vnoise(h, w, cy, cx, rng, wrap)
        norm += amp
        amp *= gain
        cy *= 2
        cx *= 2
    return tot / norm


def noise1d(n, cells, rng, octaves=3, gain=0.55):
    return fbm(1, n, 1, cells, rng, octaves, gain)[0]


def gather(img, ys, xs):
    """Çift doğrusal örnekleme (sınırda kenar tekrarı)."""
    h, w = img.shape
    ys = np.clip(ys, 0, h - 1.001)
    xs = np.clip(xs, 0, w - 1.001)
    y0 = ys.astype(int)
    x0 = xs.astype(int)
    fy = ys - y0
    fx = xs - x0
    return (img[y0, x0] * (1 - fx) + img[y0, x0 + 1] * fx) * (1 - fy) + (
        img[y0 + 1, x0] * (1 - fx) + img[y0 + 1, x0 + 1] * fx
    ) * fy


def grid(h, w):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    return yy, xx


# ---------------------------------------------------------------- fırça şeridi
def brush_stroke(h, w, rng, pad_y=0.12, wobble=0.07, dry=0.9, tear=0.07, fray_rows=1.0):
    """Yatay fırça darbesi: R kaplama, G kıl çizgisi parlaklığı. Uçlar kuru ve kılcal."""
    yy, xx = grid(h, w)
    # üst/alt kenar: düşük frekanslı dalga + kıl tırtığı
    top = h * pad_y + (noise1d(w, 5, rng) - 0.5) * h * wobble * 2 + (noise1d(w, 90, rng, 2) - 0.5) * h * 0.035
    bot = h * (1 - pad_y) + (noise1d(w, 6, rng) - 0.5) * h * wobble * 2 + (noise1d(w, 80, rng, 2) - 0.5) * h * 0.04
    # kıl çizgileri: yatayda uzun, dikeyde ince
    streak = fbm(h, w, h // 2, 4, rng, 4, 0.55)
    streak2 = fbm(h, w, h, 9, rng, 3, 0.5)
    bristle = 0.6 * streak + 0.4 * streak2
    # kenar bristle'a göre kayar: kıl uzunluğu farkı
    edge_push = (bristle - 0.5) * h * 0.10
    inside = sstep(0.0, 2.2, yy - top - edge_push * 0.7) * sstep(0.0, 2.2, bot + edge_push * 0.7 - yy)
    # uçlar: her satırın bittiği yer farklı (kılcal), uca doğru kuruma
    endL = w * 0.035 + (noise1d(h, h // 2, rng, 3) - 0.5) * w * tear * 2 + np.abs(noise1d(h, h // 5, rng) - 0.5) * w * 0.12
    endR = w * 0.035 + (noise1d(h, h // 2, rng, 3) - 0.5) * w * tear * 2 + np.abs(noise1d(h, h // 5, rng) - 0.5) * w * 0.12
    cutL = sstep(0.0, 3.0, xx - endL[:, None])
    cutR = sstep(0.0, 3.0, (w - endR[:, None]) - xx)
    nx = np.abs(xx / w - 0.5) * 2.0
    dryness = sstep(0.55, 1.0, nx) * dry
    cover = sstep(dryness - 0.04, dryness + 0.14, bristle * 1.05 + 0.05) if dry > 0 else 1.0
    # sertlik: iç boşluklar (kuru fırça damarları) az
    cover = np.maximum(cover, 0.0)
    cov = inside * cutL * cutR * cover
    # çok ince kıl boşlukları
    cov *= 0.84 + 0.16 * sstep(0.2, 0.5, streak2)
    # damlalar / sıçramalar
    for _ in range(int(w / 60)):
        cx = rng.random() * w
        cy = (top.mean() if rng.random() < 0.5 else bot.mean()) + (rng.random() - 0.5) * h * 0.5
        r = 0.8 + rng.random() ** 3 * 4.5
        cov = np.maximum(cov, sstep(r, r - 1.2, np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)))
    detail = np.clip(0.55 + 0.7 * (bristle - 0.5) + 0.25 * (streak2 - 0.5), 0.0, 1.0)
    return np.clip(cov, 0, 1), detail


def band(h, w, seed, **kw):
    rng = np.random.default_rng(seed)
    cov, det = brush_stroke(h, w, rng, **kw)
    return stack(cov, det, cov * 0.0)


def stack(r, g, b):
    return np.stack([r, g, b], axis=-1).astype(np.float32)


# ---------------------------------------------------------------- leke / blot
def blot(h, w, seed):
    """Siyah fırça lekesi: dolu, düzensiz yırtık kenar, kenarda kuru fırça uçları."""
    rng = np.random.default_rng(seed)
    yy, xx = grid(h, w)
    n1 = fbm(h, w, 6, 10, rng, 5, 0.55)
    n2 = fbm(h, w, h // 3, 8, rng, 3, 0.5)  # yatay kıl
    n3 = fbm(h, w, 4, w // 12, rng, 3, 0.5)  # dikey kıl
    # dikdörtgen sdf, düzensiz
    mx, my = w * 0.07, h * 0.10
    d = np.minimum(np.minimum(xx - mx, w - mx - xx), np.minimum(yy - my, h - my - yy))
    d = d + (n1 - 0.5) * 70 + (n2 - 0.5) * 34 + (n3 - 0.5) * 30
    cov = sstep(-3.0, 4.0, d)
    # kenarda kuru uç boşlukları
    edge_zone = 1.0 - sstep(10, 55, d)
    gaps = sstep(0.5, 0.62, n2 + (fbm(h, w, 40, 40, rng, 2) - 0.5) * 0.35)
    cov = cov * (1.0 - edge_zone * (1.0 - gaps) * 0.8)
    for _ in range(46):
        cx = mx + rng.random() * (w - 2 * mx)
        cy = my if rng.random() < 0.5 else h - my
        cy += (rng.random() - 0.5) * 90
        r = 1.0 + rng.random() ** 3 * 5.0
        cov = np.maximum(cov, sstep(r, r - 1.2, np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)))
    return stack(np.clip(cov, 0, 1), np.clip(0.6 + n2 * 0.5, 0, 1), cov * 0)


# ---------------------------------------------------------------- sıçrama
def splat(sz, seed, spikes=14, drops=70):
    """Boya / kan sıçraması: R kaplama."""
    rng = np.random.default_rng(seed)
    yy, xx = grid(sz, sz)
    c = sz / 2.0
    dx = xx - c
    dy = yy - c
    r = np.sqrt(dx * dx + dy * dy)
    th = np.arctan2(dy, dx)
    core = sz * (0.10 + rng.random() * 0.04)
    # çekirdek: kenarı düzensiz
    wob = np.zeros_like(th)
    for k, a in ((3, 0.18), (7, 0.1), (13, 0.06), (23, 0.03)):
        wob += a * np.sin(k * th + rng.random() * 6.28)
    cov = sstep(1.4, -1.4, r - core * (1.0 + wob))
    # sivri akıntılar
    for _ in range(spikes):
        a = rng.random() * 6.2832
        ln = sz * (0.14 + rng.random() * 0.30)
        wd = sz * (0.004 + rng.random() * 0.012)
        ux, uy = np.cos(a), np.sin(a)
        t = dx * ux + dy * uy
        p = np.abs(-dx * uy + dy * ux)
        taper = np.clip(1.0 - t / ln, 0, 1)
        m = (t > 0) & (t < ln)
        w_here = wd * (0.35 + 1.6 * taper ** 1.3)
        cov = np.maximum(cov, m * sstep(w_here, w_here - 1.3, p))
        # ucunda damla
        er = wd * (0.9 + rng.random() * 1.4)
        ex = c + ux * (ln + er * 1.5)
        ey = c + uy * (ln + er * 1.5)
        cov = np.maximum(cov, sstep(er, er - 1.2, np.sqrt((xx - ex) ** 2 + (yy - ey) ** 2)))
    # serpilen damlalar
    for _ in range(drops):
        a = rng.random() * 6.2832
        dist = core * 1.5 + (rng.random() ** 0.8) * sz * 0.40
        rad = (0.7 + rng.random() ** 3 * 5.5) * (1.0 - dist / sz) * 1.4
        ex = c + np.cos(a) * dist
        ey = c + np.sin(a) * dist
        el = 1.0 + rng.random() * 1.6
        ux, uy = np.cos(a), np.sin(a)
        lx = (xx - ex) * ux + (yy - ey) * uy
        ly = -(xx - ex) * uy + (yy - ey) * ux
        cov = np.maximum(cov, sstep(rad, rad - 1.2, np.sqrt((lx / el) ** 2 + ly ** 2)))
    return np.clip(cov, 0, 1)


# ---------------------------------------------------------------- kart maskesi
def card_mask(h, w, seed):
    """R: kart silueti (yırtık kenar). G: kir (üst/yan kenar siyahı, kuru fırça). B: sıçrama."""
    rng = np.random.default_rng(seed)
    yy, xx = grid(h, w)
    iso = fbm(h, w, 8, 6, rng, 6, 0.55)
    streak_h = fbm(h, w, h // 3, 5, rng, 4, 0.55)  # yatay kıl
    streak_v = fbm(h, w, 5, w // 3, rng, 4, 0.55)  # dikey kıl
    grain = fbm(h, w, h // 2, w // 2, rng, 2, 0.5)
    d_left = xx
    d_right = w - 1 - xx
    d_top = yy
    d_bot = h - 1 - yy
    d_edge = np.minimum(np.minimum(d_left, d_right), np.minimum(d_top, d_bot))
    # silüet: kenar 6-14 px içeride, hafif yırtık
    sil = d_edge + (iso - 0.5) * 16 + (grain - 0.5) * 7 - 11
    R = sstep(-1.0, 1.5, sil)
    # kir: üstte kalın ve yırtık, yanlarda ince, altta köşelerde
    t_top = (yy + (iso - 0.5) * 150 + (streak_h - 0.5) * 70 + (grain - 0.5) * 26)
    top_dark = sstep(top := 118, 78, t_top)
    side = np.minimum(d_left, d_right) + (iso - 0.5) * 80 + (streak_v - 0.5) * 60 + (grain - 0.5) * 22
    side_dark = sstep(50, 14, side) * 0.95
    bot = d_bot + (iso - 0.5) * 120 + (streak_h - 0.5) * 50 + (grain - 0.5) * 22
    bot_dark = sstep(70, 26, bot) * 0.9
    G = np.clip(np.maximum(np.maximum(top_dark, side_dark), bot_dark), 0, 1)
    # kuru fırça lekeleri / yırtık beneklenme (kenarın iç tarafında kalan tozlu alan)
    speck = sstep(0.60, 0.74, fbm(h, w, 30, 22, rng, 3, 0.6))
    G = np.maximum(G, speck * sstep(260, 0, np.minimum(d_edge, d_top + 40)) * 0.55)
    # sıçramalar
    B = np.zeros((h, w), np.float32)
    spots = [(0.82, 0.20, 190, 31), (0.14, 0.58, 150, 32), (0.60, 0.66, 210, 33), (0.30, 0.18, 120, 34),
             (0.86, 0.80, 160, 35), (0.18, 0.88, 130, 36), (0.52, 0.30, 110, 37)]
    for fx, fy, sz, sd in spots:
        s = splat(sz * 2, sd, 12, 60)
        cx = int(fx * w - sz)
        cy = int(fy * h - sz)
        x0, y0 = max(cx, 0), max(cy, 0)
        x1, y1 = min(cx + sz * 2, w), min(cy + sz * 2, h)
        if x1 > x0 and y1 > y0:
            B[y0:y1, x0:x1] = np.maximum(B[y0:y1, x0:x1], s[y0 - cy:y1 - cy, x0 - cx:x1 - cx])
    return stack(R, G, B)


# ---------------------------------------------------------------- tebeşir çerçeve
def chalk_frame(h, w, seed):
    """Titrek çift tebeşir çizgisi, taneli ve kuru uçlu. R kaplama."""
    rng = np.random.default_rng(seed)
    yy, xx = grid(h, w)
    out = np.zeros((h, w), np.float32)
    grain = fbm(h, w, h // 2, w // 2, rng, 2, 0.5)
    fine = rng.random((h, w)).astype(np.float32)
    for k, (inset, width) in enumerate(((11, 3.1), (15, 2.1))):
        wx = (fbm(h, w, 14, 10, rng, 4, 0.55) - 0.5) * 7.0
        wy = (fbm(h, w, 14, 10, rng, 4, 0.55) - 0.5) * 7.0
        px = xx + wx
        py = yy + wy
        d = np.minimum(np.minimum(px - inset, w - 1 - inset - px), np.minimum(py - inset, h - 1 - inset - py))
        line = sstep(width, width * 0.35, np.abs(d))
        # kuru tebeşir: bazı bölümler incelir, taneli kopar
        pressure = fbm(h, w, 9, 7, rng, 3, 0.6)
        keep = sstep(0.28 + 0.1 * k, 0.50, pressure * 0.7 + grain * 0.5 + fine * 0.28)
        out = np.maximum(out, line * keep)
    return stack(np.clip(out, 0, 1), out * 0, out * 0)


# ---------------------------------------------------------------- tileable gürültü
def noise_tile(n, seed):
    """R: yumuşak fbm (duman/alev), G: ince tane, B: yatay kıl çizgileri. Hepsi döngülü."""
    rng = np.random.default_rng(seed)
    r = fbm(n, n, 4, 4, rng, 6, 0.55, wrap=True)
    g = fbm(n, n, 64, 64, rng, 2, 0.6, wrap=True)
    b = fbm(n, n, n // 3, 4, rng, 3, 0.55, wrap=True)
    r = (r - r.min()) / (r.max() - r.min())
    return stack(r, g, b)


def scratches(n, seed):
    """Döngülü ince çizikler (R)."""
    rng = np.random.default_rng(seed)
    yy, xx = grid(n, n)
    out = np.zeros((n, n), np.float32)
    for _ in range(70):
        a = rng.random() * 3.14159
        ln = n * (0.08 + rng.random() * 0.25)
        cx, cy = rng.random() * n, rng.random() * n
        ux, uy = np.cos(a), np.sin(a)
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                dx = xx - (cx + ox)
                dy = yy - (cy + oy)
                t = dx * ux + dy * uy
                p = np.abs(-dx * uy + dy * ux)
                m = (np.abs(t) < ln) & (p < 2.0)
                if m.any():
                    out = np.maximum(out, m * sstep(1.1, 0.2, p) * (0.35 + 0.65 * rng.random()) * sstep(ln, ln * 0.4, np.abs(t)))
    return stack(out, out, out)


def emblem_placeholder(n, seed):
    """Yer tutucu amblem: kemik rengi fırça halka + çapraz çizgi (RGBA)."""
    rng = np.random.default_rng(seed)
    yy, xx = grid(n, n)
    dx = xx - n / 2
    dy = yy - n / 2
    r = np.sqrt(dx * dx + dy * dy)
    wob = (fbm(n, n, 6, 6, rng, 3, 0.5) - 0.5) * n * 0.05
    ring = sstep(n * 0.035, n * 0.012, np.abs(r - n * 0.36 + wob))
    slash = sstep(n * 0.03, n * 0.01, np.abs(dx + dy + wob)) * (r < n * 0.34)
    a = np.clip(ring + slash, 0, 1) * (0.8 + 0.2 * fbm(n, n, 40, 40, rng, 2, 0.5))
    rgb = np.stack([np.full_like(a, 0.91), np.full_like(a, 0.875), np.full_like(a, 0.8)], -1)
    return np.concatenate([rgb, np.clip(a, 0, 1)[..., None]], -1).astype(np.float32)


def save(name, arr):
    arr = np.asarray(arr, np.float32)
    h, w = arr.shape[:2]
    if arr.shape[2] == 3:
        arr = np.concatenate([arr, np.ones((h, w, 1), np.float32)], -1)
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.colorspace_settings.name = "Non-Color"
    img.alpha_mode = "STRAIGHT"
    img.pixels.foreach_set(np.flipud(arr).ravel())
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)
    print("yazıldı", name, w, h)


if __name__ == "__main__":
    save("card_mask", card_mask(1136, 768, 7))
    save("band_a", band(192, 1024, 11))
    save("band_b", band(192, 1024, 12, wobble=0.10, dry=1.0, pad_y=0.16))
    save("band_c", band(192, 1024, 13, wobble=0.05, dry=0.8, pad_y=0.09))
    save("btn_stroke_a", band(128, 512, 21, pad_y=0.10, wobble=0.06, dry=0.85))
    save("btn_stroke_b", band(128, 512, 22, pad_y=0.14, wobble=0.08, dry=0.95))
    save("desc_blot", blot(512, 1024, 5))
    save("chalk_frame", chalk_frame(1136, 768, 3))
    for i in range(4):
        s = splat(512, 40 + i, 14 + i * 2, 80)
        save("splat_%d" % i, stack(s, s * 0, s * 0))
    save("noise_tile", noise_tile(512, 9))
    save("scratches", scratches(512, 4))
    save("emblem_placeholder", emblem_placeholder(256, 2))
