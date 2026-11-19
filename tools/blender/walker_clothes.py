"""Yürüyen zombinin kıyafetleri ve ayakkabıları (V.5 v2). build_walker.py içe aktarır.

Kıyafet gövde yüzeyinden (kit.garment); kesik kenarlar gevşetilir ki voxel merdiveni kalmasın.
Ayakkabı ayrı kütle: topuk, kemer, parmak kökü, burun + bilek yakası; düz ve hafif taşan koyu taban.
"""
import bmesh
from mathutils import Matrix, Vector, noise

import zombie_kit as kit

CLOTH_EDGE_SMOOTH = 20    # kıyafet kesik kenarı gevşetme turu (0 = v1 merdivenli kenar)


# ---------------------------------------------------------------- kıyafet

def _noisy(co, amp=0.12, scale=12.0, seed=0.0):
    return amp * noise.noise(co * scale + Vector((seed, 0.0, 0.0)))


def build_clothes(body_obj, classify, v, suffix):
    h, seed = v["body"]["h"], v["seed"]
    sm = CLOTH_EDGE_SMOOTH
    cache = {}

    def part(co):
        key = (round(co.x, 4), round(co.y, 4), round(co.z, 4))
        if key not in cache:
            cache[key] = classify(co)
        return cache[key]

    top = v["top"]
    if top:
        sleeve = {"tshirt": ("uparm", 0.55), "shirt": ("forearm", 0.80), "tank": (None, 0.0)}[top]

        def keep_top(co):
            cls, t = part(co)
            if cls in ("torso", "hips"):
                return True
            if cls == "clav":
                return top != "tank" or t < 0.45
            if top == "tank" or sleeve[0] is None:
                return False
            if cls == "uparm":
                return sleeve[0] == "forearm" or t < sleeve[1] + _noisy(co, seed=seed)
            if cls == "forearm" and sleeve[0] == "forearm":
                return t < sleeve[1] + _noisy(co, seed=seed)
            return False
        mat = kit.cloth_material("M_Walker_Top" + suffix, v["top_color"], blood=v["blood"])
        kit.garment(body_obj, "Walker_Top", keep_top, mat, offset=0.010,
                    hems=[(2, 0.93 * h, 1.0, 0.035, 9.0)], holes=0.30, seed=seed, smooth_edges=sm)
    if v["vest"]:
        def keep_vest(co):
            cls, _t = part(co)
            if cls == "clav":
                return _t < 0.55
            if cls not in ("torso", "hips"):
                return False
            vneck = co.y < -0.05 and abs(co.x) < max(0.0, (co.z - 1.22 * h)) * 0.55
            return not vneck
        mat = kit.cloth_material("M_Walker_Vest" + suffix, v["vest"], blood=0.3)
        kit.garment(body_obj, "Walker_Vest", keep_vest, mat, offset=0.024, thickness=0.006,
                    hems=[(2, 0.98 * h, 1.0, 0.025, 8.0)], holes=0.15, seed=seed + 2.0,
                    smooth_edges=sm)
    if v["tie"]:
        def keep_tie(co):
            cls, _t = part(co)
            return cls == "torso" and co.y < -0.05 and abs(co.x - 0.005) < 0.022 + 0.01 * (1.46 * h - co.z) \
                and co.z < 1.47 * h
        mat = kit.cloth_material("M_Walker_Tie" + suffix, v["tie"])
        kit.garment(body_obj, "Walker_Tie", keep_tie, mat, offset=0.017, thickness=0.004,
                    hems=[(2, 1.13 * h, 1.0, 0.02, 10.0)], seed=seed + 4.0, smooth_edges=sm)
    hem = v["hem"]

    def keep_bottom(co):
        cls, t = part(co)
        if cls in ("hips", "torso"):
            return co.z < 1.03 * h
        if cls == "thigh":
            return hem >= 0.5 or t < hem * 2.0 + _noisy(co, 0.10, seed=seed)
        if cls == "shin":
            return hem > 0.5 and t < (hem - 0.5) * 2.0 + _noisy(co, 0.06, seed=seed)
        return False
    mat = kit.cloth_material("M_Walker_Bottom" + suffix, v["bottom_color"], stain=(0.05, 0.04, 0.03))
    kit.garment(body_obj, "Walker_Bottom", keep_bottom, mat, offset=0.008, holes=0.22, seed=seed + 1.0,
                smooth_edges=sm)
    return part


# ---------------------------------------------------------------- ayakkabı

# Ayak yerel uzayı: x tabandan buruna (0..1 boy oranı), y yan, z taban üstü yükseklik (m).
# (boy oranı, yükseklik, (yarıçap boy, yan, yukarı)) — topuk yüksek ve dar, burun alçak ve geniş.
SHOE_BLOBS = [
    (0.15, 0.040, (0.050, 0.037, 0.040)),   # topuk
    (0.44, 0.044, (0.080, 0.040, 0.036)),   # kemer / üst
    (0.70, 0.032, (0.058, 0.046, 0.031)),   # parmak kökü (en geniş)
    (0.87, 0.026, (0.042, 0.042, 0.024)),   # burun (yuvarlak kutu)
]
SOLE_HEIGHT = 0.014        # taban kalınlığı (koyu kauçuk)
HEEL_HEIGHT = 0.022        # topuk bloğu (tabanın arka üçte biri)
SOLE_LIP = 0.003           # taban kenarı üst deriden bu kadar taşar


def build_shoe(pts, side, mat, sole_mat, s):
    heel, toe, ankle = (pts[f"{k}_{side}"] for k in ("heel", "toe", "ankle"))
    up0 = Vector((0.0, 0.0, 1.0))
    heel_b = heel[0] - up0 * heel[1]
    toe_b = toe[0] - up0 * toe[1]
    fwd = (toe_b - heel_b).normalized()
    side_v = fwd.cross(up0).normalized()
    up = side_v.cross(fwd).normalized()
    length = (toe_b - heel_b).length + (heel[1] + toe[1]) * 0.7
    origin = heel_b - fwd * heel[1] * 0.9
    rot = Matrix((fwd, side_v, up)).transposed().to_quaternion()
    blobs = [(tuple(origin + fwd * u * length + up * z * s), tuple(r * s for r in radii), rot, False)
             for u, z, radii in SHOE_BLOBS]
    # bilek yakası: bileği saran alçak halka (bot değil)
    blobs.append((tuple(ankle[0] + up0 * 0.006 * s), (0.047 * s, 0.045 * s, 0.032 * s), rot, False))
    shoe = kit.metaball_oriented("Walker_Shoe_" + side, blobs, mat, resolution=0.004, smooth=3)
    shoe.data.materials.append(sole_mat)
    for vert in shoe.data.vertices:          # düz taban, kenarı hafif taşan
        hgt = (vert.co - origin).dot(up)
        if hgt < 0.0:
            vert.co -= up * hgt
            hgt = 0.0
        if hgt < SOLE_HEIGHT * s:
            out = vert.normal - up * vert.normal.dot(up)
            if out.length > 1e-4:
                vert.co += out.normalized() * SOLE_LIP * s
    for poly in shoe.data.polygons:          # taban ve topuk bloğu koyu
        c = poly.center - origin
        u = c.dot(fwd) / length
        limit = HEEL_HEIGHT if u < 0.30 else SOLE_HEIGHT
        poly.material_index = 1 if c.dot(up) < limit * s else 0
    return shoe


def build_shoes(body_obj, pts, part, v, suffix):
    mat, _ = kit.material("M_Walker_Shoes" + suffix, v["shoes"], rough=0.55)
    sole, _ = kit.material("M_Walker_Sole" + suffix, (0.015, 0.014, 0.013), rough=0.8)
    for side in ("L", "R"):
        build_shoe(pts, side, mat, sole, v["body"]["h"])
    # ayakkabının içinde kalan ayak ağını sil (görünmez, üçgen bütçesine yük)
    bm = bmesh.new()
    bm.from_mesh(body_obj.data)
    def hidden(f):
        cls, t = part(f.calc_center_median())
        return cls == "foot"
    dead = [f for f in bm.faces if hidden(f)]
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(body_obj.data)
    bm.free()
