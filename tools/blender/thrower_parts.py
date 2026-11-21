"""Taş fırlatanın parçaları (7.3): asimetrik kas grupları, dev sağ el, sıska sol el.

build_thrower.py içe aktarır. Kas yöntemi tank_parts ile aynı (kas grupları ayrı elipsoid, aralarında
voxel remesh sonrası oluk, eklemlerde incelme); fark: kol kasları YANA GÖRE ölçeklenir. Sağ kol dev
(deltoid/biseps/triseps ×ARM_SCALE["R"]["upper"], önkol daha da şiş: Popeye önkolu), sol kol sıska.
Gövde kasları da yana göre (sağ trapez/göğüs/kanat kası iri, sol sönük): siluet yukarıdan asimetrik.
El: yarı açık pençe (avuç + dört parmak × üç boğum + boğum tümsekleri + başparmak); ayrı metaball ağı.
tank_parts'tan yalnız salt veri/yardımcı içe aktarılır (dosyası düzenlenmez).
"""
import math

from mathutils import Matrix, Quaternion, Vector

import zombie_kit as kit
import tank_parts as tp

FRONT = Vector((0.0, -1.0, 0.0))
ARM_MUSCLES = {"delt_f", "delt_s", "delt_r", "bicep", "tricep", "brachio", "flexor", "extensor"}
FORE = {"brachio", "flexor", "extensor"}
# Yan -> (üst kol, önkol) kas ölçeği. Sağ kol bacaktan kalın okunsun (oyun kamerasından imza).
ARM_SCALE = {"R": {"upper": 1.12, "fore": 1.30}, "L": {"upper": 0.50, "fore": 0.46}}
TORSO_SCALE = {"R": 1.35, "L": 0.62}
BOOST = {"delt_s": 1.18, "delt_f": 1.10, "delt_r": 1.10, "brachio": 1.15, "bicep": 1.05}   # sağ kolda belirgin kas başları
# Gövde kasları (ad, A, B, oran, ofset (x dışa, y, z), yarıçap) — sol taraf değerleri, x yana göre işaretlenir
TORSO_MUSCLES = [
    ("trap", "upchest", "shoulder", 0.50, (0.0, 0.035, 0.060), (0.110, 0.090, 0.080)),
    ("trap_neck", "upchest", "neck1", 0.45, (0.045, 0.030, 0.0), (0.055, 0.080, 0.070)),
    ("pec", "chest", "shoulder", 0.45, (0.0, -0.095, -0.030), (0.115, 0.050, 0.085)),
    ("lat", "spine", "shoulder", 0.50, (0.0, 0.070, -0.050), (0.090, 0.095, 0.170)),
    ("serratus", "spine", "shoulder", 0.40, (0.0, -0.050, -0.060), (0.060, 0.060, 0.080)),
]


def _q(out, front, d):
    return Matrix((out, front, d)).transposed().to_quaternion()


def masses(pts, body, rest_pts=None):
    """Kas kütleleri: [(merkez, yarıçaplar, dönüş, negatif)]. Bacaklar simetrik, kollar/gövde yana göre."""
    blobs = []
    legs = body.get("legs", 1.0)
    rest_pts = rest_pts or pts
    arm_k = body.get("arm", 1.0)
    for name, a, b, f, off, radii in tp.LIMB_MUSCLES:
        for side, sx in (("L", 1.0), ("R", -1.0)):
            if name in ARM_MUSCLES:
                k = ARM_SCALE[side]["fore" if name in FORE else "upper"]
                k *= arm_k * BOOST.get(name, 1.0) if side == "R" else body.get("thin", 1.0)
            else:
                k = legs * 0.74
            pa, pb = pts[f"{a}_{side}"][0], pts[f"{b}_{side}"][0]
            rest = rest_pts[f"{b}_{side}"][0] - rest_pts[f"{a}_{side}"][0]
            out, front, d = tp.limb_frame(pa, pb, sx, rest)
            c = pa.lerp(pb, f) + out * off[0] * k + front * off[1] * k
            blobs.append((tuple(c), tuple(r * k for r in radii), _q(out, front, d), False))
    for name, a, b, f, off, radii in TORSO_MUSCLES:
        for side, sx in (("L", 1.0), ("R", -1.0)):
            k = TORSO_SCALE[side] * (arm_k if side == "R" else 1.0) * body["w"]
            pa = pts[a if a in pts else f"{a}_{side}"][0]
            pb = pts[b if b in pts else f"{b}_{side}"][0]
            c = pa.lerp(pb, f) + Vector((off[0] * sx, off[1], off[2])) * k
            blobs.append((tuple(c), tuple(r * k for r in radii), Quaternion(), False))
    gut = pts["belly"][0] + Vector((0.0, -0.06, -0.03))
    g = body["belly"]
    blobs.append((tuple(gut), (0.17 * g, 0.14 * g, 0.16 * g), Quaternion(), False))
    return blobs


# ---------------------------------------------------------------- el

FINGERS = ((1.00, 0.92), (1.08, 1.00), (1.02, 0.97), (0.86, 0.86))   # (uzunluk, kalınlık) işaret→serçe
PHALANX = (0.060, 0.042, 0.032)        # boğum uzunlukları (m, el ölçeği 1)
CURL = (22.0, 34.0, 30.0)              # boğum başına kıvrılma (derece, curl=1)


def hand_frame(wrist, tip, sx):
    """(karşı, sırt, boyunca) — elin sırtı dışa (yanına göre ±X), avuç gövdeye bakar."""
    d = (tip - wrist).normalized()
    back = Vector((sx, 0.0, 0.0))
    back = (back - d * back.dot(d)).normalized()
    across = d.cross(back).normalized()
    return across, back, d


def hand_blobs(wrist, tip, sx, s, curl=0.6):
    """Yarı açık pençe: avuç bloğu, avuç topuğu, dört parmak (üç boğum, boğum tümsekleri), başparmak."""
    across, back, d = hand_frame(wrist, tip, sx)
    q = _q(across, back, d)
    blobs = [(tuple(wrist + d * 0.085 * s), (0.078 * s, 0.040 * s, 0.070 * s), q, False),      # avuç
             (tuple(wrist + d * 0.030 * s - back * 0.006 * s), (0.064 * s, 0.040 * s, 0.045 * s), q, False)]
    for i, (lf, tf) in enumerate(FINGERS):
        o = (i - 1.5) * 0.037 * s
        base = wrist + d * (0.150 - 0.012 * abs(i - 1.2)) * s + across * o
        blobs.append((tuple(base + back * 0.016 * s), (0.021 * s * tf, 0.020 * s * tf, 0.020 * s * tf), q, False))
        p, dirv, ang = base, d.copy(), 0.0
        for k, ln in enumerate(PHALANX):
            ang += math.radians(CURL[k] * curl)
            dirv = (d * math.cos(ang) - back * math.sin(ang)).normalized()
            ln *= s * lf
            r = (0.0185, 0.0165, 0.0145)[k] * s * tf
            mid = p + dirv * ln * 0.5
            side_v = across
            qq = _q(side_v, dirv.cross(side_v).normalized(), dirv)
            blobs.append((tuple(mid), (r, r * 0.92, ln * 0.62), qq, False))
            p = p + dirv * ln
            if k < 2:   # boğum tümseği (eklem sırtta)
                blobs.append((tuple(p + (dirv.cross(across)).normalized() * -0.004 * s),
                              (r * 1.05, r * 1.0, r * 0.9), qq, False))
    thumb_side = across if across.dot(FRONT) > 0.0 else -across
    t0 = wrist + d * 0.050 * s + thumb_side * 0.055 * s - back * 0.018 * s
    tdir = (d * 0.75 + thumb_side * 0.25 - back * 0.55 * curl).normalized()
    qt = _q(thumb_side, tdir.cross(thumb_side).normalized(), tdir)
    blobs.append((tuple(t0), (0.026 * s, 0.024 * s, 0.036 * s), qt, False))
    blobs.append((tuple(t0 + tdir * 0.050 * s), (0.019 * s, 0.018 * s, 0.026 * s), qt, False))
    blobs.append((tuple(t0 + tdir * 0.088 * s), (0.016 * s, 0.015 * s, 0.020 * s), qt, False))
    return blobs


def build_hand(name, wrist, tip, sx, s, mat, curl=0.6):
    return kit.metaball_oriented(name, hand_blobs(wrist, tip, sx, s, curl), mat, resolution=0.0045, smooth=2)


def palm_point(wrist, tip, sx, s, depth):
    """Avuç içinin önündeki tutma noktası (kaya merkezi): avuç merkezinden avuç normali boyunca `depth`."""
    across, back, d = hand_frame(wrist, tip, sx)
    return wrist + d * 0.13 * s - back * depth
