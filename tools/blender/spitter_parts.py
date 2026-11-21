"""Tükürücü (spitter, "Asitli") parçaları (7.3): sinirli uzuv kasları, kambur, sarkık karın, gırtlak
kesesi, eller, ayak parmakları ve yeşil parlayan kabarcıklar.

build_spitter.py içe aktarır. Kas listesi tank_parts.LIMB_MUSCLES'tan okunur ve ince uzuv için
küçültülür (kas grupları arasında oluk kalır, eklemler incelir). Gövde: omurga üstünde kambur (üstünde
omur çıkıntıları), çökük göğüs, sarkık şiş karın, boyunun önünde sarkan guatr kesesi (iki yan lobu var).
El ve kabarcık yöntemi bloater_parts'tan kopyalandı (başka türün dosyasına bağımlı kalmamak için).
Kabarcık = parıltı maskesi (oyun modelinde köşe rengi alfası ~0).
"""
import math
import random

from mathutils import Matrix, Vector

import tank_parts as tp
import zombie_kit as kit

FRONT = Vector((0.0, -1.0, 0.0))
ARM_K = 0.44            # tank kas ölçüsüne göre kol kası çarpanı (sinirli, ince)
LEG_K = 0.56
SKIP = {"glute"}
BUBBLE_COLOR = (0.16, 0.85, 0.02)       # konsept yayıcı rengi (asit yeşili)
BUBBLE_CORE = (0.50, 1.0, 0.14)

# Kabarcık kümeleri: (ad, çapa, çapadan ofset, yön, adet, en büyük yarıçap m, ışın uzaklığı m).
# Çapa "sac" = kese merkezi. Kese önde ve yanda yoğun; kamburun tepesi oyun kamerasına (yukarıdan) bakar.
CLUSTERS = [
    ("sac_front", "sac", (0.0, 0.0, 0.0), (0.15, -1.0, 0.05), 14, 0.024, 0.45),
    ("sac_r", "sac", (0.0, 0.0, 0.0), (-0.85, -0.55, -0.25), 8, 0.026, 0.45),
    ("sac_l", "sac", (0.0, 0.0, 0.0), (0.80, -0.45, 0.15), 7, 0.024, 0.45),
    ("belly_l", "belly", (0.0, -0.10, -0.07), (0.55, -0.85, 0.05), 9, 0.034, 0.8),
    ("belly_r", "belly", (0.0, -0.10, -0.07), (-0.40, -0.85, -0.40), 6, 0.028, 0.8),
    ("hump_top", "upchest", (0.0, 0.10, 0.02), (0.15, 0.45, 1.0), 12, 0.040, 0.9),
    ("hump_r", "upchest", (0.0, 0.10, 0.02), (-0.75, 0.55, 0.55), 8, 0.034, 0.9),
    ("shoulder_l", "upchest", (0.0, 0.0, 0.0), (0.85, 0.15, 0.55), 5, 0.026, 0.9),
]


def masses(pts, body, rest_pts, sac):
    """Kas, kambur, karın ve kese kütleleri (metaball): [(merkez, yarıçaplar, dönüş, negatif)]."""
    blobs = []
    t, legs = body["t"], body.get("legs", 1.0)
    ident = Matrix.Identity(3).to_quaternion()
    for name, a, b, f, off, radii in tp.LIMB_MUSCLES:
        if name in SKIP:
            continue
        k = (LEG_K * legs) if name in tp.LEG_NAMES else ARM_K * t
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pa, pb = pts[f"{a}_{side}"][0], pts[f"{b}_{side}"][0]
            rest = rest_pts[f"{b}_{side}"][0] - rest_pts[f"{a}_{side}"][0]
            out, front, d = tp.limb_frame(pa, pb, sx, rest)
            c = pa.lerp(pb, f) + out * off[0] * k + front * off[1] * k
            rr = tuple(r * k for r in radii[:2]) + (radii[2] * 0.85,)
            blobs.append((tuple(c), rr, tp._frame_quat(out, front, d), False))
    w, g = body["w"], body["belly"]
    up, belly, chest = pts["upchest"][0], pts["belly"][0], pts["chest"][0]
    hump = up + Vector((0.0, 0.10, 0.02))
    blobs += [
        (tuple(hump), (0.16 * w, 0.14, 0.13), ident, False),                                   # kambur
        (tuple(chest + Vector((0.0, 0.08, -0.02))), (0.14 * w, 0.11, 0.14), ident, False),     # sırt
        (tuple(belly + Vector((0.0, -0.10, -0.07))), (0.185 * g * w, 0.165 * g, 0.165 * g), ident, False),  # karın
        (tuple(belly + Vector((0.0, -0.13 * g, -0.17 * g))), (0.15 * g * w, 0.12 * g, 0.10 * g), ident, False),  # sarkık alt karın
        (tuple(chest + Vector((0.0, -0.10, -0.10))), (0.08, 0.06, 0.05), ident, True),         # çökük mide çukuru
    ]
    for i in range(5):                                       # kamburun tepesinde omur çıkıntıları
        a = math.radians(15 + i * 17)
        c = hump + Vector((0.0, 0.14 * math.cos(a), 0.13 * math.sin(a))) * 0.95
        blobs.append((tuple(c), (0.020, 0.018, 0.018), ident, False))
    sc, sr = sac
    blobs.append((tuple(sc), tuple(sr), ident, False))       # gırtlak kesesi (guatr)
    for sx in (1.0, -1.0):
        blobs.append((tuple(sc + Vector((0.065 * sx, 0.02, 0.025)) * (sr.x / 0.105)),
                      tuple(sr * 0.68), ident, False))       # kese yan lobları
        blobs.append((tuple(up + Vector((0.10 * sx * w, 0.05, 0.04))), (0.07, 0.075, 0.06), ident, False))  # trapez
        blobs.append((tuple(chest + Vector((0.075 * sx * w, -0.11, 0.03))), (0.065, 0.040, 0.05), ident, False))  # göğüs
    return blobs


def add_blobs(obj, blobs, resolution=0.010):
    tp.add_blobs(obj, blobs, resolution)


# ---------------------------------------------------------------- el (bloater_parts kopyası, uzun parmak)

def hand_blobs(wrist, tip, sx, s):
    d = (tip - wrist).normalized()
    out = Vector((sx, 0.0, 0.0))
    out = (out - d * out.dot(d)).normalized()
    across = d.cross(out).normalized()
    q = tp._frame_quat(across, out, d)
    palm = wrist.lerp(tip, 0.36)
    blobs = [(tuple(palm), (0.032 * s, 0.014 * s, 0.040 * s), q, False)]
    for i in range(4):
        o = (i - 1.5) * 0.016 * s
        ln = (0.95, 1.08, 1.0, 0.82)[i]
        k0 = palm + d * 0.040 * s + across * o
        k1 = k0 + d * 0.034 * s * ln - out * 0.008 * s
        k2 = k1 + d * 0.026 * s * ln - out * 0.020 * s
        for c, r in ((k0, 0.0088), (k0.lerp(k1, 0.5), 0.0072), (k1, 0.0072), (k1.lerp(k2, 0.5), 0.0060), (k2, 0.0052)):
            blobs.append((tuple(c), (r * s, r * s, r * 1.15 * s), q, False))
    thumb = across if across.dot(FRONT) > 0.0 else -across
    t0 = palm + thumb * 0.028 * s - out * 0.006 * s
    t1 = t0 + d * 0.030 * s + thumb * 0.006 * s - out * 0.014 * s
    blobs.append((tuple(t0), (0.011 * s, 0.010 * s, 0.017 * s), q, False))
    blobs.append((tuple(t1), (0.0078 * s, 0.0074 * s, 0.012 * s), q, False))
    return blobs


def build_hand(name, wrist, tip, sx, s, mat):
    return kit.metaball_oriented(name, hand_blobs(wrist, tip, sx, s), mat, resolution=0.0032, smooth=2)


def build_toes(name, ball, toe, sx, s, mat, seed):
    rng = random.Random(int(seed * 100) + (1 if sx > 0 else 2))
    return kit.metaball_oriented(name, tp.toe_blobs(ball, toe, sx, s * 0.82, rng), mat, resolution=0.0032, smooth=2)


# ---------------------------------------------------------------- kabarcık

def bubble_material(name, glow=1.0):
    """Konsept: içten yanan asit yeşili kese (yayıcı + parlak ince kabuk)."""
    mat, bsdf = kit.material(name, BUBBLE_COLOR, rough=0.2, sss=0.3, coat=0.6,
                             emission=BUBBLE_COLOR, strength=0.75 * glow)
    nt = mat.node_tree
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.45
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*BUBBLE_CORE, 1.0)
    ramp.color_ramp.elements[1].color = (*BUBBLE_COLOR, 1.0)
    nt.links.new(lw.outputs["Facing"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color"])
    return mat


def bubble_spots(body, pts, sac, seed, amount=1.0):
    """[(konum, normal, yarıçap, küme_adı)]: küme yönünde gövdeye ışın, çevresine dağınık kabarcıklar."""
    rng = random.Random(int(seed * 1000) + 91)
    inv = body.matrix_world.inverted()
    spots = []
    for name, anchor, off, direction, count, rmax, reach in CLUSTERS:
        center = (sac[0] if anchor == "sac" else pts[anchor][0]) + Vector(off)
        n = max(2, round(count * amount))
        d0 = Vector(direction).normalized()
        for i in range(n):
            jitter = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))) * (0.0 if i == 0 else 0.30)
            d = (d0 + jitter).normalized()
            origin = inv @ (center + d * reach)
            hit, loc, nrm, _i = body.ray_cast(origin, -(inv.to_3x3() @ d))
            if not hit:
                continue
            r = rmax * (1.0 if i == 0 else rng.uniform(0.30, 0.80))
            if any((loc - p).length < (r + q) * 0.70 for p, _n, q, _c in spots):
                continue
            spots.append((body.matrix_world @ loc, (body.matrix_world.to_3x3() @ nrm).normalized(), r, name))
    return spots


def build_bubbles(spots, mat, suffix=""):
    """Kabarcıklar: yarı gömülü, normal boyunca basık küre."""
    made = []
    for loc, nrm, r, _cl in spots:
        b = kit.primitive("Spitter_Bubble", "sphere", loc + nrm * r * 0.22, segments=10, rings=7, radius=r)
        b.rotation_mode = "QUATERNION"
        b.rotation_quaternion = nrm.to_track_quat("Z", "Y")
        b.scale = (1.0, 1.0, 0.80)
        b.data.materials.append(mat)
        for p in b.data.polygons:
            p.use_smooth = True
        made.append(b)
    return made
