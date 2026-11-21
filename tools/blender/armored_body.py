"""Zırhlı zombinin gövdesi (7.3): iskelet noktaları, kas kütleleri, skin + voxel gövde. build_armored.py içe aktarır.

İnsan boyunda (~1.9 m, kambur), kalkan kolu asimetrik: sol kol dirsek önde, önkol göğsün önünde yatay
(kalkan önkolun önüne bağlı), sağ kol sarkık. Bacaklar aynalanır. Kas grupları tank_parts tablosundan
insan ölçeğine indirilir (k = t / legs); gövde kasları kendi tablosu. Eklemlerde ince yarıçap.
Karakter -Y'ye bakar, +X sol, Z yukarı, metre.
"""
import math

from mathutils import Matrix, Vector, geometry

import tank_parts as tp
import zombie_kit as kit

TORSO_POINTS = {
    "pelvis": ((0.0, 0.04, 0.98), 0.150),
    "belly": ((0.0, -0.01, 1.14), 0.140),
    "spine": ((0.0, 0.05, 1.30), 0.150),
    "chest": ((0.0, 0.00, 1.45), 0.165),
    "upchest": ((0.0, -0.07, 1.55), 0.125),
    "hump": ((0.0, 0.09, 1.57), 0.135),
    "neck0": ((0.0, -0.12, 1.61), 0.060),
    "neck1": ((0.0, -0.17, 1.67), 0.050),
}
LEG_POINTS = {   # sol (+X); sağ aynalanır
    "hip": ((0.115, 0.04, 0.94), 0.10), "knee": ((0.15, -0.05, 0.52), 0.068),
    "ankle": ((0.16, 0.03, 0.10), 0.048), "heel": ((0.16, 0.08, 0.05), 0.044),
    "ball": ((0.165, -0.08, 0.045), 0.040), "toe": ((0.165, -0.13, 0.035), 0.030),
}
ARM_POSES = {
    # nötr: sol kol kalkanı önde tutar (önkol göğsün önünde yatay), sağ kol sarkık, hafif önde
    "neutral": {
        "L": {"shoulder": ((0.205, -0.03, 1.53), 0.080), "elbow": ((0.27, -0.25, 1.31), 0.056),
              "wrist": ((-0.02, -0.32, 1.32), 0.044), "fist": ((-0.10, -0.335, 1.32), 0.0)},
        "R": {"shoulder": ((-0.205, -0.03, 1.53), 0.080), "elbow": ((-0.255, 0.03, 1.235), 0.056),
              "wrist": ((-0.28, -0.085, 0.95), 0.044), "fist": ((-0.285, -0.115, 0.87), 0.0)},
    },
}
UPPER = {"shoulder", "elbow", "wrist", "fist"}
LEGS = ("hip", "knee", "ankle", "heel", "ball", "toe", "pelvis")
TORSO_EDGES = [("pelvis", "belly"), ("belly", "spine"), ("spine", "chest"), ("chest", "upchest"),
               ("upchest", "neck0"), ("neck0", "neck1"), ("chest", "hump"), ("hump", "neck1")]
LIMB_CHAIN = [("hip", "knee"), ("knee", "ankle"), ("ankle", "heel"), ("ankle", "ball"),
              ("ball", "toe"), ("shoulder", "elbow"), ("elbow", "wrist")]
PART_CLASS = {
    "pelvis-belly": "hips", "belly-spine": "torso", "spine-chest": "torso", "chest-upchest": "torso",
    "chest-hump": "hump", "hump-neck1": "hump", "upchest-neck0": "neck", "neck0-neck1": "neck",
    "pelvis-hip": "hips", "upchest-shoulder": "clav", "hip-knee": "thigh", "knee-ankle": "shin",
    "ankle-heel": "foot", "ankle-ball": "foot", "ball-toe": "foot", "shoulder-elbow": "uparm",
    "elbow-wrist": "forearm",
}
# Gövde kasları (sol; sağ aynalanır): (ad, A, B, oran, ofset (dünya), yarıçap)
TORSO_MUSCLES = [
    ("trap", "hump", "shoulder", 0.45, (0.0, 0.0, 0.040), (0.095, 0.075, 0.060)),
    ("trap_neck", "hump", "neck1", 0.55, (0.045, 0.01, 0.015), (0.050, 0.080, 0.050)),
    ("pec", "chest", "shoulder", 0.40, (0.0, -0.085, -0.025), (0.095, 0.040, 0.065)),
    ("lat", "spine", "shoulder", 0.50, (0.0, 0.055, -0.040), (0.070, 0.080, 0.125)),
]
VOXEL = 0.008
Q0 = Matrix.Identity(3).to_quaternion()


def body_points(body, pose="neutral"):
    """Çeşidin gövde noktaları (çeşit ölçeğinden önce): ad -> (konum, yarıçap); kollar _L/_R."""
    w, t, legs = body["w"], body["t"], body.get("legs", 1.0)
    pts = {n: (Vector(p), r * w) for n, (p, r) in TORSO_POINTS.items()}
    for n, (p, r) in LEG_POINTS.items():
        for side, sx in (("L", 1.0), ("R", -1.0)):
            x = p[0] * (w if n == "hip" else 1.0 + (w - 1.0) * 0.6)
            pts[f"{n}_{side}"] = (Vector((x * sx, p[1], p[2])), r * legs)
    for side, arm in ARM_POSES[pose].items():
        for n, (p, r) in arm.items():
            pts[f"{n}_{side}"] = (Vector((p[0] * (w if n == "shoulder" else 1.0), p[1], p[2])), r * t)
    return pts


def masses(pts, body):
    """Kas kütleleri: tank_parts uzuv tablosu insan ölçeğinde + kendi gövde tablosu."""
    blobs = []
    k_arm, k_leg = body["t"] * 0.58, body.get("legs", 1.0) * 0.60
    for name, a, b, f, off, radii in tp.LIMB_MUSCLES:
        k = k_leg if name in tp.LEG_NAMES else k_arm
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pa, pb = pts[f"{a}_{side}"][0], pts[f"{b}_{side}"][0]
            out, front, d = tp.limb_frame(pa, pb, sx, pb - pa)
            c = pa.lerp(pb, f) + out * off[0] * k + front * off[1] * k
            blobs.append((tuple(c), tuple(r * k for r in radii), tp._frame_quat(out, front, d), False))
    for name, a, b, f, off, radii in TORSO_MUSCLES:
        for side, sx in (("L", 1.0), ("R", -1.0)):
            pa = pts[a if a in pts else f"{a}_{side}"][0]
            pb = pts[b if b in pts else f"{b}_{side}"][0]
            c = pa.lerp(pb, f) + Vector((off[0] * sx, off[1], off[2]))
            blobs.append((tuple(c), tuple(r * body["t"] for r in radii), Q0, False))
    gut = pts["belly"][0] + Vector((0.0, -0.035, -0.02))
    g = body.get("belly", 1.0)
    blobs.append((tuple(gut), (0.13 * g, 0.11 * g, 0.12 * g), Q0, False))
    return blobs


def edges():
    out = list(TORSO_EDGES)
    for side in ("L", "R"):
        out += [(f"{a}_{side}", f"{b}_{side}") for a, b in LIMB_CHAIN]
        out += [("pelvis", f"hip_{side}"), ("upchest", f"shoulder_{side}")]
    return out


def build_body(v, mat, pose="neutral", name="Armored_Body"):
    body = v["body"]
    pts = body_points(body, pose)
    blobs = masses(pts, body)
    ed = edges()
    skin_pts = {n: (tuple(p), r) for n, (p, r) in pts.items() if not n.startswith("fist")}
    obj = kit.skin_object(name, skin_pts, ed, mat)
    tp.add_blobs(obj, blobs, resolution=0.008)
    kit.organic_pass(obj, voxel=VOXEL, lump=0.004)
    segments = []
    for a, b in ed:
        key = f"{a.split('_')[0]}-{b.split('_')[0]}"
        if key in PART_CLASS:
            segments.append((PART_CLASS[key], pts[a][0], pts[b][0], a.split("_")[-1] if "_" in a else
                             (b.split("_")[-1] if "_" in b else "")))
    return obj, segments, pts


def classify(co, segments):
    """En yakın parça: (sınıf, t); sınıf uzuvlarda yan ekiyle ayrılmaz (kıyafet kuralları ortak)."""
    best, best_d = ("torso", 0.0), 1e9
    for cls, a, b, _side in segments:
        _c, t = geometry.intersect_point_line(co, a, b)
        t = min(max(t, 0.0), 1.0)
        d = (co - a.lerp(b, t)).length
        if d < best_d:
            best, best_d = (cls, t), d
    return best


def classify_side(co, segments):
    """(sınıf, t, yan) — kol kuralları sağ/sol ayrımına bakar."""
    best, best_d = ("torso", 0.0, ""), 1e9
    for cls, a, b, side in segments:
        _c, t = geometry.intersect_point_line(co, a, b)
        t = min(max(t, 0.0), 1.0)
        d = (co - a.lerp(b, t)).length
        if d < best_d:
            best, best_d = (cls, t, side), d
    return best


def deg(x):
    return math.radians(x)
