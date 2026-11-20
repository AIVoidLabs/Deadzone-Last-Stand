"""Tank zombisinin kıyafetleri (V.5 konsept). build_tank.py içe aktarır.

Kıyafet gövde yüzeyinden (kit.garment), sınırlar gövde noktalarından türetilir (boy sabiti yok).
Sırt plakalarının çevresi yırtık: kumaş plakaların çıktığı yerde açılır.
Ayakkabı/bot: walker_clothes.build_shoe (ölçekli) yeniden kullanılır.
"""
import bmesh
from mathutils import Vector, noise

import walker_clothes as wc
import zombie_kit as kit

EDGE_SMOOTH = 20
PLATE_TEAR = 0.11         # plaka tabanı çevresinde kumaş açıklığı (m, taban boyuna eklenir)


def _noisy(co, amp, seed, scale=9.0):
    return amp * noise.noise(co * scale + Vector((seed, 0.0, 0.0)))


def build_clothes(body_obj, part, pts, spots, v, suffix):
    seed = v["seed"]
    waist = pts["pelvis"][0].z + 0.20
    torn_back = [(loc, base + PLATE_TEAR) for loc, _u, _f, _s, base, _sx in spots]

    def near_plate(co):
        return any((co - loc).length < r + _noisy(co, 0.03, seed, 14.0) for loc, r in torn_back)

    top = v["top"]
    if top:
        sleeve = {"none": None, "torn": ("uparm", 0.30), "short": ("uparm", 0.62)}[v.get("sleeve", "torn")]

        def keep_top(co):
            if near_plate(co):
                return False
            cls, t = part(co)
            if cls in ("torso", "hump"):
                return top != "tank" or abs(co.x) < 0.24 or co.y > 0.1
            if cls == "hips":
                return co.z > waist - 0.10 or top == "coverall"
            if cls == "clav":
                return t < (0.35 if top == "tank" else 0.62 if sleeve is None else 1.0)
            if cls == "uparm" and sleeve:
                return t < sleeve[1] + _noisy(co, 0.10, seed)
            if top == "coverall" and cls in ("thigh", "shin"):
                return cls == "thigh" or t < v["hem"] + _noisy(co, 0.06, seed)
            return False
        mat = kit.cloth_material("M_Tank_Top" + suffix, v["top_color"], blood=v["blood"])
        hems = [] if top == "coverall" else [(2, waist - 0.12, 1.0, 0.04, 8.0)]
        kit.garment(body_obj, "Tank_Top", keep_top, mat, offset=0.012, thickness=0.006, hems=hems,
                    holes=v.get("holes", 0.3), seed=seed, smooth_edges=EDGE_SMOOTH)
    if v.get("belt"):
        def keep_belt(co):
            cls, _t = part(co)
            return cls in ("hips", "torso") and abs(co.z - waist + 0.02) < 0.045
        mat, _ = kit.material("M_Tank_Belt" + suffix, v["belt"], rough=0.45)
        kit.garment(body_obj, "Tank_Belt", keep_belt, mat, offset=0.024, thickness=0.012,
                    smooth_edges=6)
    if v["bottom"]:
        hem = v["hem"]

        def keep_bottom(co):
            cls, t = part(co)
            if cls in ("hips", "torso"):
                return co.z < waist
            if cls == "thigh":
                return True
            if cls == "shin":
                return t < hem + _noisy(co, 0.07, seed)
            return False
        mat = kit.cloth_material("M_Tank_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03))
        kit.garment(body_obj, "Tank_Bottom", keep_bottom, mat, offset=0.009, thickness=0.006,
                    holes=0.22, seed=seed + 1.0, smooth_edges=EDGE_SMOOTH)


def build_shoes(body_obj, pts, part, v, suffix, s):
    mat, _ = kit.material("M_Tank_Shoes" + suffix, v["shoes"], rough=0.55)
    sole, _ = kit.material("M_Tank_Sole" + suffix, (0.015, 0.014, 0.013), rough=0.8)
    shoes = [wc.build_shoe(pts, side, mat, sole, s) for side in ("L", "R")]
    bm = bmesh.new()
    bm.from_mesh(body_obj.data)
    dead = [f for f in bm.faces if part(f.calc_center_median())[0] == "foot"]
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(body_obj.data)
    bm.free()
    return shoes
