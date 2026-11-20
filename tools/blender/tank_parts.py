"""Tank zombisinin parçaları (V.5 v2): tanımlı kas grupları, yumruklar, çıplak ayak parmakları.

build_tank.py içe aktarır. v1'deki uzun balon kütlelerin yerine kas grupları (deltoidin üç başı,
biseps/triseps, önkolun üç kütlesi, uyluk ön/yan/iç, arka bacak, baldırın iki başı, kalça) ayrı ayrı
konur; aralarında voxel remesh sonrası oluk kalır, eklemler (dirsek, bilek, diz, ayak bileği) incedir.
Uzuv kasları uzuv çerçevesinde verilir (dışa, öne, boyunca): poz değişince kas uzuvla döner.
Yumruk ve ayak parmakları gövdeye kaynatılmaz, ayrı metaball ağıdır (parmak arası oluk net kalsın).
Kemik plakalar: tank_plates.py. Kafa: tank_head.py.
"""
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

import zombie_kit as kit

UP = Vector((0.0, 0.0, 1.0))
FRONT = Vector((0.0, -1.0, 0.0))

# Uzuv kasları: (ad, A, B, A->B oranı, ofset (dışa, öne, boyunca) m, yarıçap (dışa, öne, boyunca) m)
LIMB_MUSCLES = [
    ("delt_f", "shoulder", "elbow", 0.08, (0.02, 0.060, 0.0), (0.080, 0.068, 0.130)),
    ("delt_s", "shoulder", "elbow", 0.12, (0.060, 0.0, 0.0), (0.078, 0.095, 0.150)),
    ("delt_r", "shoulder", "elbow", 0.08, (0.02, -0.062, 0.0), (0.080, 0.068, 0.130)),
    ("bicep", "shoulder", "elbow", 0.56, (0.0, 0.058, 0.0), (0.080, 0.080, 0.150)),
    ("tricep", "shoulder", "elbow", 0.44, (0.005, -0.062, 0.0), (0.088, 0.084, 0.175)),
    ("brachio", "elbow", "wrist", 0.20, (0.045, 0.035, 0.0), (0.068, 0.066, 0.125)),
    ("flexor", "elbow", "wrist", 0.36, (-0.032, 0.018, 0.0), (0.070, 0.066, 0.165)),
    ("extensor", "elbow", "wrist", 0.36, (0.030, -0.034, 0.0), (0.066, 0.066, 0.165)),
    ("glute", "hip", "knee", -0.02, (0.02, -0.105, 0.0), (0.125, 0.105, 0.125)),
    ("vast_lat", "hip", "knee", 0.48, (0.065, 0.0, 0.0), (0.095, 0.105, 0.195)),
    ("rectus", "hip", "knee", 0.44, (0.0, 0.070, 0.0), (0.082, 0.078, 0.195)),
    ("vast_med", "hip", "knee", 0.78, (-0.050, 0.050, 0.0), (0.068, 0.068, 0.090)),
    ("adductor", "hip", "knee", 0.26, (-0.070, 0.0, 0.0), (0.078, 0.088, 0.150)),
    ("hamstring", "hip", "knee", 0.46, (0.0, -0.068, 0.0), (0.086, 0.078, 0.185)),
    ("gastro_l", "knee", "ankle", 0.28, (0.030, -0.055, 0.0), (0.062, 0.068, 0.125)),
    ("gastro_m", "knee", "ankle", 0.30, (-0.030, -0.060, 0.0), (0.068, 0.072, 0.125)),
    ("tibialis", "knee", "ankle", 0.35, (0.024, 0.045, 0.0), (0.044, 0.044, 0.140)),
    ("sole", "heel", "ball", 0.55, (0.0, 0.0, 0.0), (0.060, 0.034, 0.100)),
]
# Gövde kasları (dünya ofseti, sol taraf; sağ aynalanır): (ad, A, B, oran, ofset, yarıçap)
TORSO_MUSCLES = [
    ("trap", "hump", "shoulder", 0.45, (0.0, 0.0, 0.065), (0.160, 0.125, 0.110)),
    ("trap_neck", "hump", "neck1", 0.60, (0.070, 0.02, 0.035), (0.085, 0.130, 0.085)),
    ("pec", "chest", "shoulder", 0.40, (0.0, -0.150, -0.030), (0.160, 0.062, 0.105)),
    ("lat", "spine", "shoulder", 0.50, (0.0, 0.10, -0.06), (0.120, 0.140, 0.215)),
    ("serratus", "spine", "shoulder", 0.36, (0.0, -0.06, -0.08), (0.080, 0.090, 0.110)),
]
LEG_NAMES = {"glute", "vast_lat", "rectus", "vast_med", "adductor", "hamstring", "gastro_l",
             "gastro_m", "tibialis", "sole"}
LIMB_REST = {}             # nötr pozun uzuv yönleri (build_tank doldurur): (A, B) -> yön


def limb_frame(pa, pb, sx, rest_dir=None):
    """(dışa, öne, boyunca) çerçevesi. Nötr yönde dışa = +X (yanına göre), öne = -Y; başka pozda
    nötr çerçeve yeni yöne döndürülür (kas uzuvla döner)."""
    d = (pb - pa).normalized()
    base = rest_dir.normalized() if rest_dir is not None else d
    out = Vector((sx, 0.0, 0.0))
    out = (out - base * out.dot(base)).normalized()
    front = base.cross(out).normalized()
    if front.dot(FRONT) < 0.0:
        front = -front
    q = base.rotation_difference(d)
    return q @ out, q @ front, d


def _frame_quat(out, front, d):
    return Matrix((out, front, d)).transposed().to_quaternion()


def masses(pts, body, rest_pts=None):
    """Kas kütleleri (metaball): [(merkez, yarıçaplar, dönüş, negatif)]."""
    blobs = []
    t, legs = body["t"], body.get("legs", 1.0)
    rest_pts = rest_pts or pts
    for name, a, b, f, off, radii in LIMB_MUSCLES:
        k = legs if name in LEG_NAMES else t
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pa, pb = pts[f"{a}_{side}"][0], pts[f"{b}_{side}"][0]
            rest = rest_pts[f"{b}_{side}"][0] - rest_pts[f"{a}_{side}"][0]
            out, front, d = limb_frame(pa, pb, sx, rest)
            c = pa.lerp(pb, f) + out * off[0] * k + front * off[1] * k + d * off[2]
            blobs.append((tuple(c), tuple(r * k for r in radii), _frame_quat(out, front, d), False))
    for name, a, b, f, off, radii in TORSO_MUSCLES:
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pa = pts[a if a in pts else f"{a}_{side}"][0]
            pb = pts[b if b in pts else f"{b}_{side}"][0]
            c = pa.lerp(pb, f) + Vector((off[0] * sx, off[1], off[2]))
            blobs.append((tuple(c), tuple(r * t for r in radii), Matrix.Identity(3).to_quaternion(), False))
    gut = pts["belly"][0] + Vector((0.0, -0.07, -0.03))
    g = body["belly"]
    blobs.append((tuple(gut), (0.23 * g, 0.19 * g, 0.21 * g), Matrix.Identity(3).to_quaternion(), False))
    return blobs


def add_blobs(obj, blobs, resolution=0.010):
    """Metaball kütlelerini gövde ağına ekler (voxel remesh sonra kaynaştırır)."""
    extra = kit.metaball_oriented("Tank_Mass", blobs, obj.active_material, resolution=resolution, smooth=0)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.from_mesh(extra.data)
    bm.to_mesh(obj.data)
    bm.free()
    mesh = extra.data
    bpy.data.objects.remove(extra)
    bpy.data.meshes.remove(mesh)


# ---------------------------------------------------------------- yumruk

def fist_blobs(wrist, fist, sx, s):
    """Dev yumruk: avuç bloğu, dört boğum, kıvrık parmaklar, başparmak. Elin sırtı dışa (+X yanı) bakar,
    kıvrık parmaklar içe; iki yumruk imzada parmak yüzleriyle birbirine dayanır."""
    d = (fist - wrist).normalized()
    back = Vector((sx, 0.0, 0.0))
    back = (back - d * back.dot(d)).normalized()
    across = d.cross(back).normalized()
    q = _frame_quat(across, back, d)
    blobs = [(tuple(fist), (0.072 * s, 0.050 * s, 0.070 * s), q, False),            # avuç
             (tuple(wrist.lerp(fist, 0.45)), (0.058 * s, 0.040 * s, 0.050 * s), q, False)]
    for i in range(4):
        o = (i - 1.5) * 0.034 * s
        r = (1.0, 1.0, 0.95, 0.85)[i]
        knuck = fist + d * 0.064 * s + back * 0.022 * s + across * o
        blobs.append((tuple(knuck), (0.018 * s * r, 0.020 * s * r, 0.024 * s * r), q, False))
        mid = fist + d * 0.080 * s - back * 0.020 * s + across * o
        blobs.append((tuple(mid), (0.016 * s * r, 0.026 * s * r, 0.019 * s * r), q, False))
        tip = fist + d * 0.050 * s - back * 0.046 * s + across * o
        blobs.append((tuple(tip), (0.015 * s * r, 0.016 * s * r, 0.018 * s * r), q, False))
    thumb_side = across if across.dot(FRONT) > 0.0 else -across
    th0 = fist + thumb_side * 0.060 * s - back * 0.010 * s - d * 0.010 * s
    th1 = fist + thumb_side * 0.030 * s - back * 0.052 * s + d * 0.035 * s
    blobs.append((tuple(th0), (0.022 * s, 0.024 * s, 0.032 * s), q, False))
    blobs.append((tuple(th1), (0.022 * s, 0.018 * s, 0.020 * s), q, False))
    return blobs


def build_fist(name, wrist, fist, sx, s, mat):
    return kit.metaball_oriented(name, fist_blobs(wrist, fist, sx, s), mat, resolution=0.0045, smooth=2)


# ---------------------------------------------------------------- ayak parmakları

# (içten dışa) başparmak kalın ve uzun; (yan ofset, yarıçap, uzunluk, geri çekilme) m
TOES = ((-0.046, 0.024, 0.056, 0.000), (-0.012, 0.018, 0.046, 0.004), (0.016, 0.017, 0.042, 0.010),
        (0.041, 0.016, 0.036, 0.018), (0.062, 0.014, 0.030, 0.028))


def toe_blobs(ball, toe, sx, s, rng):
    """Beş parmak; her biri iki boğum (kök + uç), aralarında boşluk; uçlar yere değer."""
    fwd = toe - ball
    fwd.z = 0.0
    fwd.normalize()
    across = fwd.cross(UP).normalized()
    q = _frame_quat(across, fwd, UP)
    blobs = []
    for off, r, ln, back in TOES:
        r, ln = r * s, ln * s
        base = ball + fwd * (0.030 * s - back * s) - across * off * sx * s
        base.z = r * 0.95
        tip = base + fwd * ln * rng.uniform(0.92, 1.05)
        tip.z = r * 0.70
        blobs.append((tuple(base), (r * 0.95, r * 1.05, r * 0.92), q, False))
        blobs.append((tuple(base.lerp(tip, 0.55)), (r * 0.88, ln * 0.42, r * 0.80), q, False))
        blobs.append((tuple(tip), (r * 0.82, r * 0.85, r * 0.68), q, False))
    return blobs


def build_toes(name, ball, toe, sx, s, mat, seed):
    rng = random.Random(int(seed * 100) + (1 if sx > 0 else 2))
    return kit.metaball_oriented(name, toe_blobs(ball, toe, sx, s, rng), mat, resolution=0.0035, smooth=2)


def rng_for(v):
    return random.Random(int(v["seed"] * 1000) + 5)
