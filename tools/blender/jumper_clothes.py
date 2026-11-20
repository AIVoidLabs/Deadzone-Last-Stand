"""Zıplayan zombinin kıyafetleri (V.5 konsept v1). build_jumper.py içe aktarır.

walker_clothes'tan uyarlandı: kesimler yükseklik (z) yerine parça sınıfı + parça boyunca konum (t)
+ eksenden dışa yön ile yapılır, çünkü zıplayan çömelik pozda durur. Kıyafet gövde yüzeyinden
(kit.garment). Kas şişmesiyle patlamış kumaş: uyluk ve baldırda gürültüyle açılmış yarıklar.
"""
from mathutils import Vector, noise

import zombie_kit as kit

CLOTH_EDGE_SMOOTH = 20


def _n(co, scale, seed, amp=1.0):
    return amp * noise.noise(co * scale + Vector((seed, seed * 0.7, 0.0)))


def build_clothes(body_obj, classify, v, suffix):
    seed, sm = v["seed"], CLOTH_EDGE_SMOOTH
    cache = {}

    def part(co):
        key = (round(co.x, 4), round(co.y, 4), round(co.z, 4))
        if key not in cache:
            cache[key] = classify(co)
        return cache[key]

    def burst(co, cls):
        """Kas şişmesiyle yırtılmış yer: uyluk ve baldırda, öne ve dışa bakan yüzlerde yoğun."""
        if cls not in ("thigh", "shin") or v["burst"] <= 0.0:
            return False
        return _n(co, 7.5, seed + 3.0) + 0.35 * _n(co, 19.0, seed) > 0.62 - v["burst"]

    top = v["top"]
    if top:
        def keep_top(co):
            cls, t, _r = part(co)
            if cls == "torso":
                return True
            if cls == "clav":
                return top != "tank"
            if top == "tshirt" and cls == "uparm":
                return t < 0.40 + _n(co, 12.0, seed, 0.12)
            return False
        mat = kit.cloth_material("M_Jumper_Top" + suffix, v["top_color"], blood=v["blood"])
        kit.garment(body_obj, "Jumper_Top", keep_top, mat, offset=0.010, holes=0.30, seed=seed,
                    smooth_edges=sm)
    if v["bib"]:
        def keep_bib(co):
            cls, t, r = part(co)
            side = abs(abs(co.x) - 0.085)
            if cls == "clav":
                return t < 0.35 and side < 0.024          # askılar omuz üstünden
            if cls != "torso":
                return False
            front = -r.y > 0.25
            if front and abs(co.x) < 0.13 and _n(co, 6.0, seed, 0.02) + co.z < body_obj["chest_z"]:
                return True                               # ön önlük (göğüs ortasına dek)
            return side < 0.024                           # askı
        mat = kit.cloth_material("M_Jumper_Bib" + suffix, v["bib"], blood=v["blood"])
        kit.garment(body_obj, "Jumper_Bib", keep_bib, mat, offset=0.013, thickness=0.005, holes=0.12,
                    seed=seed + 2.0, smooth_edges=sm)
    hem, shorts = v["hem"], v["bottom"] == "shorts"

    def keep_bottom(co):
        cls, t, _r = part(co)
        if burst(co, cls):
            return False
        if cls == "hips":
            return co.z < body_obj["belly_z"] + 0.02
        if cls == "thigh":
            return (not shorts and hem >= 0.5) or t < min(hem, 0.5) * 2.0 + _n(co, 11.0, seed, 0.10)
        if cls == "shin":
            return not shorts and hem > 0.5 and t < (hem - 0.5) * 2.0 + _n(co, 11.0, seed, 0.08)
        return False
    mat = kit.cloth_material("M_Jumper_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03),
                             blood=v["blood"] * 0.4)
    kit.garment(body_obj, "Jumper_Bottom", keep_bottom, mat, offset=0.009, holes=0.10, seed=seed + 1.0,
                smooth_edges=sm)
    if v["pocket"]:
        def keep_pocket(co):
            cls, t, r = part(co)
            outward = r.x * (1.0 if co.x > 0 else -1.0)
            return cls == "thigh" and 0.38 < t < 0.70 and outward > 0.70 and not burst(co, cls)
        mat = kit.cloth_material("M_Jumper_Pocket" + suffix, v["pocket"], stain=(0.04, 0.035, 0.02))
        kit.garment(body_obj, "Jumper_Pocket", keep_pocket, mat, offset=0.024, thickness=0.006,
                    seed=seed + 5.0, smooth_edges=8)
