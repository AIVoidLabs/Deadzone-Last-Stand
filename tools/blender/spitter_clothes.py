"""Tükürücünün kıyafetleri (7.3): kesim verisi; kumaş yöntemi tank_clothes.garment (kıvrım, gevşetilmiş ve
kıvrılmış yırtık kenar, kalınlık).

- worker: kolları kopmuş iş tulumu; fermuar göğüsten karına açık (kese ve karın dışarıda), bot;
- suit: kirli beyaz gömlek, yakası açık, karında gerilip yırtılmış; koyu kumaş pantolon, kemer, ayakkabı;
- bare: çıplak gövde, baldırda yırtık kot, çıplak ayak (parmaklı).
Kese (sınıf "sac") hiçbir zaman örtülmez; kabarcıkların çevresinde kumaş delinir.
"""
import math

from mathutils import Vector, noise

import tank_clothes as tc
import zombie_kit as kit

BUBBLE_TEAR = 0.03        # kabarcık çevresinde kumaş açıklığı (m, yarıçapa eklenir)


def _n(co, scale, seed):
    return noise.noise(co * scale + Vector((seed, seed * 0.7, 0.0)))


def front_open(co, pts, seed, top_w=0.13, low_w=0.05, low_dz=-0.10):
    """Önde, boyundan karına daralan açıklık (açık fermuar / yaka)."""
    if co.y > pts["chest"][0].y - 0.05:
        return False
    z0, z1 = pts["belly"][0].z + low_dz, pts["neck0"][0].z
    if co.z < z0:
        return False
    u = min((co.z - z0) / (z1 - z0), 1.0)
    w = low_w + (top_w - low_w) * u
    return abs(co.x - 0.015 * _n(co, 5.0, seed)) < w * (1.0 + 0.35 * _n(co, 14.0, seed))


def belly_split(co, pts, seed, width=0.11, half_h=0.15):
    """Karnın önünde gerilip patlamış mercek yarık."""
    gut = pts["belly"][0] + Vector((0.0, -0.10, -0.07))
    if co.y > gut.y - 0.06:
        return False
    u = (co.z - gut.z) / half_h
    if abs(u) >= 1.0:
        return False
    w = width * math.sqrt(1.0 - u * u) * (1.0 + 0.45 * _n(co, 14.0, seed))
    return abs(co.x - 0.03 * _n(co, 4.0, seed + 3)) < w


def build_clothes(body, part, pts, bubbles, v, suffix):
    seed = v["seed"]
    waist0 = pts["pelvis"][0].z + 0.10

    def waist(co):
        """Bel çizgisi arkada belde, önde sarkık karnın altına iner (pantolon göbeğin altında)."""
        u = min(max((-0.04 - co.y) / 0.10, 0.0), 1.0)
        return waist0 - 0.13 * u * u * (3.0 - 2.0 * u)
    holes = [(loc, r + BUBBLE_TEAR) for loc, _n2, r, _c in bubbles]

    def holed(co):
        return any((co - loc).length < r + 0.015 * _n(co, 16.0, seed) for loc, r in holes)
    made = []
    top, hem = v["top"], v["hem"]

    def legs(cls, t, co):
        if cls == "thigh":
            return True
        return cls == "shin" and t < hem - 1.0 + 0.07 * _n(co, 9.0, seed)
    if top == "coverall":
        def keep(co):
            cls, t = part(co)
            if holed(co) or cls in ("sac", "foot", "forearm"):
                return False
            if cls in ("torso", "clav", "hips"):
                return not front_open(co, pts, seed)
            if cls == "neck":
                return co.y > pts["neck0"][0].y + 0.02
            if cls == "uparm":
                return t < 0.42 + 0.10 * _n(co, 9.0, seed)
            return legs(cls, t, co)
        mat = kit.cloth_material("M_Spitter_Top" + suffix, v["top_color"], stain=(0.06, 0.07, 0.03), blood=v["blood"])
        made.append(tc.garment(body, "Spitter_Top", keep, mat, part, "coverall", seed,
                               offset=0.010, thickness=0.006, holes=v.get("holes", 0.2), loose=0.012))
    elif top == "shirt":
        def keep(co):
            cls, t = part(co)
            if holed(co) or cls == "sac":
                return False
            if cls in ("torso", "clav"):
                return not (front_open(co, pts, seed + 1, 0.12, 0.03, 0.12) or belly_split(co, pts, seed))
            if cls == "hips":
                return co.z > waist(co) - 0.02 and not belly_split(co, pts, seed)
            if cls == "neck":
                return co.y > pts["neck0"][0].y + 0.03
            if cls == "uparm":
                return True
            return cls == "forearm" and t < 0.45 + 0.10 * _n(co, 9.0, seed)
        mat = kit.cloth_material("M_Spitter_Top" + suffix, v["top_color"], stain=(0.20, 0.22, 0.08), blood=v["blood"])
        made.append(tc.garment(body, "Spitter_Top", keep, mat, part, "shirt", seed,
                               offset=0.008, thickness=0.005, holes=v.get("holes", 0.2), loose=0.0))
    if v.get("belt"):
        def keep_belt(co):
            return part(co)[0] in ("hips", "torso") and abs(co.z - waist(co) + 0.03) < 0.03 and not holed(co)
        bmat, _ = kit.material("M_Spitter_Belt" + suffix, v["belt"], rough=0.5)
        made.append(tc.garment(body, "Spitter_Belt", keep_belt, bmat, part, "belt", seed,
                               offset=0.020, thickness=0.010, smooth_edges=6))
    if v["bottom"]:
        def keep_bottom(co):
            cls, t = part(co)
            if cls in ("hips", "torso"):
                return co.z < waist(co)
            return legs(cls, t, co)
        mat = kit.cloth_material("M_Spitter_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.05, 0.03))
        made.append(tc.garment(body, "Spitter_Bottom", keep_bottom, mat, part, "coverall", seed + 1.0,
                               offset=0.009, holes=0.25, loose=0.012))
    return made


def build_shoes(body, pts, part, v, suffix, s):
    import bpy
    shoes = tc.build_shoes(body, pts, part, v, suffix, s)
    for o in list(bpy.data.objects):
        if o.name.startswith(("Tank_Shoe", "Walker_Shoe")):
            o.name = o.name.replace("Tank_", "Spitter_").replace("Walker_", "Spitter_")
    return shoes
