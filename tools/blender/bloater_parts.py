"""Patlayıcı (bloater, "Şişko") parçaları (7.3): ince ama tanımlı uzuv kasları, gövde yağ kütleleri,
eller, ayak parmakları ve parlayan kabarcık kümeleri.

build_bloater.py içe aktarır. Kas listesi tank_parts.LIMB_MUSCLES'tan okunur ve ince uzuv için
küçültülür (kas grupları arasında oluk kalsın, eklemler incelsin). Gövde neredeyse küre: dev göbek +
sırt/göğüs yağı + yan bel simitleri + boyun yağ halkası; ince kollar küreden dışa açılır.
Kabarcıklar: gövde yüzeyine ışın atılarak kümeler halinde konur, yarısı gövdeye gömülür; her kümenin
altında kızarık, şiş bir taban (et) olur. Kabarcık = parıltı maskesi (oyun modelinde köşe rengi alfası 0).
"""
import random

from mathutils import Matrix, Vector

import tank_parts as tp
import zombie_kit as kit

UP = Vector((0.0, 0.0, 1.0))
FRONT = Vector((0.0, -1.0, 0.0))
ARM_K = 0.60            # tank kas ölçüsüne göre kol kası çarpanı (ince, ipliksi)
LEG_K = 0.62
SKIP = {"glute"}        # kalçayı göbek ve gövde kapatır
BLISTER_COLOR = (1.0, 0.32, 0.02)       # konsept yayıcı rengi (turuncu-sarı)
BLISTER_CORE = (1.0, 0.62, 0.08)
RASH_COLOR = (0.16, 0.035, 0.02)          # kabarcık tabanındaki kızarık et

# Kabarcık kümeleri: (ad, yön (gövde merkezinden; x, y, z), adet, en büyük yarıçap m). Üst ve önde
# yoğun: oyun kamerası yukarıdan ve önden bakar.
CLUSTERS = [
    ("belly_l", (0.45, -0.85, 0.10), 14, 0.058),
    ("belly_r", (-0.35, -0.90, -0.35), 10, 0.048),
    ("chest_top", (0.30, -0.40, 0.90), 12, 0.052),
    ("shoulder_r", (-0.70, 0.05, 0.75), 11, 0.050),
    ("back_top", (0.15, 0.70, 0.75), 14, 0.058),
    ("side_l", (0.95, 0.10, -0.05), 8, 0.045),
    ("back_low", (-0.40, 0.85, -0.10), 8, 0.042),
]


def masses(pts, body, rest_pts=None):
    """Kas ve yağ kütleleri (metaball): [(merkez, yarıçaplar, dönüş, negatif)]."""
    blobs = []
    t, legs = body["t"], body.get("legs", 1.0)
    rest_pts = rest_pts or pts
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
            rr = tuple(r * k for r in radii[:2]) + (radii[2] * (0.85 if k < 0.6 else 1.0),)
            blobs.append((tuple(c), rr, tp._frame_quat(out, front, d), False))
    g = body["belly"]
    gut = pts["belly"][0]
    w = body["w"]
    blobs += [
        (tuple(gut + Vector((0.0, -0.05, 0.02))), (0.40 * g * w, 0.39 * g, 0.40 * g), ident, False),   # dev göbek
        (tuple(pts["chest"][0] + Vector((0.0, 0.05, -0.02))), (0.35 * w, 0.31, 0.24), ident, False),   # sırt/göğüs
        (tuple(gut + Vector((0.0, -0.17 * g, -0.20 * g))), (0.27 * g * w, 0.22 * g, 0.16 * g), ident, False),  # sarkık alt göbek
        (tuple(pts["neck0"][0] + Vector((0.0, 0.03, -0.03))), (0.16, 0.15, 0.08), ident, False),          # boyun yağı
    ]
    for sx in (1.0, -1.0):
        blobs.append((tuple(gut + Vector((0.24 * sx * g * w, 0.08, -0.12))), (0.17, 0.20, 0.15), ident, False))  # bel simidi
        blobs.append((tuple(pts["chest"][0] + Vector((0.13 * sx * w, -0.22, -0.04))), (0.14, 0.10, 0.12), ident, False))  # sarkık göğüs
        blobs.append((tuple(pts["upchest"][0] + Vector((0.20 * sx * w, 0.02, 0.0))), (0.13, 0.13, 0.10), ident, False))  # trapez yağı
    return blobs


def add_blobs(obj, blobs, resolution=0.010):
    tp.add_blobs(obj, blobs, resolution)


# ---------------------------------------------------------------- el

def hand_blobs(wrist, tip, sx, s):
    """İnce, yarı kıvrık el: avuç, dört iki boğumlu parmak, başparmak. Avuç içe (gövdeye) bakar."""
    d = (tip - wrist).normalized()
    out = Vector((sx, 0.0, 0.0))
    out = (out - d * out.dot(d)).normalized()
    across = d.cross(out).normalized()
    q = tp._frame_quat(across, out, d)
    palm = wrist.lerp(tip, 0.38)
    blobs = [(tuple(palm), (0.034 * s, 0.016 * s, 0.040 * s), q, False)]
    for i in range(4):
        o = (i - 1.5) * 0.017 * s
        ln = (0.9, 1.0, 0.96, 0.8)[i]
        k0 = palm + d * 0.040 * s + across * o
        k1 = k0 + d * 0.030 * s * ln - out * 0.010 * s
        k2 = k1 + d * 0.022 * s * ln - out * 0.020 * s
        for c, r in ((k0, 0.0095), (k0.lerp(k1, 0.5), 0.008), (k1, 0.0078), (k1.lerp(k2, 0.5), 0.0068), (k2, 0.006)):
            blobs.append((tuple(c), (r * s, r * s, r * 1.15 * s), q, False))
    thumb = across if across.dot(FRONT) > 0.0 else -across
    t0 = palm + thumb * 0.030 * s - out * 0.006 * s
    t1 = t0 + d * 0.030 * s + thumb * 0.006 * s - out * 0.014 * s
    blobs.append((tuple(t0), (0.012 * s, 0.011 * s, 0.018 * s), q, False))
    blobs.append((tuple(t1), (0.0085 * s, 0.008 * s, 0.012 * s), q, False))
    return blobs


def build_hand(name, wrist, tip, sx, s, mat):
    return kit.metaball_oriented(name, hand_blobs(wrist, tip, sx, s), mat, resolution=0.0032, smooth=2)


def build_toes(name, ball, toe, sx, s, mat, seed):
    rng = random.Random(int(seed * 100) + (1 if sx > 0 else 2))
    return kit.metaball_oriented(name, tp.toe_blobs(ball, toe, sx, s * 0.85, rng), mat, resolution=0.0032, smooth=2)


# ---------------------------------------------------------------- kabarcık

def blister_material(name, glow=1.0):
    """Konsept: içten yanan turuncu-sarı kese (yayıcı + ince kabuk)."""
    mat, bsdf = kit.material(name, BLISTER_COLOR, rough=0.25, sss=0.3, coat=0.5,
                             emission=BLISTER_COLOR, strength=1.6 * glow)
    nt = mat.node_tree
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.45
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*BLISTER_CORE, 1.0)
    ramp.color_ramp.elements[1].color = (*BLISTER_COLOR, 1.0)
    nt.links.new(lw.outputs["Facing"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color"])
    return mat


def blister_spots(body, center, seed, amount=1.0):
    """[(konum, normal, yarıçap, küme_adı)]: küme yönünde gövdeye ışın, çevresine dağınık kabarcıklar."""
    rng = random.Random(int(seed * 1000) + 77)
    inv = body.matrix_world.inverted()
    spots = []
    for name, direction, count, rmax in CLUSTERS:
        n = max(2, round(count * amount))
        d0 = Vector(direction).normalized()
        for i in range(n):
            jitter = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))) * (0.0 if i == 0 else 0.20)
            d = (d0 + jitter).normalized()
            origin = inv @ (center + d * 1.5)
            hit, loc, nrm, _i = body.ray_cast(origin, -(inv.to_3x3() @ d))
            if not hit:
                continue
            r = rmax * (1.0 if i == 0 else rng.uniform(0.25, 0.75))
            if any((loc - p).length < (r + q) * 0.62 for p, _n, q, _c in spots):
                continue
            spots.append((body.matrix_world @ loc, (body.matrix_world.to_3x3() @ nrm).normalized(), r, name))
    return spots


def build_blisters(spots, mat, rash_mat, suffix=""):
    """Kabarcıklar (yarı gömülü, normal boyunca basık küre) + küme altında kızarık şiş taban."""
    made = []
    for loc, nrm, r, _cl in spots:
        q = nrm.to_track_quat("Z", "Y")
        b = kit.primitive("Bloater_Blister", "sphere", loc + nrm * r * 0.25, segments=12, rings=8, radius=r)
        b.rotation_mode = "QUATERNION"
        b.rotation_quaternion = q
        b.scale = (1.0, 1.0, 0.78)
        b.data.materials.append(mat)
        for p in b.data.polygons:
            p.use_smooth = True
        made.append(b)
        if r > 0.03:
            rash = kit.primitive("Bloater_Rash", "sphere", loc - nrm * r * 0.15, segments=12, rings=6, radius=r * 1.55)
            rash.rotation_mode = "QUATERNION"
            rash.rotation_quaternion = q
            rash.scale = (1.0, 1.0, 0.32)
            rash.data.materials.append(rash_mat)
            for p in rash.data.polygons:
                p.use_smooth = True
            made.append(rash)
    return made


def rash_material(name):
    mat, bsdf = kit.material(name, RASH_COLOR, rough=0.35, sss=0.25, coat=0.3,
                             emission=(0.6, 0.12, 0.02), strength=0.25)
    return mat


def rng_for(v):
    return random.Random(int(v["seed"] * 1000) + 5)

