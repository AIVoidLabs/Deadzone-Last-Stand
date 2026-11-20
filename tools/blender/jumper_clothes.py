"""Zıplayan zombinin kıyafetleri (V.5 konsept v2). build_jumper.py içe aktarır.

Kesimler parça sınıfı + parça boyunca konum (t) + eksenden dışa yön ile (çömelik poz). Kıyafet gövde
yüzeyinden (kit.garment), kenarlar gevşetilir. v2: kumaş gibi okunsun diye
- bel bandı (kalın, ayrı şerit), paçada kıvrık/katlanmış kenar (rulo), tulumda dikişli göğüs cebi,
- eklem çevresinde sıkışma kıvrımları (kasık, diz arkası, sıvalı kol) — normal boyunca dalga,
- eşofmanda yan şerit (kolda ve pantolonda iki çizgi). Kargo pantolon çıktı (yastık gibi şişiyordu).
"""
import math

from mathutils import Vector, noise

import zombie_kit as kit

CLOTH_EDGE_SMOOTH = 20
FOLD_AMP = 0.0045         # kıvrım derinliği (m)
FOLD_FREQ = 75.0          # kıvrım sıklığı (rad/m, ~8 cm)


def _n(co, scale, seed, amp=1.0):
    return amp * noise.noise(co * scale + Vector((seed, seed * 0.7, 0.0)))


def add_folds(obj, part, zones, seed):
    """Sıkışma kıvrımları: zones = {sınıf: (t0, t1)} aralığında, parça eksenine dik halkalar."""
    mw = obj.matrix_world
    for vert in obj.data.vertices:
        co = mw @ vert.co
        cls, t, _r = part(co)
        if cls not in zones:
            continue
        t0, t1 = zones[cls]
        w = max(0.0, 1.0 - abs(t - (t0 + t1) * 0.5) / max((t1 - t0) * 0.5, 1e-3))
        if w <= 0.0:
            continue
        phase = (co.z * 0.8 + co.y * 0.5 + co.x * 0.3) * FOLD_FREQ + 3.0 * _n(co, 9.0, seed)
        vert.co += vert.normal * FOLD_AMP * w * (0.5 + 0.5 * math.sin(phase)) ** 2


def build_clothes(body_obj, classify, v, suffix):
    """body_obj: örtü gövdesi (build_jumper, drape=True): kaslar tek metaball, oluk yok; kumaş kas
    tepelerini örter, olukları köprüler (gövdeye boyanmış gibi değil)."""
    seed, sm = v["seed"], CLOTH_EDGE_SMOOTH
    cache = {}
    made = []

    def part(co):
        key = (round(co.x, 4), round(co.y, 4), round(co.z, 4))
        if key not in cache:
            cache[key] = classify(co)
        return cache[key]

    def burst(co, cls):
        """Kas şişmesiyle yırtık: yalnız uylukta ve dışa bakan yüzde, seyrek."""
        return cls == "thigh" and _n(co, 7.5, seed + 3.0) + 0.35 * _n(co, 19.0, seed) > 0.55

    if v["top"] == "jacket":          # eşofman üstü: gövde + kol, kollar dirsek üstüne sıvalı
        def keep_top(co):
            cls, t, _r = part(co)
            if cls in ("torso", "clav", "uparm"):
                return True
            if cls == "hips":
                return co.z > body_obj["belly_z"] - 0.02 + _n(co, 10.0, seed, 0.02)
            return cls == "forearm" and t < 0.12 + _n(co, 12.0, seed, 0.05)
        mat = kit.cloth_material("M_Jumper_Top" + suffix, v["top_color"], blood=v["blood"])
        top = kit.garment(body_obj, "Jumper_Top", keep_top, mat, offset=0.011, holes=0.18, seed=seed,
                          smooth_edges=sm)
        add_folds(top, part, {"uparm": (0.55, 1.0), "forearm": (0.0, 0.15), "clav": (0.6, 1.0)}, seed)
        made.append(top)
    if v["bib"]:
        def keep_bib(co):
            cls, t, r = part(co)
            side = abs(abs(co.x) - 0.085)
            if cls == "clav":
                return t < 0.35 and side < 0.022          # askılar omuz üstünden
            if cls != "torso":
                return False
            if -r.y > 0.25 and abs(co.x) < 0.13 and co.z < body_obj["chest_z"] + _n(co, 6.0, seed, 0.02):
                return True                               # ön önlük
            return side < 0.022                           # askı
        mat = kit.cloth_material("M_Jumper_Bib" + suffix, v["bib"], blood=v["blood"])
        made.append(kit.garment(body_obj, "Jumper_Bib", keep_bib, mat, offset=0.013, thickness=0.005,
                                holes=0.10, seed=seed + 2.0, smooth_edges=sm))

        def keep_pocket(co):
            cls, _t, r = part(co)
            return (cls == "torso" and -r.y > 0.6 and abs(co.x - 0.02) < 0.055
                    and body_obj["chest_z"] - 0.10 < co.z < body_obj["chest_z"] - 0.025)
        dark = tuple(c * 0.7 for c in v["bib"])
        made.append(kit.garment(body_obj, "Jumper_Pocket", keep_pocket,
                                kit.cloth_material("M_Jumper_Pocket" + suffix, dark), offset=0.022,
                                thickness=0.004, seed=seed + 5.0, smooth_edges=6))
    hem = v["hem"]

    def leg_cut(cls, t, co):
        if cls == "thigh":
            return hem >= 0.5 or t < hem * 2.0 + _n(co, 11.0, seed, 0.08)
        return cls == "shin" and hem > 0.5 and t < (hem - 0.5) * 2.0 + _n(co, 11.0, seed, 0.05)

    def keep_bottom(co):
        cls, t, _r = part(co)
        if burst(co, cls):
            return False
        if cls == "hips":
            return co.z < body_obj["belly_z"] + 0.02
        return leg_cut(cls, t, co)
    mat = kit.cloth_material("M_Jumper_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03),
                             blood=v["blood"] * 0.4)
    bottom = kit.garment(body_obj, "Jumper_Bottom", keep_bottom, mat, offset=0.009, holes=0.06,
                         seed=seed + 1.0, smooth_edges=sm)
    add_folds(bottom, part, {"thigh": (0.0, 0.22), "shin": (0.0, 0.18) if hem > 0.5 else (2, 3)}, seed)
    made.append(bottom)

    def keep_band(co):                 # bel bandı: kalın şerit
        cls, _t, _r = part(co)
        z0 = body_obj["belly_z"] - 0.012
        return cls in ("hips", "torso") and z0 - 0.028 < co.z < z0 + 0.012
    band_mat = kit.cloth_material("M_Jumper_Band" + suffix, tuple(c * 0.8 for c in v["bottom_color"]))
    made.append(kit.garment(body_obj, "Jumper_Band", keep_band, band_mat, offset=0.017, thickness=0.006,
                            seed=seed + 6.0, smooth_edges=8))

    def keep_cuff(co):                 # paça rulosu / kıvrık kenar: paçanın kendi (gürültülü) kesiminin içinde
        cls, t, _r = part(co)
        if hem <= 0.5:
            cut = hem * 2.0 + _n(co, 11.0, seed, 0.08)
            return cls == "thigh" and cut - 0.11 < t < cut - 0.015
        cut = (hem - 0.5) * 2.0 + _n(co, 11.0, seed, 0.05)
        return cls == "shin" and cut - 0.14 < t < cut - 0.02
    made.append(kit.garment(body_obj, "Jumper_Cuff", keep_cuff, band_mat, offset=0.012, thickness=0.005,
                            seed=seed + 7.0, smooth_edges=8))
    if v["stripe"]:
        def keep_stripe(co):
            cls, t, r = part(co)
            out = r.x * (1.0 if co.x > 0 else -1.0)
            if cls in ("thigh", "shin") and leg_cut(cls, t, co):
                return 0.86 < out and abs(r.y) > 0.10
            return cls == "uparm" and out > 0.80 and abs(r.y) > 0.10
        smat = kit.cloth_material("M_Jumper_Stripe" + suffix, v["stripe"], stain=(0.20, 0.18, 0.15))
        made.append(kit.garment(body_obj, "Jumper_Stripe", keep_stripe, smat, offset=0.016, thickness=0.003,
                                seed=seed + 8.0, smooth_edges=6))
    return made
